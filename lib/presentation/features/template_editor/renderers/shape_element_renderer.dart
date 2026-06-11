import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';

/// Renders a [ShapeElementBlueprint] on the designer canvas.
class ShapeElementRenderer implements LabelElementRenderer {
  /// Creates a [ShapeElementRenderer] instance.
  const ShapeElementRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
  }) {
    final bp = blueprint as ShapeElementBlueprint;

    return SizedBox(
      width: bp.width,
      height: bp.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bp.isFilled ? Color(bp.fillColorHex) : Colors.transparent,
          borderRadius: BorderRadius.circular(bp.cornerRadius),
          border: Border.all(
            color: Color(bp.strokeColorHex),
            width: bp.strokeWidth,
          ),
        ),
      ),
    );
  }
}
