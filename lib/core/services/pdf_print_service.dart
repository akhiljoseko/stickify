import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/domain/domain.dart';

/// Printer Calibration configurations.
class PrinterCalibration {
  /// Instantiates printer calibration.
  const PrinterCalibration({
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
  });

  /// X calibration offset in mm.
  final double offsetX;

  /// Y calibration offset in mm.
  final double offsetY;

  /// X scale coefficient.
  final double scaleX;

  /// Y scale coefficient.
  final double scaleY;
}

/// Concrete implementation of [PrintService] using the `pdf` and `printing` packages.
///
/// This service coordinates the rendering of structured sticker layouts on print sheets,
/// offloading PDF document generation to a background Dart Isolate to keep the main
/// application UI thread completely responsive during physical printing.
class PdfPrintService implements PrintService {
  /// Instantiates a new [PdfPrintService].
  const PdfPrintService();

  @override
  Future<Result<void, AppError>> printLabels({
    required Product product,
    required ProductVariant variant,
    required LabelTemplate template,
    required int quantity,
    required Set<int> disabledSlots,
    required String printerName,
  }) async {
    try {
      // 1. Pre-print validation layer
      final sheetConfig = template.sheetConfig;
      if (sheetConfig == null) {
        return const Result.failure(
          ValidationError(message: 'Sheet configuration is required for custom label printing.'),
        );
      }
      final stickerConfig = template.stickerConfig;
      if (stickerConfig == null) {
        return const Result.failure(
          ValidationError(message: 'Sticker configuration is required for custom label printing.'),
        );
      }

      if (sheetConfig.pageWidth <= 0 || sheetConfig.pageHeight <= 0) {
        return const Result.failure(ValidationError(message: 'Page width and height must be greater than zero.'));
      }
      if (stickerConfig.widthMm <= 0 || stickerConfig.heightMm <= 0) {
        return const Result.failure(ValidationError(message: 'Sticker width and height must be greater than zero.'));
      }
      if (sheetConfig.columns <= 0 || sheetConfig.rows <= 0) {
        return const Result.failure(ValidationError(message: 'Columns and rows must be greater than zero.'));
      }
      if (sheetConfig.columnGap < 0 || sheetConfig.rowGap < 0) {
        return const Result.failure(ValidationError(message: 'Gaps cannot be negative.'));
      }
      if (sheetConfig.marginTop < 0 || sheetConfig.marginBottom < 0 ||
          sheetConfig.marginLeft < 0 || sheetConfig.marginRight < 0) {
        return const Result.failure(ValidationError(message: 'Margins cannot be negative.'));
      }
      if (quantity <= 0) {
        return const Result.failure(ValidationError(message: 'Quantity must be greater than zero.'));
      }

      // Check slot indices
      final maxSlots = sheetConfig.columns * sheetConfig.rows;
      for (final slot in disabledSlots) {
        if (slot < 0) {
          return const Result.failure(ValidationError(message: 'Disabled slot index cannot be negative.'));
        }
      }

      final requiredWidth = sheetConfig.marginLeft +
          sheetConfig.columns * stickerConfig.widthMm +
          (sheetConfig.columns - 1) * sheetConfig.columnGap +
          sheetConfig.marginRight;
      final requiredHeight = sheetConfig.marginTop +
          sheetConfig.rows * stickerConfig.heightMm +
          (sheetConfig.rows - 1) * sheetConfig.rowGap +
          sheetConfig.marginBottom;

      if (requiredWidth > sheetConfig.pageWidth || requiredHeight > sheetConfig.pageHeight) {
        return Result.failure(
          ValidationError(
            message: 'Sticker grid layout exceeds the physical sheet bounds. '
                'Required size: ${requiredWidth.toStringAsFixed(1)} x ${requiredHeight.toStringAsFixed(1)} mm. '
                'Configured sheet size: ${sheetConfig.pageWidth} x ${sheetConfig.pageHeight} mm.',
          ),
        );
      }

      if (stickerConfig.printableArea.isNotEmpty && stickerConfig.printableArea.length < 3) {
        return const Result.failure(ValidationError(message: 'Printable area polygon must have at least 3 points.'));
      }

      // Barcode / QR containment validation
      for (final element in template.elements) {
        final isBarcodeOrQr = element is BarcodeElementBlueprint || element is QrElementBlueprint;
        final isInside = PolygonUtils.isBoxInPolygon(
          x: element.x,
          y: element.y,
          width: element.width,
          height: element.height,
          rotationDegrees: element.rotation,
          vertices: stickerConfig.printableArea,
        );

        if (isBarcodeOrQr && !isInside) {
          return Result.failure(
            ValidationError(
              message: 'Barcode/QR element "${element.id}" falls outside the printable area polygon.',
            ),
          );
        } else if (!isInside) {
          // Log a warning for non-barcode elements that are clipped
          print('WARNING: Element "${element.id}" is outside the printable area polygon.');
        }
      }

      // 2. Pre-cache all network/asset/file images on the main thread
      final imageCache = await _preCacheImages(template);

      // 3. Offload the heavy compilation and saving process to a background Isolate
      final jobInput = _PdfJobInput(
        product: product,
        variant: variant,
        template: template,
        quantity: quantity,
        disabledSlots: disabledSlots,
        imageCache: imageCache,
        printerName: printerName,
      );

      final Uint8List pdfBytes;
      if (Platform.environment.containsKey('FLUTTER_TEST')) {
        pdfBytes = await _buildPdfDocumentInBackground(jobInput);
      } else {
        pdfBytes = await Isolate.run(() => _buildPdfDocumentInBackground(jobInput));
      }

      final targetFormat = PdfPageFormat(
        sheetConfig.pageWidth * PdfPageFormat.mm,
        sheetConfig.pageHeight * PdfPageFormat.mm,
        marginAll: 0,
      );

      if (Platform.isAndroid && !Platform.environment.containsKey('FLUTTER_TEST')) {
        const customPrintChannel = MethodChannel('co.inevitablesoftware.stickify/custom_print');
        await customPrintChannel.invokeMethod<bool>('printPdf', {
          'name': '${product.name}_${variant.name}_labels',
          'bytes': pdfBytes,
          'width': sheetConfig.pageWidth.toDouble(),
          'height': sheetConfig.pageHeight.toDouble(),
        });
      } else {
        await Printing.layoutPdf(
          name: '${product.name}_${variant.name}_labels',
          onLayout: (format) async => pdfBytes,
          format: targetFormat,
          dynamicLayout: false,
          forceCustomPrintPaper: true,
        );
      }

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        UnexpectedError(
          message: 'Failed to compile and print PDF document.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  /// Asynchronously pre-caches all images on the main thread where platform channels are active.
  Future<Map<String, Uint8List>> _preCacheImages(LabelTemplate template) async {
    final imageCache = <String, Uint8List>{};
    for (final bp in template.elements) {
      if (bp is ImageElementBlueprint) {
        if (bp.localFilePath != null && bp.localFilePath!.isNotEmpty) {
          try {
            final file = File(bp.localFilePath!);
            if (file.existsSync()) {
              imageCache[bp.localFilePath!] = file.readAsBytesSync();
            }
          } on FileSystemException catch (_) {
            // Safe fallback if local file access fails
          }
        } else if (bp.networkUrl != null && bp.networkUrl!.isNotEmpty) {
          final bytes = await _fetchNetworkImage(bp.networkUrl!);
          if (bytes != null) {
            imageCache[bp.networkUrl!] = bytes;
          }
        } else if (bp.assetPath != null && bp.assetPath!.isNotEmpty) {
          try {
            final data = await rootBundle.load(bp.assetPath!);
            imageCache[bp.assetPath!] = data.buffer.asUint8List();
          } on Object catch (_) {
            // Safe fallback if Flutter asset load fails
          }
        }
      }
    }
    return imageCache;
  }

  /// Fetches a network image's bytes using HttpClient.
  Future<Uint8List?> _fetchNetworkImage(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final builder = BytesBuilder();
        await response.forEach(builder.add);
        return builder.takeBytes();
      }
    } on HttpException catch (_) {
      // Safe fallback if connection fails
    }
    return null;
  }

  /// Map printer station strings to custom physical calibration profiles.
  static PrinterCalibration _getCalibrationForPrinter(String printerName) {
    if (printerName.contains('Zebra')) {
      return const PrinterCalibration(offsetX: 0.5, offsetY: -0.2);
    } else if (printerName.contains('Brother')) {
      return const PrinterCalibration(offsetX: -0.3, offsetY: 0.3);
    } else if (printerName.contains('Industrial')) {
      return const PrinterCalibration(offsetX: 0.0, offsetY: 0.0, scaleX: 1.01, scaleY: 1.01);
    }
    return const PrinterCalibration();
  }

  /// Background isolate compilation task.
  static Future<Uint8List> _buildPdfDocumentInBackground(
    _PdfJobInput input,
  ) async {
    final doc = pw.Document(
      compress: !Platform.environment.containsKey('FLUTTER_TEST'),
    );

    final sheetConfig = input.template.sheetConfig!;
    final sticker = input.template.stickerConfig!;

    final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
    final totalSheets = _calculateTotalSheets(
      input.quantity,
      slotsPerSheet,
      input.disabledSlots,
    );
    final activePositions = _getActivePositions(
      input.quantity,
      input.disabledSlots,
    );

    final targetFormat = PdfPageFormat(
      sheetConfig.pageWidth * PdfPageFormat.mm,
      sheetConfig.pageHeight * PdfPageFormat.mm,
      marginAll: 0,
    );

    final cal = _getCalibrationForPrinter(input.printerName);

    // Build pages using absolute stacking coordinates
    for (var sheetIndex = 0; sheetIndex < totalSheets; sheetIndex++) {
      final pageSlots = <pw.Widget>[];

      for (var r = 0; r < sheetConfig.rows; r++) {
        for (var c = 0; c < sheetConfig.columns; c++) {
          final cellIndex = r * sheetConfig.columns + c;
          final absIndex = sheetIndex * slotsPerSheet + cellIndex;
          final isActive = activePositions.contains(absIndex);

          if (isActive) {
            // Calculate physical grid position in mm
            var slotX = sheetConfig.marginLeft + c * (sticker.widthMm + sheetConfig.columnGap);
            var slotY = sheetConfig.marginTop + r * (sticker.heightMm + sheetConfig.rowGap);

            // Apply calibration settings
            slotX += cal.offsetX;
            slotY += cal.offsetY;

            final slotWidth = sticker.widthMm * cal.scaleX;
            final slotHeight = sticker.heightMm * cal.scaleY;

            pageSlots.add(
              pw.Positioned(
                left: slotX * PdfPageFormat.mm,
                top: slotY * PdfPageFormat.mm,
                child: pw.SizedBox(
                  width: slotWidth * PdfPageFormat.mm,
                  height: slotHeight * PdfPageFormat.mm,
                  child: _buildStickerContent(
                    template: input.template,
                    sticker: sticker,
                    product: input.product,
                    variant: input.variant,
                    imageCache: input.imageCache,
                  ),
                ),
              ),
            );
          }
        }
      }

      doc.addPage(
        pw.Page(
          pageFormat: targetFormat,
          build: (context) {
            return pw.Stack(
              children: pageSlots,
            );
          },
        ),
      );
    }

    return doc.save();
  }

  /// Compile fresh widgets tree for a single sticker slot instance.
  static pw.Widget _buildStickerContent({
    required LabelTemplate template,
    required StickerConfig sticker,
    required Product product,
    required ProductVariant variant,
    required Map<String, Uint8List> imageCache,
  }) {
    final elements = <pw.Widget>[];

    for (final bp in template.elements) {
      final renderer = PdfElementRendererRegistry.getRenderer(bp);
      final childWidget = renderer.render(
        bp,
        product,
        variant,
        imageCache,
      );

      elements.add(
        pw.Positioned(
          left: bp.x * PdfPageFormat.mm,
          top: bp.y * PdfPageFormat.mm,
          child: pw.Transform.rotate(
            angle: bp.rotation * (3.141592653589793 / 180),
            child: pw.SizedBox(
              width: bp.width * PdfPageFormat.mm,
              height: bp.height * PdfPageFormat.mm,
              child: childWidget,
            ),
          ),
        ),
      );
    }

    final content = pw.Stack(
      children: elements,
    );

    // Apply polygon clipping if a custom shape is configured
    if (sticker.printableArea.length >= 3) {
      return pw.CustomPaint(
        painter: (PdfGraphics canvas, PdfPoint size) {
          final vertices = sticker.printableArea;
          // Flip Y coordinate system for PDF Graphics (starts bottom-left)
          canvas.moveTo(
            vertices[0].x * PdfPageFormat.mm,
            (sticker.heightMm - vertices[0].y) * PdfPageFormat.mm,
          );
          for (var i = 1; i < vertices.length; i++) {
            canvas.lineTo(
              vertices[i].x * PdfPageFormat.mm,
              (sticker.heightMm - vertices[i].y) * PdfPageFormat.mm,
            );
          }
          canvas.closePath();
          canvas.clipPath();
        },
        child: content,
      );
    }

    return content;
  }

  /// Calculates the total sheets required given the target quantity and disabled slot positions.
  static int _calculateTotalSheets(
    int qty,
    int slotsPerSheet,
    Set<int> disabledSlots,
  ) {
    if (qty <= 0) return 0;
    var activePlaced = 0;
    var currentSlot = 0;
    while (activePlaced < qty) {
      if (!disabledSlots.contains(currentSlot)) {
        activePlaced++;
      }
      if (activePlaced < qty) {
        currentSlot++;
      }
    }
    return (currentSlot / slotsPerSheet).floor() + 1;
  }

  /// Returns a set of all active slot index positions that contain label stickers.
  static Set<int> _getActivePositions(int qty, Set<int> disabledSlots) {
    final active = <int>{};
    var activePlaced = 0;
    var currentSlot = 0;
    while (activePlaced < qty) {
      if (!disabledSlots.contains(currentSlot)) {
        active.add(currentSlot);
        activePlaced++;
      }
      currentSlot++;
    }
    return active;
  }
}

/// Isolate message wrapper carrying print execution payload.
class _PdfJobInput {
  /// Creates a [_PdfJobInput] payload.
  const _PdfJobInput({
    required this.product,
    required this.variant,
    required this.template,
    required this.quantity,
    required this.disabledSlots,
    required this.imageCache,
    required this.printerName,
  });

  /// The active product.
  final Product product;

  /// The active product variant.
  final ProductVariant variant;

  /// The label design template to compile.
  final LabelTemplate template;

  /// Number of labels to print.
  final int quantity;

  /// Slot grid positions on the sheet marked as disabled/skipped.
  final Set<int> disabledSlots;

  /// Pre-cached image asset bytes indexed by source path/URL.
  final Map<String, Uint8List> imageCache;

  /// The selected printer station name.
  final String printerName;
}
