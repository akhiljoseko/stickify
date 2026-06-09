import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/entities/product.dart';

/// A single row in the "Frequent Products" data table.
///
/// **Stitch spec:** 40px row height, zebra-striped on even rows,
/// `label-mono` for SKU text, colour-coded station dot (green/amber/red),
/// and a "Quick Print" action button with hover state.
///
/// [isEvenRow] drives the zebra-stripe background (subtle tonal layer).
class FrequentProductRow extends StatefulWidget {
  const FrequentProductRow({
    required this.product,
    required this.isEvenRow,
    this.onQuickPrint,
    super.key,
  });

  /// The product entity to render.
  final Product product;

  /// When `true`, applies a light tonal zebra-stripe background.
  final bool isEvenRow;

  /// Called when the "Quick Print" button is tapped.
  final VoidCallback? onQuickPrint;

  @override
  State<FrequentProductRow> createState() => _FrequentProductRowState();
}

class _FrequentProductRowState extends State<FrequentProductRow> {
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

    final rowBg = _isHovered && isDesktopOrLarger
        ? colorScheme.surfaceContainerLow
        : widget.isEvenRow
            ? colorScheme.surfaceContainerLow.withValues(alpha: 0.4)
            : Colors.transparent;

    final stationDotColor = switch (widget.product.stationStatus) {
      StationStatus.online  => const Color(0xFF10B981),
      StationStatus.warning => const Color(0xFFF59E0B),
      StationStatus.offline => const Color(0xFFEF4444),
    };

    final totalPrintsFormatted = widget.product.totalPrints >= 1000
        ? '${(widget.product.totalPrints / 1000).toStringAsFixed(1)}k'
        : widget.product.totalPrints.toString();

    final lastPrinted = _formatDateTime(widget.product.lastPrintedAt);

    return MouseRegion(
      onEnter: isDesktopOrLarger ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktopOrLarger ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: rowBg,
        child: Row(
          children: [
            // ── Product Name & SKU ────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.product.name,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.product.sku,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            // ── Last Printed ──────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  lastPrinted,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            // ── Total Prints ──────────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    totalPrintsFormatted,
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            // ── Printer Station ───────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: stationDotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.product.assignedStation,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // ── Quick Print Action ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _QuickPrintButton(onPressed: widget.onQuickPrint),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:$m';
  }
}

/// Isolated "Quick Print" button extracted to keep [FrequentProductRow] clean.
class _QuickPrintButton extends StatefulWidget {
  const _QuickPrintButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  State<_QuickPrintButton> createState() => _QuickPrintButtonState();
}

class _QuickPrintButtonState extends State<_QuickPrintButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: _isHovered ? colorScheme.primaryContainer : colorScheme.primaryFixed,
          borderRadius: BorderRadius.circular(4),
        ),
        child: TextButton(
          onPressed: widget.onPressed,
          style: TextButton.styleFrom(
            foregroundColor: _isHovered
                ? colorScheme.onPrimaryContainer
                : colorScheme.onPrimaryFixedVariant,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('Quick Print'),
        ),
      ),
    );
  }
}
