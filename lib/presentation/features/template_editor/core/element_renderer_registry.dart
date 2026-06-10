import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/barcode_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/image_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/qr_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/shape_element_renderer.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

class ElementRendererRegistry {
  static const _renderers = <Type, LabelElementRenderer>{
    TextElementBlueprint: TextElementRenderer(),
    BarcodeElementBlueprint: BarcodeElementRenderer(),
    QrElementBlueprint: QrElementRenderer(),
    ImageElementBlueprint: ImageElementRenderer(),
    ShapeElementBlueprint: ShapeElementRenderer(),
  };

  static LabelElementRenderer forBlueprint(ElementBlueprint b) {
    final renderer = _renderers[b.runtimeType];
    if (renderer == null) {
      return const _FallbackRenderer();
    }
    return renderer;
  }
}

class _FallbackRenderer implements LabelElementRenderer {
  const _FallbackRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
  }) {
    return SizedBox(
      width: blueprint.width,
      height: blueprint.height,
      child: Container(
        color: const Color(0xFFFFCCCC),
        alignment: Alignment.center,
        child: const Text(
          'Unknown element type',
          style: TextStyle(color: Color(0xFFFF0000), fontSize: 8),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
