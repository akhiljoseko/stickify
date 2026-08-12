import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stickify/core/services/pdf/pdf_element_renderer.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

/// Concrete Strategy for rendering [TextElementBlueprint] into PDF [pw.Text].
class PdfTextElementRenderer implements PdfElementRenderer<TextElementBlueprint> {
  /// Creates a [PdfTextElementRenderer] instance.
  const PdfTextElementRenderer();

  @override
  pw.Widget render(
    TextElementBlueprint blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache, [
    DateTime? manufacturingDate,
  ]) {
    final text = blueprint.isDynamic
        ? TextElementRenderer.resolveToken(blueprint.content, product, variant, manufacturingDate)
        : blueprint.content;

    final fontWeight = switch (blueprint.fontWeightValue) {
      >= 700 => pw.FontWeight.bold,
      _ => pw.FontWeight.normal,
    };

    final textAlign = switch (blueprint.textAlign) {
      BlueprintTextAlign.left => pw.TextAlign.left,
      BlueprintTextAlign.center => pw.TextAlign.center,
      BlueprintTextAlign.right => pw.TextAlign.right,
      BlueprintTextAlign.justify => pw.TextAlign.justify,
    };

    return pw.Text(
      text,
      textAlign: textAlign,
      maxLines: blueprint.maxLines,
      overflow: pw.TextOverflow.clip,
      style: pw.TextStyle(
        fontSize: blueprint.fontSize * PdfPageFormat.mm,
        fontWeight: fontWeight,
        color: PdfColor.fromInt(blueprint.colorHex),
        letterSpacing: blueprint.letterSpacing * PdfPageFormat.mm,
      ),
    );
  }
}

/// Concrete Strategy for rendering [ShapeElementBlueprint] into PDF shapes.
class PdfShapeElementRenderer implements PdfElementRenderer<ShapeElementBlueprint> {
  /// Creates a [PdfShapeElementRenderer] instance.
  const PdfShapeElementRenderer();

  @override
  pw.Widget render(
    ShapeElementBlueprint blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache, [
    DateTime? manufacturingDate,
  ]) {
    return pw.Container(
      width: blueprint.width * PdfPageFormat.mm,
      height: blueprint.height * PdfPageFormat.mm,
      decoration: pw.BoxDecoration(
        color: blueprint.isFilled ? PdfColor.fromInt(blueprint.fillColorHex) : null,
        borderRadius: pw.BorderRadius.circular(blueprint.cornerRadius * PdfPageFormat.mm),
        border: pw.Border.all(
          color: PdfColor.fromInt(blueprint.strokeColorHex),
          width: blueprint.strokeWidth * PdfPageFormat.mm,
        ),
      ),
    );
  }
}

/// Concrete Strategy for rendering [BarcodeElementBlueprint] into PDF barcode widgets.
class PdfBarcodeElementRenderer implements PdfElementRenderer<BarcodeElementBlueprint> {
  /// Creates a [PdfBarcodeElementRenderer] instance.
  const PdfBarcodeElementRenderer();

  @override
  pw.Widget render(
    BarcodeElementBlueprint blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache, [
    DateTime? manufacturingDate,
  ]) {
    final barcodeData = blueprint.isDynamic
        ? TextElementRenderer.resolveToken(blueprint.data, product, variant, manufacturingDate)
        : blueprint.data;

    final data = barcodeData.isEmpty ? '12345678' : barcodeData;

    final symbology = switch (blueprint.barcodeType) {
      BlueprintBarcodeType.code128 => pw.Barcode.code128(),
      BlueprintBarcodeType.ean13 => pw.Barcode.ean13(),
    };

    final widthMm = blueprint.width;
    final heightMm = blueprint.height;

    final barcodeWidget = pw.BarcodeWidget(
      barcode: symbology,
      data: data,
      width: widthMm * PdfPageFormat.mm,
      height: heightMm * PdfPageFormat.mm,
      drawText: false,
    );

    if (!blueprint.showLabel) {
      return barcodeWidget;
    }

    return pw.Column(
      children: [
        pw.SizedBox(
          width: widthMm * PdfPageFormat.mm,
          height: heightMm * PdfPageFormat.mm * 0.8,
          child: barcodeWidget,
        ),
        pw.SizedBox(
          width: widthMm * PdfPageFormat.mm,
          height: heightMm * PdfPageFormat.mm * 0.2,
          child: pw.Text(
            data,
            style: pw.TextStyle(
              fontSize: heightMm * 0.12 * PdfPageFormat.mm,
            ),
            maxLines: 1,
            overflow: pw.TextOverflow.clip,
          ),
        ),
      ],
    );
  }
}

/// Concrete Strategy for rendering [QrElementBlueprint] into PDF QR codes.
class PdfQrElementRenderer implements PdfElementRenderer<QrElementBlueprint> {
  /// Creates a [PdfQrElementRenderer] instance.
  const PdfQrElementRenderer();

  @override
  pw.Widget render(
    QrElementBlueprint blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache, [
    DateTime? manufacturingDate,
  ]) {
    final qrData = blueprint.isDynamic
        ? TextElementRenderer.resolveToken(blueprint.data, product, variant, manufacturingDate)
        : blueprint.data;
    final data = qrData.isEmpty ? 'https://stickify.io' : qrData;

    return pw.BarcodeWidget(
      barcode: pw.Barcode.qrCode(),
      data: data,
      width: blueprint.width * PdfPageFormat.mm,
      height: blueprint.height * PdfPageFormat.mm,
    );
  }
}

/// Concrete Strategy for rendering [ImageElementBlueprint] into PDF images.
class PdfImageElementRenderer implements PdfElementRenderer<ImageElementBlueprint> {
  /// Creates a [PdfImageElementRenderer] instance.
  const PdfImageElementRenderer();

  @override
  pw.Widget render(
    ImageElementBlueprint blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache, [
    DateTime? manufacturingDate,
  ]) {
    final pdfBoxFit = switch (blueprint.fit) {
      BlueprintBoxFit.fill => pw.BoxFit.fill,
      BlueprintBoxFit.contain => pw.BoxFit.contain,
      BlueprintBoxFit.cover => pw.BoxFit.cover,
      BlueprintBoxFit.fitWidth => pw.BoxFit.fitWidth,
      BlueprintBoxFit.fitHeight => pw.BoxFit.fitHeight,
      BlueprintBoxFit.none => pw.BoxFit.none,
    };

    Uint8List? bytes;
    if (blueprint.localFilePath != null && blueprint.localFilePath!.isNotEmpty) {
      bytes = imageCache[blueprint.localFilePath!];
    } else if (blueprint.networkUrl != null && blueprint.networkUrl!.isNotEmpty) {
      bytes = imageCache[blueprint.networkUrl!];
    } else if (blueprint.assetPath != null && blueprint.assetPath!.isNotEmpty) {
      bytes = imageCache[blueprint.assetPath!];
    }

    if (bytes != null) {
      try {
        return pw.Image(pw.MemoryImage(bytes), fit: pdfBoxFit);
      } on Object catch (_) {}
    }

    // Fallback gray container if image cannot be loaded
    return pw.Container(
      decoration: const pw.BoxDecoration(color: PdfColors.grey300),
      child: pw.Center(
        child: pw.Text('[Image]', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
    );
  }
}

/// Concrete Strategy for rendering [NutritionTableElementBlueprint] into PDF nutrition tables.
class PdfNutritionTableElementRenderer implements PdfElementRenderer<NutritionTableElementBlueprint> {
  /// Creates a [PdfNutritionTableElementRenderer] instance.
  const PdfNutritionTableElementRenderer();

  @override
  pw.Widget render(
    NutritionTableElementBlueprint blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache, [
    DateTime? manufacturingDate,
  ]) {
    final textColor = PdfColor.fromInt(blueprint.colorHex);

    // Resolve nutrition facts from product or use default mock values
    final nutrition = product?.nutritionFacts;
    final calories = nutrition?.calories ?? 250.0;
    final protein = nutrition?.protein ?? 10.0;
    final totalFat = nutrition?.totalFat ?? 8.0;
    final saturatedFat = nutrition?.saturatedFat ?? 2.5;
    final totalCarbs = nutrition?.totalCarbs ?? 30.0;
    final fiber = nutrition?.fiber ?? 3.0;

    return pw.FittedBox(
      fit: pw.BoxFit.fill,
      child: pw.Container(
        width: 240,
        height: 320,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: textColor, width: 4),
        ),
        padding: const pw.EdgeInsets.all(12),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              'Nutrition Facts',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: textColor,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.Divider(color: textColor, thickness: 4, height: 16),
            _buildRow('Energy/Calories', '${calories.toStringAsFixed(0)} kcal', textColor, isBold: true),
            pw.Divider(color: textColor, thickness: 2, height: 10),
            _buildRow('Total Fat', '${totalFat.toStringAsFixed(1)} g', textColor),
            pw.Divider(color: textColor, thickness: 1, height: 10),
            _buildRow('  Saturated Fat', '${saturatedFat.toStringAsFixed(1)} g', textColor, isSub: true),
            pw.Divider(color: textColor, thickness: 2, height: 10),
            _buildRow('Total Carbohydrate', '${totalCarbs.toStringAsFixed(1)} g', textColor),
            pw.Divider(color: textColor, thickness: 1, height: 10),
            _buildRow('  Dietary Fiber', '${fiber.toStringAsFixed(1)} g', textColor, isSub: true),
            pw.Divider(color: textColor, thickness: 2, height: 10),
            _buildRow('Protein', '${protein.toStringAsFixed(1)} g', textColor, isBold: true),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildRow(
    String label,
    String value,
    PdfColor color, {
    bool isBold = false,
    bool isSub = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: isSub ? 15 : 16,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
