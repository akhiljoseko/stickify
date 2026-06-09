import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/entities/print_job.dart';

/// A card in the "Recently Printed Labels" horizontal carousel.
///
/// Displays a label preview mockup (matching the Stitch design's bordered
/// label art), the product name (in monospaced font), the SKU, and action
/// buttons (Repeat Print, More options).
///
/// **Stitch spec:** `w-80 bg-surface-container-lowest border rounded-xl p-4`
/// with a 3:2 aspect-ratio label preview area, verified badge overlay,
/// and Repeat Print primary button.
class RecentPrintCard extends StatefulWidget {
  const RecentPrintCard({
    required this.job,
    this.onRepeatPrint,
    super.key,
  });

  /// The print job to display.
  final PrintJob job;

  /// Called when the "Repeat Print" button is tapped.
  final VoidCallback? onRepeatPrint;

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
        width: 320,
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
            // ── Label Preview Area ────────────────────────────────────────
            _LabelPreviewArea(
              isVerified: widget.job.isVerified,
              status: widget.job.status,
            ),
            const SizedBox(height: 12),
            // ── Product Info ──────────────────────────────────────────────
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
              'SKU: ${widget.job.sku}',
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            // ── Action Buttons ────────────────────────────────────────────
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
                const SizedBox(width: 8),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      side: BorderSide(color: colorScheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
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

/// The label preview mockup area — a 3:2 aspect-ratio container with a
/// schematic label art and an optional "Verified" badge overlay.
class _LabelPreviewArea extends StatelessWidget {
  const _LabelPreviewArea({
    required this.isVerified,
    required this.status,
  });

  final bool isVerified;
  final PrintJobStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 3 / 2,
      child: Stack(
        children: [
          // Background tray
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: colorScheme.outlineVariant,
              ),
            ),
            child: Center(
              child: _LabelArtMockup(colorScheme: colorScheme),
            ),
          ),
          // Status badge overlay
          Positioned(
            top: 8,
            right: 8,
            child: _StatusBadge(isVerified: isVerified, status: status),
          ),
        ],
      ),
    );
  }
}

/// Renders a schematic label art mockup — styled rectangles representing
/// a real label's layout zones (title, barcode, content lines).
class _LabelArtMockup extends StatelessWidget {
  const _LabelArtMockup({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: colorScheme.primary, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: title strip + logo block
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 64,
                height: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.10),
              ),
              Container(
                width: 16,
                height: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.18),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Content lines
          Container(
            width: double.infinity,
            height: 5,
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          const SizedBox(height: 3),
          Container(
            width: 80,
            height: 5,
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
          const Spacer(),
          // Barcode strip
          Container(
            width: double.infinity,
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge shown in the top-right corner of the label preview.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isVerified, required this.status});

  final bool isVerified;
  final PrintJobStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      PrintJobStatus.completed when isVerified => (
          const Color(0xFF10B981),
          Icons.check,
          'Verified',
        ),
      PrintJobStatus.completed => (
          const Color(0xFF6B7280),
          Icons.check_outlined,
          'Done',
        ),
      PrintJobStatus.printing => (
          const Color(0xFF3B82F6),
          Icons.sync,
          'Printing',
        ),
      PrintJobStatus.queued => (
          const Color(0xFFF59E0B),
          Icons.schedule,
          'Queued',
        ),
      PrintJobStatus.error => (
          const Color(0xFFEF4444),
          Icons.error_outline,
          'Error',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
