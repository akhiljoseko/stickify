import 'dart:io';
import 'dart:isolate';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';

/// Concrete implementation of [PrintService] using the `pdf` and `printing` packages.
class PdfPrintService implements PrintService {
  const PdfPrintService();

  @override
  Future<void> printLabels({
    required Product product,
    required ProductVariant variant,
    required LabelTemplate template,
    required int quantity,
    required Set<int> disabledSlots,
    required String printerName,
  }) async {
    // 1. Pre-cache all network/asset/file images on the main thread
    // to prevent asynchronous layout blocks or platform channel errors during background Isolate execution.
    final imageCache = await _preCacheImages(template);

    // 2. Offload the heavy compilation and saving process to a background Isolate
    final pdfBytes = await Isolate.run(() => _buildPdfDocumentInBackground(
          _PdfJobInput(
            product: product,
            variant: variant,
            template: template,
            quantity: quantity,
            disabledSlots: disabledSlots,
            imageCache: imageCache,
          ),
        ));

    // 3. Launch the native system print dialog
    await Printing.layoutPdf(
      name: '${product.name}_${variant.name}_labels',
      onLayout: (format) async => pdfBytes,
    );
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
          } catch (_) {}
        } else if (bp.networkUrl != null && bp.networkUrl!.isNotEmpty) {
          final bytes = await _fetchNetworkImage(bp.networkUrl!);
          if (bytes != null) {
            imageCache[bp.networkUrl!] = bytes;
          }
        } else if (bp.assetPath != null && bp.assetPath!.isNotEmpty) {
          try {
            final data = await rootBundle.load(bp.assetPath!);
            imageCache[bp.assetPath!] = data.buffer.asUint8List();
          } catch (_) {}
        }
      }
    }
    return imageCache;
  }

  Future<Uint8List?> _fetchNetworkImage(String url) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode == 200) {
        final builder = BytesBuilder();
        await for (final chunk in response) {
          builder.add(chunk);
        }
        return builder.takeBytes();
      }
    } catch (_) {}
    return null;
  }

  /// Background isolate compilation task.
  static Future<Uint8List> _buildPdfDocumentInBackground(_PdfJobInput input) async {
    final doc = pw.Document();

    final sheetConfig = input.template.sheetConfig ??
        const SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 2,
          rows: 5,
          columnGap: 5,
          rowGap: 5,
        );

    final sticker = input.template.stickerConfig ??
        const StickerConfig(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          printableArea: [],
        );

    final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
    final totalSheets = _calculateTotalSheets(input.quantity, slotsPerSheet, input.disabledSlots);
    final activePositions = _getActivePositions(input.quantity, input.disabledSlots);

    // Build the template elements ONCE to optimize generation and prevent duplicate tree instantiation
    final List<pw.Widget> cachedStickerElements = [];
    for (final bp in input.template.elements) {
      final renderer = PdfElementRendererRegistry.getRenderer(bp);
      final childWidget = renderer.render(bp, input.product, input.variant, input.imageCache);

      cachedStickerElements.add(
        pw.Positioned(
          left: bp.x,
          top: bp.y,
          child: pw.Transform.rotate(
            angle: bp.rotation * (3.141592653589793 / 180),
            child: pw.SizedBox(
              width: bp.width,
              height: bp.height,
              child: childWidget,
            ),
          ),
        ),
      );
    }

    // Build pages
    for (int sheetIndex = 0; sheetIndex < totalSheets; sheetIndex++) {
      final List<pw.Widget> rowsList = [];

      for (int r = 0; r < sheetConfig.rows; r++) {
        final List<pw.Widget> rowCells = [];

        for (int c = 0; c < sheetConfig.columns; c++) {
          final cellIndex = r * sheetConfig.columns + c;
          final absIndex = sheetIndex * slotsPerSheet + cellIndex;
          final isActive = activePositions.contains(absIndex);

          pw.Widget cellWidget;
          if (isActive) {
            cellWidget = pw.Container(
              width: sticker.widthMm * PdfPageFormat.mm,
              height: sticker.heightMm * PdfPageFormat.mm,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                borderRadius: pw.BorderRadius.circular(sticker.cornerRadiusMm),
              ),
              child: pw.ClipRRect(
                horizontalRadius: sticker.cornerRadiusMm,
                verticalRadius: sticker.cornerRadiusMm,
                child: pw.FittedBox(
                  fit: pw.BoxFit.contain,
                  child: pw.SizedBox(
                    width: sticker.widthMm * 4,
                    height: sticker.heightMm * 4,
                    child: pw.Stack(
                      children: cachedStickerElements,
                    ),
                  ),
                ),
              ),
            );
          } else {
            cellWidget = pw.Container(
              width: sticker.widthMm * PdfPageFormat.mm,
              height: sticker.heightMm * PdfPageFormat.mm,
            );
          }

          rowCells.add(cellWidget);
          if (c < sheetConfig.columns - 1) {
            rowCells.add(pw.SizedBox(width: sheetConfig.columnGap * PdfPageFormat.mm));
          }
        }

        rowsList.add(pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.start,
          children: rowCells,
        ));
        if (r < sheetConfig.rows - 1) {
          rowsList.add(pw.SizedBox(height: sheetConfig.rowGap * PdfPageFormat.mm));
        }
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            sheetConfig.pageWidth * PdfPageFormat.mm,
            sheetConfig.pageHeight * PdfPageFormat.mm,
            marginTop: sheetConfig.marginTop * PdfPageFormat.mm,
            marginBottom: sheetConfig.marginBottom * PdfPageFormat.mm,
            marginLeft: sheetConfig.marginLeft * PdfPageFormat.mm,
            marginRight: sheetConfig.marginRight * PdfPageFormat.mm,
          ),
          build: (pw.Context context) {
            return pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.start,
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: rowsList,
            );
          },
        ),
      );
    }

    return doc.save();
  }

  static int _calculateTotalSheets(int qty, int slotsPerSheet, Set<int> disabledSlots) {
    if (qty <= 0) return 0;
    int activePlaced = 0;
    int currentSlot = 0;
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

  static Set<int> _getActivePositions(int qty, Set<int> disabledSlots) {
    final active = <int>{};
    int activePlaced = 0;
    int currentSlot = 0;
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
  const _PdfJobInput({
    required this.product,
    required this.variant,
    required this.template,
    required this.quantity,
    required this.disabledSlots,
    required this.imageCache,
  });

  final Product product;
  final ProductVariant variant;
  final LabelTemplate template;
  final int quantity;
  final Set<int> disabledSlots;
  final Map<String, Uint8List> imageCache;
}
