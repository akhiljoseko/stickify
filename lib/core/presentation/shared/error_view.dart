import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/core.dart';

/// A visually rich full-screen error state view.
///
/// Responsive: on desktop the content is rendered inside a centered [Card]
/// (max ~480px) with more whitespace; on mobile/tablet it keeps the original
/// compact centered column layout.
class ErrorView extends StatelessWidget {
  /// Creates an [ErrorView].
  const ErrorView({
    required this.message,
    this.onRetry,
    this.onBack,
    super.key,
  });

  /// The error message body.
  final String message;

  /// Optional callback for a "Try Again" action (shown when data can be reloaded).
  final VoidCallback? onRetry;

  /// Optional callback for a "Go Back" action.  When omitted no back button is rendered.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.breakpoint.name == AppBreakpoints.desktop ||
        bp.breakpoint.name == AppBreakpoints.fourK;

    final content = _buildContent(colorScheme, textTheme);

    if (isDesktop) {
      return Center(
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLowest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          margin: const EdgeInsets.all(32),
          child: SizedBox(
            width: 480,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 40),
              child: content,
            ),
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: content,
      ),
    );
  }

  Widget _buildContent(ColorScheme colorScheme, TextTheme textTheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.error_outline_rounded,
            color: colorScheme.error,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'An error occurred',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (onBack != null)
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Go Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.onSurfaceVariant,
                  side: BorderSide(color: colorScheme.outlineVariant),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            if (onRetry != null)
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Try Again'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
