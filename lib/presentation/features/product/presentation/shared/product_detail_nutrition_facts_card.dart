import 'package:flutter/material.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';

class ProductDetailNutritionFactsCard extends StatelessWidget {
  const ProductDetailNutritionFactsCard({
    required this.nutritionFacts,
    this.subtitle,
    super.key,
  });

  final NutritionFacts? nutritionFacts;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nutrition Facts', style: textTheme.titleSmall),
                if (subtitle != null)
                  Text(subtitle!, style: textTheme.bodySmall?.copyWith(color: colorScheme.outline, fontStyle: FontStyle.italic)),
              ],
            ),
            const Divider(),
            if (nutritionFacts == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No nutrition facts defined.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
              )
            else
              Table(
                border: TableBorder.all(color: colorScheme.outlineVariant, width: 0.5, borderRadius: BorderRadius.circular(4)),
                columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(2)},
                children: [
                  _row(textTheme, 'Calories', '${nutritionFacts!.calories.toStringAsFixed(0)} kcal'),
                  _row(textTheme, 'Protein', '${nutritionFacts!.protein.toStringAsFixed(1)} g'),
                  _row(textTheme, 'Total Fat', '${nutritionFacts!.totalFat.toStringAsFixed(1)} g'),
                  _row(textTheme, 'Saturated Fat', '${nutritionFacts!.saturatedFat.toStringAsFixed(1)} g'),
                  _row(textTheme, 'Total Carbohydrates', '${nutritionFacts!.totalCarbs.toStringAsFixed(1)} g'),
                  _row(textTheme, 'Dietary Fiber', '${nutritionFacts!.fiber.toStringAsFixed(1)} g'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  TableRow _row(TextTheme textTheme, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(value, style: textTheme.bodyMedium),
        ),
      ],
    );
  }
}
