import 'package:flutter/material.dart';
import 'package:stickify/core/constants/dimensions.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';

/// Renders a [NutritionTableElementBlueprint] on the template editor canvas.
class NutritionTableElementRenderer implements LabelElementRenderer {
  /// Creates a [NutritionTableElementRenderer] instance.
  const NutritionTableElementRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
    DateTime? manufacturingDate,
  }) {
    // Cast to the expected blueprint subclass
    final bp = blueprint as NutritionTableElementBlueprint;
    final textColor = Color(bp.colorHex);

    // Resolve nutrition facts from product or use default mock values
    final nutrition = product?.nutritionFacts;
    final calories = nutrition?.calories ?? 250.0;
    final protein = nutrition?.protein ?? 10.0;
    final totalFat = nutrition?.totalFat ?? 8.0;
    final saturatedFat = nutrition?.saturatedFat ?? 2.5;
    final totalCarbs = nutrition?.totalCarbs ?? 30.0;
    final fiber = nutrition?.fiber ?? 3.0;

    return SizedBox(
      width: bp.width * AppDimensions.mmToPx,
      height: bp.height * AppDimensions.mmToPx,
      child: FittedBox(
        fit: BoxFit.fill,
        child: Container(
          width: 240,
          height: 320,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: textColor, width: 4),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Nutrition Facts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              Divider(color: textColor, thickness: 4, height: 16),
              _buildRow('Energy/Calories', '${calories.toStringAsFixed(0)} kcal', textColor, isBold: true),
              Divider(color: textColor, thickness: 2, height: 10),
              _buildRow('Total Fat', '${totalFat.toStringAsFixed(1)} g', textColor),
              Divider(color: textColor, thickness: 1, height: 10),
              _buildRow('  Saturated Fat', '${saturatedFat.toStringAsFixed(1)} g', textColor, isSub: true),
              Divider(color: textColor, thickness: 2, height: 10),
              _buildRow('Total Carbohydrate', '${totalCarbs.toStringAsFixed(1)} g', textColor),
              Divider(color: textColor, thickness: 1, height: 10),
              _buildRow('  Dietary Fiber', '${fiber.toStringAsFixed(1)} g', textColor, isSub: true),
              Divider(color: textColor, thickness: 2, height: 10),
              _buildRow('Protein', '${protein.toStringAsFixed(1)} g', textColor, isBold: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value,
    Color color, {
    bool isBold = false,
    bool isSub = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSub ? 15 : 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color,
                height: 1.1,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: color,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}
