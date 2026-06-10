import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';

class TextElementRenderer implements LabelElementRenderer {
  const TextElementRenderer();

  static String resolveToken(String template, Product? product) {
    if (product == null) return template;
    return template.replaceAllMapped(RegExp(r'\{\{product\.([a-zA-Z0-9_]+)\}\}'), (match) {
      final field = match.group(1);
      switch (field) {
        case 'id':
          return product.id;
        case 'name':
          return product.name;
        case 'sku':
          return product.sku;
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

  @override
  Widget render(BuildContext context, ElementBlueprint blueprint, {Product? product}) {
    final bp = blueprint as TextElementBlueprint;
    final text = bp.isDynamic ? resolveToken(bp.content, product) : bp.content;

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
