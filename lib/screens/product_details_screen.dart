import 'package:flutter/material.dart';

/// Product Details screen — displays detailed information about a single
/// product.
///
/// ## Route Parameter
///
/// The [id] is extracted from the URL path by GoRouter and passed here via
/// `ProductDetailsRoute.id`. For example, navigating to `/products/prod-001`
/// sets `id = 'prod-001'`.
///
/// In production, use [id] to fetch data from your product repository.
class ProductDetailsScreen extends StatelessWidget {
  const ProductDetailsScreen({required this.id, super.key});

  /// The product identifier from the URL path parameter `:id`.
  final String id;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back button — uses Navigator.pop() to stay within the Products
            // branch and return to ProductManagementScreen.
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Products'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 24),
            Text('Product Details', style: textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Viewing product ID: $id',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontFamily: 'JetBrains Mono',
              ),
            ),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2,
                            color: colorScheme.onPrimaryContainer,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Product $id', style: textTheme.titleSmall),
                            Text(
                              'Route parameter successfully resolved',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Placeholder detail rows
                    _DetailRow(label: 'ID', value: id),
                    const _DetailRow(label: 'Status', value: 'Active'),
                    const _DetailRow(label: 'Category', value: 'Labels'),
                    const _DetailRow(label: 'Created', value: '2024-01-15'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
