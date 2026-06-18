import 'package:flutter/material.dart';

class ProductDetailStorageCard extends StatelessWidget {
  const ProductDetailStorageCard({
    required this.storageConditions,
    super.key,
  });

  final String? storageConditions;

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
              children: [
                Icon(Icons.thermostat_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Storage Conditions', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              storageConditions ?? 'No specific storage requirements.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
