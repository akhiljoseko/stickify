import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/widgets.dart';
import 'package:stickify/core/constants/dimensions.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

/// Renders a [BarcodeElementBlueprint] on the designer canvas.
class BarcodeElementRenderer implements LabelElementRenderer {
  /// Creates a [BarcodeElementRenderer] instance.
  const BarcodeElementRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
  }) {
    final bp = blueprint as BarcodeElementBlueprint;
    final barcodeData = bp.isDynamic
        ? TextElementRenderer.resolveToken(bp.data, product, variant)
        : bp.data;

    // Fallback data if empty to prevent widget crashes
    final data = barcodeData.isEmpty ? '12345678' : barcodeData;

    final barcodeSymbology = switch (bp.barcodeType) {
      BlueprintBarcodeType.code128 => Barcode.code128(),
      BlueprintBarcodeType.ean13 => Barcode.ean13(),
    };

    final barcodePxWidth = bp.width * AppDimensions.mmToPx;
    final barcodePxHeight = bp.height * AppDimensions.mmToPx;

    final barcodeWidget = BarcodeWidget(
      barcode: barcodeSymbology,
      data: data,
      errorBuilder: (context, error) => const Center(
        child: Text(
          'Invalid Barcode',
          style: TextStyle(
            fontSize: 10,
            color: Color(0xFFFF0000),
          ),
        ),
      ),
    );

    if (!bp.showLabel) {
      return SizedBox(
        width: barcodePxWidth,
        height: barcodePxHeight,
        child: barcodeWidget,
      );
    }

    // When showLabel is true, render barcode + text label proportionally.
    // The text font size scales with element height so it looks correct
    // when the element is resized in the editor.
    return SizedBox(
      width: barcodePxWidth,
      height: barcodePxHeight,
      child: Column(
        children: [
          Expanded(
            flex: 4,
            child: barcodeWidget,
          ),
          SizedBox(
            height: barcodePxHeight * 0.2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                data,
                style: TextStyle(
                  fontSize: barcodePxHeight * 0.12,
                  fontWeight: FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
