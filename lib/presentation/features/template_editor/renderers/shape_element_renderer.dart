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
    DateTime? manufacturingDate,
  }) {
    final bp = blueprint as ShapeElementBlueprint;

    return SizedBox(
      width: bp.width * 4.0,
      height: bp.height * 4.0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bp.isFilled ? Color(bp.fillColorHex) : Colors.transparent,
          borderRadius: BorderRadius.circular(bp.cornerRadius * 4.0),
          border: Border.all(
            color: Color(bp.strokeColorHex),
            width: bp.strokeWidth * 4.0,
          ),
        ),
      ),
    );
  }
}
