import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

class BarcodeElementRenderer implements LabelElementRenderer {
  const BarcodeElementRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
  }) {
    final bp = blueprint as BarcodeElementBlueprint;
    final barcodeData = bp.isDynamic
        ? TextElementRenderer.resolveToken(bp.data, product)
        : bp.data;

    // Fallback data if empty to prevent widget crashes
    final data = barcodeData.isEmpty ? '12345678' : barcodeData;

    final barcodeSymbology = switch (bp.barcodeType) {
      BlueprintBarcodeType.code128 => Barcode.code128(),
      BlueprintBarcodeType.ean13 => Barcode.ean13(),
    };

    return SizedBox(
      width: bp.width,
      height: bp.height,
      child: BarcodeWidget(
        barcode: barcodeSymbology,
        data: data,
        // showText: bp.showLabel,
        errorBuilder: (context, error) => const Center(
          child: Text(
            'Invalid Barcode',
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
