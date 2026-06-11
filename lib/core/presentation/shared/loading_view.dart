import 'package:flutter/material.dart';

/// A premium, beautiful loading view with subtle micro-animations/fade effects.
class LoadingView extends StatelessWidget {
  /// Creates a [LoadingView].
  const LoadingView({
    this.message = 'Loading dashboard details...',
    super.key,
  });

  /// Optional message to display beneath the indicator.
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
