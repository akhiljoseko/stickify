import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/print_job.dart';

class RecentPrintRow extends StatefulWidget {
  const RecentPrintRow({
    required this.job,
    this.onRepeatPrint,
    super.key,
  });

  final PrintJob job;
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

    final bp = ResponsiveBreakpoints.of(context);
    final enableHoverEffects = !bp.isMobile && !bp.isTablet;

    final rowBgColor = _isHovered && enableHoverEffects
        ? colorScheme.containerLow
        : colorScheme.containerLowest;

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
                image: widget.job.imageUrl != null && widget.job.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: resolveImageProvider(widget.job.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.job.imageUrl == null || widget.job.imageUrl!.isEmpty
                  ? Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            _Cell(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.job.variantName,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.job.variantSku,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
            SizedBox(
              width: 140,
              child: Center(child: _RepeatPrintButton(onPressed: widget.onRepeatPrint)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        label: const Text('Repeat'),
        style: ElevatedButton.styleFrom(
          shape: const StadiumBorder(),
        ),
      );
    }

    return IconButton(
      onPressed: onPressed,
      icon: Icon(Icons.print_outlined, size: 20, color: colorScheme.primary),
      tooltip: 'Repeat Print',
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
