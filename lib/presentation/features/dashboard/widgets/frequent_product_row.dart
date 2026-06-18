import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/variant_print_stats.dart';

class FrequentVariantRow extends StatefulWidget {
  const FrequentVariantRow({
    required this.stats,
    this.onQuickPrint,
    super.key,
  });

  final VariantPrintStats stats;
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

    final bp = ResponsiveBreakpoints.of(context);
    final enableHoverEffects = !bp.isMobile && !bp.isTablet;

    final rowBgColor = _isHovered && enableHoverEffects
        ? colorScheme.containerLow
        : colorScheme.containerLowest;

    final totalPrintsFormatted = widget.stats.totalPrints >= 1000
        ? '${(widget.stats.totalPrints / 1000).toStringAsFixed(1)}k'
        : widget.stats.totalPrints.toString();

    final lastPrinted = _formatDateTime(widget.stats.lastPrintedAt);

    return MouseRegion(
      onEnter: (_) {
        if (enableHoverEffects) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (enableHoverEffects) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(
          _isHovered && enableHoverEffects ? 4 : 0, 0, 0,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: rowBgColor,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.container,
                image: widget.stats.imageUrl != null && widget.stats.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: resolveImageProvider(widget.stats.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.stats.imageUrl == null || widget.stats.imageUrl!.isEmpty
                  ? Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.stats.variantName,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.stats.productName,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
            SizedBox(
              width: 160,
              child: Center(child: _QuickPrintButton(onPressed: widget.onQuickPrint)),
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
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.print_outlined, size: 18),
        label: const Text('Quick Print'),
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
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
