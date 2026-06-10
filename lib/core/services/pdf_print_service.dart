import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

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
    final doc = pw.Document();

    final sheetConfig = template.sheetConfig ??
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

    final sticker = template.stickerConfig ??
        const StickerConfig(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          printableArea: [],
        );

    final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
    final totalSheets = _calculateTotalSheets(quantity, slotsPerSheet, disabledSlots);
    final activePositions = _getActivePositions(quantity, disabledSlots);

    // Pre-cache all network/asset/file images used in the template elements
    // to prevent asynchronous layout blocks during PDF generation.
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
            final List<pw.Widget> elementWidgets = [];
            for (final bp in template.elements) {
              final childWidget = await _buildElement(bp, product, variant, imageCache);

              elementWidgets.add(
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
                      children: elementWidgets,
                    ),
                  ),
                ),
              ),
            );
          } else {
            // Unused or skipped slot represented by an empty container of the exact sticker size
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

    // Launch the native system print dialog
    await Printing.layoutPdf(
      name: '${product.name}_${variant.name}_labels',
      onLayout: (format) async => doc.save(),
    );
  }

  int _calculateTotalSheets(int qty, int slotsPerSheet, Set<int> disabledSlots) {
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

  Set<int> _getActivePositions(int qty, Set<int> disabledSlots) {
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

  Future<pw.Widget> _buildElement(
    ElementBlueprint bp,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache,
  ) async {
    if (bp is TextElementBlueprint) {
      final text = bp.isDynamic
          ? TextElementRenderer.resolveToken(bp.content, product, variant)
          : bp.content;

      final fontWeight = switch (bp.fontWeightValue) {
        >= 700 => pw.FontWeight.bold,
        _ => pw.FontWeight.normal,
      };

      final textAlign = switch (bp.textAlign) {
        BlueprintTextAlign.left => pw.TextAlign.left,
        BlueprintTextAlign.center => pw.TextAlign.center,
        BlueprintTextAlign.right => pw.TextAlign.right,
        BlueprintTextAlign.justify => pw.TextAlign.justify,
      };

      return pw.Text(
        text,
        textAlign: textAlign,
        style: pw.TextStyle(
          fontSize: bp.fontSize,
          fontWeight: fontWeight,
          color: PdfColor.fromInt(bp.colorHex),
          letterSpacing: bp.letterSpacing,
        ),
      );
    }

    if (bp is ShapeElementBlueprint) {
      return pw.Container(
        width: bp.width,
        height: bp.height,
        decoration: pw.BoxDecoration(
          color: bp.isFilled ? PdfColor.fromInt(bp.fillColorHex) : null,
          borderRadius: pw.BorderRadius.circular(bp.cornerRadius),
          border: pw.Border.all(
            color: PdfColor.fromInt(bp.strokeColorHex),
            width: bp.strokeWidth,
          ),
        ),
      );
    }

    if (bp is BarcodeElementBlueprint) {
      final barcodeData = bp.isDynamic
          ? TextElementRenderer.resolveToken(bp.data, product, variant)
          : bp.data;
      final data = barcodeData.isEmpty ? '12345678' : barcodeData;

      final symbology = switch (bp.barcodeType) {
        BlueprintBarcodeType.code128 => pw.Barcode.code128(),
        BlueprintBarcodeType.ean13 => pw.Barcode.ean13(),
      };

      return pw.BarcodeWidget(
        barcode: symbology,
        data: data,
        width: bp.width,
        height: bp.height,
      );
    }

    if (bp is QrElementBlueprint) {
      final qrData = bp.isDynamic
          ? TextElementRenderer.resolveToken(bp.data, product, variant)
          : bp.data;
      final data = qrData.isEmpty ? 'https://stickify.io' : qrData;

      return pw.BarcodeWidget(
        barcode: pw.Barcode.qrCode(),
        data: data,
        width: bp.width,
        height: bp.height,
      );
    }

    if (bp is ImageElementBlueprint) {
      final pdfBoxFit = switch (bp.fit) {
        BlueprintBoxFit.fill => pw.BoxFit.fill,
        BlueprintBoxFit.contain => pw.BoxFit.contain,
        BlueprintBoxFit.cover => pw.BoxFit.cover,
        BlueprintBoxFit.fitWidth => pw.BoxFit.fitWidth,
        BlueprintBoxFit.fitHeight => pw.BoxFit.fitHeight,
        BlueprintBoxFit.none => pw.BoxFit.none,
      };

      Uint8List? bytes;
      if (bp.localFilePath != null && bp.localFilePath!.isNotEmpty) {
        bytes = imageCache[bp.localFilePath!];
      } else if (bp.networkUrl != null && bp.networkUrl!.isNotEmpty) {
        bytes = imageCache[bp.networkUrl!];
      } else if (bp.assetPath != null && bp.assetPath!.isNotEmpty) {
        bytes = imageCache[bp.assetPath!];
      }

      if (bytes != null) {
        try {
          return pw.Image(pw.MemoryImage(bytes), fit: pdfBoxFit);
        } catch (_) {}
      }

      // Fallback gray container if image cannot be loaded
      return pw.Container(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        child: pw.Center(
          child: pw.Text('[Image]', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
      );
    }

    return pw.SizedBox();
  }
}
