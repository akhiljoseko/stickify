import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/core.dart';

/// A visually rich, UI-blocking error overlay for process-critical failures.
///
/// Displays a dark scrim with an animated centered card containing the error
/// icon, title, message, and action buttons.  The user must tap one of the
/// action buttons to dismiss the overlay and resume interaction.
///
/// Responsive: desktop gets a wider card; mobile/tablet keeps a compact card.
class BlockingErrorDialog extends StatefulWidget {
  /// Creates a [BlockingErrorDialog].
  const BlockingErrorDialog({
    required this.message,
    this.title,
    this.onRetry,
    this.onClose,
    super.key,
  });

  /// The error body text.
  final String message;

  /// Optional heading (defaults to "Something went wrong").
  final String? title;

  /// Optional callback for a "Try Again" action.
  final VoidCallback? onRetry;

  /// Optional callback when the user closes the dialog without retrying.
  final VoidCallback? onClose;

  /// Show the dialog as a push-based overlay route.
  ///
  /// Returns `true` if the user tapped "Try Again", `false` otherwise.
  static Future<bool> show(BuildContext context, {
    required String message,
    String? title,
    VoidCallback? onRetry,
    VoidCallback? onClose,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => BlockingErrorDialog(
        message: message,
        title: title,
        onRetry: onRetry,
        onClose: onClose,
      ),
    ).then((result) => result ?? false);
  }

  @override
  State<BlockingErrorDialog> createState() => _BlockingErrorDialogState();
}

class _BlockingErrorDialogState extends State<BlockingErrorDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.breakpoint.name == AppBreakpoints.desktop ||
        bp.breakpoint.name == AppBreakpoints.fourK;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 480 : 360,
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Error icon
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline_rounded,
                        color: colorScheme.error,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Title
                    Text(
                      widget.title ?? 'Something went wrong',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Message
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.onClose != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: OutlinedButton(
                              onPressed: () {
                                widget.onClose?.call();
                                Navigator.of(context).pop(false);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.onSurfaceVariant,
                                side: BorderSide(color: colorScheme.outlineVariant),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                        if (widget.onRetry != null)
                          FilledButton.icon(
                            onPressed: () {
                              widget.onRetry?.call();
                              Navigator.of(context).pop(true);
                            },
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
                    // Close-only fallback when neither callback provided
                    if (widget.onRetry == null && widget.onClose == null)
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Dismiss'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
