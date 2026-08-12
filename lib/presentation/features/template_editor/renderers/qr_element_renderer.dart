import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

/// Renders a [QrElementBlueprint] on the designer canvas.
class QrElementRenderer implements LabelElementRenderer {
  /// Creates a [QrElementRenderer] instance.
  const QrElementRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
    DateTime? manufacturingDate,
  }) {
    final bp = blueprint as QrElementBlueprint;
    final qrData = bp.isDynamic
        ? TextElementRenderer.resolveToken(bp.data, product, variant, manufacturingDate)
        : bp.data;

    // Fallback if data is empty
    final data = qrData.isEmpty ? 'https://stickify.io' : qrData;

    return SizedBox(
      width: bp.width * 4.0,
      height: bp.height * 4.0,
      child: BarcodeWidget(
        barcode: Barcode.qrCode(),
        data: data,
        errorBuilder: (context, error) => const Center(
          child: Text(
            'Invalid QR Code',
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFFFF0000),
            ),
          ),
        ),
      ),
    );
  }
}
