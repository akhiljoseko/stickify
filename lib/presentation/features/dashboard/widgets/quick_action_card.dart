import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';

/// A static, hover-reactive quick-action card for the Dashboard.
///
/// Displays an icon, a title, and a subtitle. Tapping fires [onTap].
///
/// **Stitch spec:**
/// - `bg-surface-container-lowest border border-outline-variant rounded-xl`
/// - On hover: `border-primary-container shadow-md` with icon background
///   transitioning to primary blue.
/// - Icon container: 48×48, `rounded-lg`, tinted background.
///
/// These are purely static navigation shortcuts — no Cubit or entity needed.
class QuickActionCard extends StatefulWidget {
  const QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
    super.key,
  });

  /// The icon to display in the card's icon container.
  final IconData icon;

  /// Short action label (e.g., `'Add New Product'`).
  final String title;

  /// Descriptive subtitle (e.g., `'Register SKU & Metadata'`).
  final String subtitle;

  /// Callback fired when the card is tapped.
  final VoidCallback onTap;

  /// When `true`, the icon container uses the primary brand color background
  /// (used for the first/primary action as per the Stitch design).
  final bool isPrimary;

  @override
  State<QuickActionCard> createState() => _QuickActionCardState();
}

class _QuickActionCardState extends State<QuickActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Desktop hover guard — guard with AdaptiveValue so touch platforms
    // never receive phantom hover states.
    final isDesktopOrLarger = AdaptiveValue<bool>(
      context,
      defaultValue: false,
      desktop: true,
      fourK: true,
    ).value;

    final iconBg = _isHovered && isDesktopOrLarger
        ? colorScheme.primary
        : widget.isPrimary
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHigh;

    final iconColor = _isHovered && isDesktopOrLarger
        ? colorScheme.onPrimary
        : widget.isPrimary
            ? colorScheme.onPrimaryContainer
            : colorScheme.primary;

    return MouseRegion(
      onEnter: isDesktopOrLarger ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktopOrLarger ? (_) => setState(() => _isHovered = false) : null,
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isHovered && isDesktopOrLarger
                  ? colorScheme.primaryContainer
                  : colorScheme.outlineVariant,
            ),
            boxShadow: _isHovered && isDesktopOrLarger
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(widget.icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 12),
              // Title
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 150),
                style: (textTheme.titleSmall ?? const TextStyle()).copyWith(
                  color: _isHovered && isDesktopOrLarger
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
                child: Text(
                  widget.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              // Subtitle
              Text(
                widget.subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
