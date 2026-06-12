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
    Map<String, Uint8List> imageCache,
  ) {
    final text = blueprint.isDynamic
        ? TextElementRenderer.resolveToken(blueprint.content, product, variant)
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
    Map<String, Uint8List> imageCache,
  ) {
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
    Map<String, Uint8List> imageCache,
  ) {
    final barcodeData = blueprint.isDynamic
        ? TextElementRenderer.resolveToken(blueprint.data, product, variant)
        : blueprint.data;
    final data = barcodeData.isEmpty ? '12345678' : barcodeData;

    final symbology = switch (blueprint.barcodeType) {
      BlueprintBarcodeType.code128 => pw.Barcode.code128(),
      BlueprintBarcodeType.ean13 => pw.Barcode.ean13(),
    };

    return pw.BarcodeWidget(
      barcode: symbology,
      data: data,
      width: blueprint.width * PdfPageFormat.mm,
      height: blueprint.height * PdfPageFormat.mm,
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
    Map<String, Uint8List> imageCache,
  ) {
    final qrData = blueprint.isDynamic
        ? TextElementRenderer.resolveToken(blueprint.data, product, variant)
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
    Map<String, Uint8List> imageCache,
  ) {
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
