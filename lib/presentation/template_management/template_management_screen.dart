import 'package:flutter/material.dart';

/// Template Management screen placeholder.
///
/// Replace the placeholder content with real template listing, filtering,
/// and creation UI as the product evolves.
class TemplateManagementScreen extends StatelessWidget {
  const TemplateManagementScreen({super.key});

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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Template Management',
                    style: textTheme.displayLarge,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('New Template'),
                  onPressed: () {
                    // TODO(you): Navigate to template creation.
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Design and manage your label templates.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.layers_outlined,
                      size: 64,
                      color: colorScheme.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No templates yet',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first template to get started.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.outlineVariant,
                      ),
                    ),
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
