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
          ],
        ),
      ),
    );
  }
}
