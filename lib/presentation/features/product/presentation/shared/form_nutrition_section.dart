import 'package:flutter/material.dart';

class FormNutritionSection extends StatelessWidget {
  const FormNutritionSection({
    required this.includeNutrition,
    required this.onToggleNutrition,
    required this.caloriesController,
    required this.proteinController,
    required this.fatController,
    required this.saturatedFatController,
    required this.carbsController,
    required this.fiberController,
    super.key,
  });

  final bool includeNutrition;
  final ValueChanged<bool> onToggleNutrition;
  final TextEditingController caloriesController;
  final TextEditingController proteinController;
  final TextEditingController fatController;
  final TextEditingController saturatedFatController;
  final TextEditingController carbsController;
  final TextEditingController fiberController;

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
                    Icon(Icons.receipt_long_outlined, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Nutrition Facts', style: textTheme.titleSmall),
                  ],
                ),
                Switch(
                  value: includeNutrition,
                  onChanged: onToggleNutrition,
                ),
              ],
            ),
            if (includeNutrition) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: proteinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Protein (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: fatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Fat (g)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: saturatedFatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Saturated Fat (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: carbsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Carbs (g)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: fiberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Fiber (g)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
