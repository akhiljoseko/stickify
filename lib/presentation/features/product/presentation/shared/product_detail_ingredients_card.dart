import 'package:flutter/material.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/domain/entities/ingredient.dart';

class ProductDetailIngredientsCard extends StatelessWidget {
  const ProductDetailIngredientsCard({
    required this.ingredients,
    super.key,
  });

  final List<Ingredient> ingredients;

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
            Text('Ingredients', style: textTheme.titleSmall),
            const Divider(),
            if (ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No ingredients listed.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients
                    .map((ing) => Chip(
                          label: Text('${ing.name} (${ing.percentage}%)'),
                          backgroundColor: colorScheme.containerLow,
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ))
                    .toList(),
              ),
            if (ingredients.any((i) =>
                i.name.toLowerCase().contains('almond') ||
                i.name.toLowerCase().contains('nut'))) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALLERGEN WARNING',
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contains Nuts (Almonds). Processed in a facility that also handles soy, dairy, and wheat.',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
