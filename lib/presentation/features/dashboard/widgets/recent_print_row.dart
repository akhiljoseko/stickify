import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/entities/print_job.dart';

class RecentPrintRow extends StatefulWidget {
  const RecentPrintRow({
    required this.job,
    required this.isEvenRow,
    this.onRepeatPrint,
    super.key,
  });

  final PrintJob job;
  final bool isEvenRow;
  final VoidCallback? onRepeatPrint;

  @override
  State<RecentPrintRow> createState() => _RecentPrintRowState();
}

class _RecentPrintRowState extends State<RecentPrintRow> {
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

    return MouseRegion(
      onEnter: isDesktopOrLarger ? (_) => setState(() => _isHovered = true) : null,
      onExit: isDesktopOrLarger ? (_) => setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: rowBg,
        child: Row(
          children: [
            _Cell(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.job.variantName,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.job.variantSku,
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
            _Cell(
              flex: 2,
              child: Text(
                widget.job.templateName,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _Cell(
              flex: 1,
              child: Text(
                '${widget.job.labelCount}',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            _Cell(
              flex: 2,
              child: Text(
                _formatRelativeDate(widget.job.printedAt),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _RepeatPrintButton(onPressed: widget.onRepeatPrint),
            ),
          ],
        ),
      ),
    );
  }

  String _formatRelativeDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays <= 3) return '${diff.inDays}d ago';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    if (dt.year == now.year) {
      return '${months[dt.month - 1]} ${dt.day}';
    }
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.flex, required this.child});

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: child,
      ),
    );
  }
}

class _RepeatPrintButton extends StatelessWidget {
  const _RepeatPrintButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.print_outlined, size: 20, color: colorScheme.primary),
      tooltip: 'Repeat Print',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
