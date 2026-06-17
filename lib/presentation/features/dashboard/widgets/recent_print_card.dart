import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/entities/print_job.dart';

/// A card in the "Recently Printed Labels" horizontal carousel.
///
/// Displays the product name, SKU, and a Repeat Print action button.
class RecentPrintCard extends StatefulWidget {
  const RecentPrintCard({
    required this.job,
    this.onRepeatPrint,
    this.width,
    super.key,
  });

  /// The print job to display.
  final PrintJob job;

  /// Called when the "Repeat Print" button is tapped.
  final VoidCallback? onRepeatPrint;

  /// Optional card width. Defaults to 320.
  final double? width;

  @override
  State<RecentPrintCard> createState() => _RecentPrintCardState();
}

class _RecentPrintCardState extends State<RecentPrintCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isDesktopOrLarger = AdaptiveValue<bool>(
      context,
      defaultValue: false,
      desktop: true,
      fourK: true,
    ).value;

    return MouseRegion(
      onEnter: isDesktopOrLarger ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktopOrLarger ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: widget.width ?? 320,
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
                    color: colorScheme.primary.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.job.productName,
              style: textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              'SKU: ${widget.job.variantSku}',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onRepeatPrint,
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text(
                      'Repeat Print',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
