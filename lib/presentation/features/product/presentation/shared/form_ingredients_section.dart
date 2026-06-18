import 'package:flutter/material.dart';
import 'package:stickify/domain/entities/ingredient.dart';

class FormIngredientsSection extends StatelessWidget {
  const FormIngredientsSection({
    required this.ingNameController,
    required this.ingPercentController,
    required this.ingredients,
    required this.onAddIngredient,
    required this.onRemoveIngredient,
    required this.isMobile,
    super.key,
  });

  final TextEditingController ingNameController;
  final TextEditingController ingPercentController;
  final List<Ingredient> ingredients;
  final VoidCallback onAddIngredient;
  final ValueChanged<int> onRemoveIngredient;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu_outlined, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Granular Ingredients', style: textTheme.titleSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              TextField(
                controller: ingNameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name', hintText: 'e.g. Organic Almonds'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ingPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Percent (%)', hintText: '12.5'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: onAddIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: ingNameController,
                      decoration: const InputDecoration(labelText: 'Ingredient Name', hintText: 'e.g. Organic Almonds'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: ingPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Percent (%)', hintText: '12.5'),
                    ),
                  ),
                  IconButton(
                    onPressed: onAddIngredient,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Ingredient',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ingredients.length,
                itemBuilder: (context, i) {
                  final ing = ingredients[i];
                  return ListTile(
                    title: Text(ing.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${ing.percentage}%', style: textTheme.bodyMedium),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onRemoveIngredient(i),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
