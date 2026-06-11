import 'dart:io';
import 'package:flutter/material.dart';

/// Resolves a dynamic [ImageProvider] from the given [path].
ImageProvider getImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  } else {
    return FileImage(File(path));
  }
}

/// A fallback view shown when no products match filters or search queries.
class EmptyCatalogState extends StatelessWidget {
  /// Creates an [EmptyCatalogState] instance.
  const EmptyCatalogState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query or filter category.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
