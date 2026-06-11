import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';

/// Renders a [TextElementBlueprint] on the designer canvas.
class TextElementRenderer implements LabelElementRenderer {
  /// Creates a [TextElementRenderer] instance.
  const TextElementRenderer();

  /// Utility to resolve dynamic metadata evaluation tokens (e.g. `{{product.name}}`, `{{variant.sku}}`) inside a [template] string.
  static String resolveToken(String template, Product? product, [ProductVariant? variant]) {
    var result = template;
    if (product != null) {
      result = result.replaceAllMapped(RegExp(r'\{\{product\.([a-zA-Z0-9_]+)\}\}'), (match) {
        final field = match.group(1);
        switch (field) {
          case 'id':
            return product.id;
          case 'name':
            return product.name;
          case 'sku':
            return variant != null ? variant.sku : product.sku;
          case 'category':
            return product.category ?? '';
          case 'totalPrints':
            return product.totalPrints.toString();
          case 'lastPrintedAt':
            return product.lastPrintedAt.toIso8601String();
          case 'assignedStation':
            return product.assignedStation;
          case 'shelfLifeDays':
            return product.shelfLifeDays?.toString() ?? '';
          case 'storageConditions':
            return product.storageConditions ?? '';
          case 'imageUrl':
            return product.imageUrl ?? '';
          default:
            return match.group(0) ?? '';
        }
      });
    }
    if (variant != null) {
      result = result.replaceAllMapped(RegExp(r'\{\{variant\.([a-zA-Z0-9_]+)\}\}'), (match) {
        final field = match.group(1);
        switch (field) {
          case 'name':
            return variant.name;
          case 'sku':
            return variant.sku;
          case 'quantity':
            return variant.quantity % 1 == 0
                ? variant.quantity.toInt().toString()
                : variant.quantity.toString();
          case 'unit':
            return variant.unit;
          case 'wholesale':
            return variant.wholesale.toStringAsFixed(2);
          case 'mrp':
            return variant.mrp.toStringAsFixed(2);
          default:
            return match.group(0) ?? '';
        }
      });
    }
    return result;
  }

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
  }) {
    final bp = blueprint as TextElementBlueprint;
    final text = bp.isDynamic ? resolveToken(bp.content, product, variant) : bp.content;

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
      width: bp.width,
      height: bp.height,
      child: Text(
        text,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: bp.fontSize,
          fontWeight: fontWeight,
          color: Color(bp.colorHex),
          letterSpacing: bp.letterSpacing,
        ),
      ),
    );
  }
}
