import 'package:flutter/material.dart';

class ZoomControls extends StatelessWidget {
  const ZoomControls({
    required this.zoomLevel,
    required this.onZoomChanged,
    super.key,
  });

  final double zoomLevel;
  final ValueChanged<double> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.zoom_out, size: 18),
            onPressed: () => onZoomChanged(zoomLevel - 0.1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outlineVariant,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${(zoomLevel * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: colorScheme.outlineVariant,
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, size: 18),
            onPressed: () => onZoomChanged(zoomLevel + 0.1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
