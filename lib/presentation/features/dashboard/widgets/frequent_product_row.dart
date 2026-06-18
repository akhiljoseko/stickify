import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/entities/variant_print_stats.dart';

class FrequentVariantRow extends StatefulWidget {
  const FrequentVariantRow({
    required this.stats,
    required this.isEvenRow,
    this.onQuickPrint,
    super.key,
  });

  final VariantPrintStats stats;
  final bool isEvenRow;
  final VoidCallback? onQuickPrint;

  @override
  State<FrequentVariantRow> createState() => _FrequentVariantRowState();
}

class _FrequentVariantRowState extends State<FrequentVariantRow> {
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
        ? colorScheme.surfaceContainerHigh
        : widget.isEvenRow
            ? colorScheme.surfaceContainerLow.withValues(alpha: 0.3)
            : Colors.transparent;

    final totalPrintsFormatted = widget.stats.totalPrints >= 1000
        ? '${(widget.stats.totalPrints / 1000).toStringAsFixed(1)}k'
        : widget.stats.totalPrints.toString();

    final lastPrinted = _formatDateTime(widget.stats.lastPrintedAt);

    return InkWell(
      onHover: isDesktopOrLarger ? (value) => setState(() => _isHovered = value) : null,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: rowBg,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.stats.variantName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.stats.productName,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      widget.stats.variantSku,
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontSize: 10,
                        fontFamily: 'JetBrains Mono',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
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

class _QuickPrintButton extends StatelessWidget {
  const _QuickPrintButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isDesktopOrLarger = AdaptiveValue<bool>(
      context,
      defaultValue: false,
      desktop: true,
      fourK: true,
    ).value;

    if (isDesktopOrLarger) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.print_outlined, size: 16),
        label: const Text('Quick Print'),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.print_outlined, size: 20),
      tooltip: 'Quick Print',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
