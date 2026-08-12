import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/domain/domain.dart';

/// Concrete layout engine that compiles sticker layouts into PDF bytes.
class LabelPdfLayoutEngine implements LabelLayoutEngine {
  /// Instantiates a new [LabelPdfLayoutEngine].
  const LabelPdfLayoutEngine({
    this.useIsolate = true,
  });

  /// Whether to run the layout generation in a background isolate.
  final bool useIsolate;

  @override
  Future<Uint8List> buildPdfBytes({
    required Product product,
    required ProductVariant variant,
    required LabelTemplate template,
    required int quantity,
    required Set<int> disabledSlots,
    bool printFromBottom = false,
    PdfPageFormat? physicalFormat,
    PrintCoordinateContext? coordinateContext,
  }) async {
    // 1. Pre-cache all network/asset/file images on the main thread
    final imageCache = await _preCacheImages(template);

    // Load custom Unicode fonts on main thread (isolates cannot run rootBundle load)
    final regularFontData = await rootBundle.load('assets/fonts/Arial-Regular.ttf');
    final boldFontData = await rootBundle.load('assets/fonts/Arial-Bold.ttf');
    final regularFontBytes = regularFontData.buffer.asUint8List();
    final boldFontBytes = boldFontData.buffer.asUint8List();

    // 2. Offload compilation to a background Isolate (unless configured not to)
    final jobInput = _PdfJobInput(
      product: product,
      variant: variant,
      template: template,
      quantity: quantity,
      disabledSlots: disabledSlots,
      imageCache: imageCache,
      compress: useIsolate,
      printFromBottom: printFromBottom,
      regularFontBytes: regularFontBytes,
      boldFontBytes: boldFontBytes,
      physicalFormat: physicalFormat,
      coordinateContext: coordinateContext ?? const PrintCoordinateContext.identity(),
    );

    if (useIsolate) {
      return Isolate.run(() => _buildPdfDocumentInBackground(jobInput));
    } else {
      return _buildPdfDocumentInBackground(jobInput);
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

  /// Background isolate compilation task.
  static Future<Uint8List> _buildPdfDocumentInBackground(
    _PdfJobInput input,
  ) async {
    PdfElementRendererRegistry.registerDefaults();

    final doc = pw.Document(
      compress: input.compress,
    );

    // Create TrueType fonts from loaded bytes
    final regularFont = pw.Font.ttf(input.regularFontBytes.buffer.asByteData());
    final boldFont = pw.Font.ttf(input.boldFontBytes.buffer.asByteData());
    final pageTheme = pw.ThemeData.withFont(
      base: regularFont,
      bold: boldFont,
      fontFallback: [regularFont, boldFont],
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
      qty: input.quantity,
      slotsPerSheet: slotsPerSheet,
      disabledSlots: input.disabledSlots,
      printFromBottom: input.printFromBottom,
    );

    final physicalFormat = input.physicalFormat;

    // Detect if spooled format is Portrait while template layout is Landscape (Case B)
    final isSpooledAsPortrait = physicalFormat != null &&
        sheetConfig.pageWidth > sheetConfig.pageHeight &&
        physicalFormat.width < physicalFormat.height;

    final targetFormat = isSpooledAsPortrait
        ? PdfPageFormat(
            physicalFormat.width,
            physicalFormat.height,
            marginAll: 0,
          )
        : PdfPageFormat(
            sheetConfig.pageWidth * PdfPageFormat.mm,
            sheetConfig.pageHeight * PdfPageFormat.mm,
            marginAll: 0,
          );

    // Driver margins: when the PDF is spooled, the print driver may impose a top
    // margin that shifts content down. For landscape templates printed directly
    // (isSpooledAsPortrait=false), the shiftY from the driver's reported margin
    // compensates. For rotated (spooled-as-portrait) jobs, the driver rotates the
    // page 90°, making the template's X-axis the physical Y-axis. In that case
    // the top margin becomes a left-margin in template space, so shiftX is the
    // appropriate compensation.
    double shiftX = 0;
    double shiftY = 0;
    if (isSpooledAsPortrait) {
      shiftX = physicalFormat.marginTop / PdfPageFormat.mm;
    } else if (physicalFormat != null &&
        sheetConfig.pageWidth > sheetConfig.pageHeight) {
      shiftY = physicalFormat.marginTop / PdfPageFormat.mm;
    }

    Log.debug(
      'LayoutEngine: pageFormat=${(targetFormat.width / PdfPageFormat.mm).toStringAsFixed(1)}'
      'x${(targetFormat.height / PdfPageFormat.mm).toStringAsFixed(1)}mm '
      'isSpooledAsPortrait=$isSpooledAsPortrait '
      'shiftX=${shiftX.toStringAsFixed(2)}mm shiftY=${shiftY.toStringAsFixed(2)}mm '
      'sticker=${sticker.widthMm}x${sticker.heightMm}mm',
      tag: 'PrintPipeline',
    );

    // Build pages using absolute stacking coordinates
    for (var sheetIndex = 0; sheetIndex < totalSheets; sheetIndex++) {
      final pageSlots = <pw.Widget>[];

      for (var r = 0; r < sheetConfig.rows; r++) {
        for (var c = 0; c < sheetConfig.columns; c++) {
          final cellIndex = r * sheetConfig.columns + c;
          final absIndex = sheetIndex * slotsPerSheet + cellIndex;
          final isActive = activePositions.contains(absIndex);

          if (isActive) {
            // Resolve any coordinate transformation for this sticker slot.
            // The identity transform (default) produces zero offset and 1.0
            // scale — output is byte-equivalent to pre-1A behavior.
            final transform = input.coordinateContext.resolveFor(
              row: r,
              column: c,
              absoluteSlotIndex: absIndex,
              slotsPerSheet: slotsPerSheet,
            );

            // Calculate physical grid position in mm.
            // Driver shift (shiftX/shiftY) is kept additive and independent
            // from the coordinate context — see Phase 0 analysis, section 3.2.
            final slotX =
                sheetConfig.marginLeft +
                c * (sticker.widthMm + sheetConfig.columnGap) +
                shiftX +
                (sticker.widthMm * transform.anchorX * (1.0 - transform.scaleX)) +
                transform.offsetX;
            final slotY =
                sheetConfig.marginTop +
                r * (sticker.heightMm + sheetConfig.rowGap) +
                shiftY +
                (sticker.heightMm * transform.anchorY * (1.0 - transform.scaleY)) +
                transform.offsetY;

            // Clamp slotY to 0 — a negative value would push stickers above the
            // PDF page boundary and get clipped. This can happen when Level 3
            // translation resolves a rotated right-edge conflict (which maps to
            // the template top edge) by shifting content upward.
            final clampedSlotY = slotY < 0 ? 0.0 : slotY;
            if (clampedSlotY != slotY) {
              Log.debug(
                'LayoutEngine: slot(r=$r,c=$c) slotY clamped from '
                '${slotY.toStringAsFixed(2)}mm to 0mm to prevent page clipping',
                tag: 'PrintPipeline',
              );
            }

            // Log the first sticker of each row and column to debug positioning
            Log.debug(
              'LayoutEngine: slot(r=$r,c=$c) '
              'slotX=${slotX.toStringAsFixed(2)}mm slotY=${slotY.toStringAsFixed(2)}mm '
              'offsetX=${transform.offsetX.toStringAsFixed(3)} '
              'offsetY=${transform.offsetY.toStringAsFixed(3)} '
              'scaleX=${transform.scaleX.toStringAsFixed(5)} '
              'scaleY=${transform.scaleY.toStringAsFixed(5)}',
              tag: 'PrintPipeline',
            );
            if (r == 0 || c == 0) {
              Log.debug(
                'LayoutEngine[pos]: slot(r=$r,c=$c) '
                'pageW=${(targetFormat.width / PdfPageFormat.mm).toStringAsFixed(1)}mm '
                'pageH=${(targetFormat.height / PdfPageFormat.mm).toStringAsFixed(1)}mm '
                'isSpooledAsPortrait=$isSpooledAsPortrait '
                'slotLeft=${slotX.toStringAsFixed(2)}mm '
                'slotTop=${clampedSlotY.toStringAsFixed(2)}mm '
                'slotRight=${(slotX + sticker.widthMm).toStringAsFixed(2)}mm '
                'slotBottom=${(clampedSlotY + sticker.heightMm).toStringAsFixed(2)}mm',
                tag: 'PrintPipeline',
              );
            }

            pageSlots.add(
              pw.Positioned(
                left: slotX * PdfPageFormat.mm,
                top: clampedSlotY * PdfPageFormat.mm,
                child: pw.SizedBox(
                  // Keep at original sticker dimensions — the transform
                  // (scale, clipping polygon) is applied inside the content
                  // so they stay in the same coordinate space and the Sized Box
                  // never clips elements that belong to this sticker.
                  width: sticker.widthMm * PdfPageFormat.mm,
                  height: sticker.heightMm * PdfPageFormat.mm,
                  child: _buildStickerContent(
                    template: input.template,
                    sticker: sticker,
                    product: input.product,
                    variant: input.variant,
                    imageCache: input.imageCache,
                    scaleX: transform.scaleX,
                    scaleY: transform.scaleY,
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
          orientation: isSpooledAsPortrait ? pw.PageOrientation.landscape : null,
          theme: pageTheme,
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
  /// [scaleX] and [scaleY] are applied to element positions/sizes and the
  /// clipping polygon so everything stays in the same coordinate space and
  /// no spurious clipping occurs from a mismatched Sized Box.
  static pw.Widget _buildStickerContent({
    required LabelTemplate template,
    required StickerConfig sticker,
    required Product product,
    required ProductVariant variant,
    required Map<String, Uint8List> imageCache,
    double scaleX = 1.0,
    double scaleY = 1.0,
  }) {
    final elements = <pw.Widget>[];

    for (final bp in template.elements) {
      final PdfElementRenderer renderer;
      try {
        renderer = PdfElementRendererRegistry.getRenderer(bp);
      } on Object catch (e, s) {
        throw UnexpectedError(
          message:
              'Unknown element type: No PDF renderer found for ${bp.runtimeType}.',
          originalError: e,
          stackTrace: s,
        );
      }
      final childWidget = renderer.render(
        bp,
        product,
        variant,
        imageCache,
      );

      final scaledX = bp.x * scaleX;
      final scaledY = bp.y * scaleY;
      final scaledWidth = bp.width * scaleX;
      final scaledHeight = bp.height * scaleY;

      elements.add(
        pw.Positioned(
          left: scaledX * PdfPageFormat.mm,
          top: scaledY * PdfPageFormat.mm,
          child: pw.Transform.rotate(
            angle: bp.rotation * (pi / 180),
            child: pw.SizedBox(
              width: scaledWidth * PdfPageFormat.mm,
              height: scaledHeight * PdfPageFormat.mm,
              child: childWidget,
            ),
          ),
        ),
      );
    }

    final content = pw.Stack(
      children: elements,
    );

    // Apply polygon clipping if a custom shape is configured.
    // The polygon vertices are also scaled to match the element positions.
    if (sticker.printableArea.length >= 3) {
      return pw.CustomPaint(
        painter: (canvas, size) {
          final vertices = sticker.printableArea;
          // Flip Y coordinate system for PDF Graphics (starts bottom-left).
          // Elements scale downwards from the top edge (Y = heightMm).
          canvas.moveTo(
            vertices[0].x * scaleX * PdfPageFormat.mm,
            (sticker.heightMm - (vertices[0].y * scaleY)) * PdfPageFormat.mm,
          );
          for (var i = 1; i < vertices.length; i++) {
            canvas.lineTo(
              vertices[i].x * scaleX * PdfPageFormat.mm,
              (sticker.heightMm - (vertices[i].y * scaleY)) * PdfPageFormat.mm,
            );
          }
          canvas
            ..closePath()
            ..clipPath();
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
  static Set<int> _getActivePositions({
    required int qty,
    required int slotsPerSheet,
    required Set<int> disabledSlots,
    required bool printFromBottom,
  }) {
    final active = <int>{};
    final totalSheets = _calculateTotalSheets(
      qty,
      slotsPerSheet,
      disabledSlots,
    );
    var remainingQty = qty;

    for (var sheetIndex = 0; sheetIndex < totalSheets; sheetIndex++) {
      final sheetStart = sheetIndex * slotsPerSheet;
      final sheetEnd = (sheetIndex + 1) * slotsPerSheet;

      var availableOnSheet = 0;
      for (var slot = sheetStart; slot < sheetEnd; slot++) {
        if (!disabledSlots.contains(slot)) {
          availableOnSheet++;
        }
      }

      if (availableOnSheet == 0) {
        continue;
      }

      final toPlace = min(remainingQty, availableOnSheet);
      final isLastSheet = sheetIndex == totalSheets - 1;

      if (isLastSheet && printFromBottom) {
        var placed = 0;
        for (var slot = sheetEnd - 1; slot >= sheetStart; slot--) {
          if (placed >= toPlace) break;
          if (!disabledSlots.contains(slot)) {
            active.add(slot);
            placed++;
          }
        }
      } else {
        var placed = 0;
        for (var slot = sheetStart; slot < sheetEnd; slot++) {
          if (placed >= toPlace) break;
          if (!disabledSlots.contains(slot)) {
            active.add(slot);
            placed++;
          }
        }
      }

      remainingQty -= toPlace;
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
    required this.compress,
    required this.printFromBottom,
    required this.regularFontBytes,
    required this.boldFontBytes,
    required this.coordinateContext,
    this.physicalFormat,
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

  /// Whether to compress the generated PDF.
  final bool compress;

  /// Whether to print from the bottom of the last sheet.
  final bool printFromBottom;

  /// Regular font bytes.
  final Uint8List regularFontBytes;

  /// Bold font bytes.
  final Uint8List boldFontBytes;

  /// Coordinate transformations to apply during PDF slot layout.
  ///
  /// The identity context (default) produces output byte-equivalent to
  /// the pre-1A behavior.
  final PrintCoordinateContext coordinateContext;

  /// Physical format returned by GDI / printer driver.
  final PdfPageFormat? physicalFormat;
}
