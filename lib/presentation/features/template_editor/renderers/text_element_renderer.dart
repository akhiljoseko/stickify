import 'package:flutter/widgets.dart';
import 'package:stickify/core/utils/token_registry.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';

/// Renders a [TextElementBlueprint] on the designer canvas.
class TextElementRenderer implements LabelElementRenderer {
  /// Creates a [TextElementRenderer] instance.
  const TextElementRenderer();

  /// Utility to resolve dynamic metadata evaluation tokens (e.g. `{{product.name}}`, `{{variant.sku}}`) inside a [template] string.
  static String resolveToken(String template, Product? product, [ProductVariant? variant, DateTime? manufacturingDate]) {
    var result = template;

    for (final tokenDef in tokenRegistry) {
      if (result.contains(tokenDef.token)) {
        final value = tokenDef.getValue(product, variant, manufacturingDate);
        result = result.replaceAll(tokenDef.token, value);
      }
    }

    return result;
  }

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
    DateTime? manufacturingDate,
  }) {
    final bp = blueprint as TextElementBlueprint;
    final text = bp.isDynamic ? resolveToken(bp.content, product, variant, manufacturingDate) : bp.content;

    final fontWeight = FontWeight.values.firstWhere(
      (w) => w.value == bp.fontWeightValue,
      orElse: () => FontWeight.normal,
    );

    final textAlign = switch (bp.textAlign) {
      BlueprintTextAlign.left => TextAlign.left,
      BlueprintTextAlign.center => TextAlign.center,
      BlueprintTextAlign.right => TextAlign.right,
      BlueprintTextAlign.justify => TextAlign.justify,
    };

    return SizedBox(
      width: bp.width * 4.0,
      height: bp.height * 4.0,
      child: Text(
        text,
        textAlign: textAlign,
        maxLines: bp.maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: bp.fontSize * 4.0,
          fontWeight: fontWeight,
          color: Color(bp.colorHex),
          letterSpacing: bp.letterSpacing * 4.0,
        ),
      ),
    );
  }
}
