import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';

/// Renders a status badge indicating the OS connectivity state of a printer.
class PrinterStatusBadge extends StatelessWidget {
  /// Creates a [PrinterStatusBadge] for [status].
  const PrinterStatusBadge({required this.status, super.key});

  /// The discovered printer status to render.
  final DiscoveredPrinterStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;

    final Color dotColor;
    final String label;

    switch (status) {
      case DiscoveredPrinterStatus.online:
        dotColor = const Color(0xFF10B981); // Emerald online
        label = 'Online';
      case DiscoveredPrinterStatus.offline:
        dotColor = colorScheme.outline; // Grey offline
        label = 'Offline';
      case DiscoveredPrinterStatus.unavailable:
        dotColor = colorScheme.error; // Red unavailable
        label = 'Unavailable';
      case DiscoveredPrinterStatus.unknown:
        dotColor = Colors.orange; // Orange unknown
        label = 'Unknown';
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textStyle?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
