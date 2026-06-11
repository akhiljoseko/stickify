import 'package:flutter/material.dart';
import 'package:stickify/app/routing/router.dart';

/// Reusable explanatory screen shown on mobile viewports for restricted template editor wizard steps.
class MobileRestrictedView extends StatelessWidget {
  /// Creates a [MobileRestrictedView] instance.
  const MobileRestrictedView({
    required this.title,
    super.key,
  });

  /// The title to show on the AppBar.
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => const TemplateManagementRoute().go(context),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.desktop_mac_outlined,
                  size: 64,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Desktop Feature Only',
                style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Label design, sheet layout configuration, and sticker editing are restricted to desktop viewports to ensure high precision alignment. Please open Stickify on a desktop computer to design templates.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => const TemplateManagementRoute().go(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Templates'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
