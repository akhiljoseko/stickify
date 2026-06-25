import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';

/// Renders a pill badge indicating printer compatibility.
class CompatibilityIndicator extends StatelessWidget {
  /// Creates a [CompatibilityIndicator] for [status].
  const CompatibilityIndicator({required this.status, super.key});

  /// The compatibility status to render.
  final PrinterCompatibilityStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;

    final Color backgroundColor;
    final Color textColor;
    final String label;
    final IconData icon;

    switch (status) {
      case PrinterCompatibilityStatus.compatible:
        backgroundColor = const Color(0xFFE6F7F0); // Emerald tint
        textColor = const Color(0xFF007A53); // Deep emerald
        label = 'Compatible';
        icon = Icons.check_circle;
      case PrinterCompatibilityStatus.warning:
        backgroundColor = const Color(0xFFFFF3E0); // Amber tint
        textColor = const Color(0xFFE65100); // Deep amber/orange
        label = 'Warning';
        icon = Icons.warning_amber_rounded;
      case PrinterCompatibilityStatus.incompatible:
        backgroundColor = colorScheme.errorContainer; // Red container
        textColor = colorScheme.onErrorContainer; // Dark red text
        label = 'Incompatible';
        icon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: textColor,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: textStyle?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
