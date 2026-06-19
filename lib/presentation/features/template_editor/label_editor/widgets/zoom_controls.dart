import 'package:flutter/material.dart';

/// Floating overlay widget showing controls to adjust the designer canvas zoom factor.
class ZoomControls extends StatelessWidget {
  /// Creates a [ZoomControls] instance.
  const ZoomControls({
    required this.zoomLevel,
    required this.onZoomChanged,
    this.onZoomToFit,
    super.key,
  });

  /// The active zoom scaling level.
  final double zoomLevel;

  /// Callback when the user changes the zoom level.
  final ValueChanged<double> onZoomChanged;

  /// Callback to fit the sticker board into the available viewport.
  final VoidCallback? onZoomToFit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          if (onZoomToFit != null)
            IconButton(
              icon: const Icon(Icons.fit_screen_outlined, size: 18),
              tooltip: 'Zoom to fit',
              onPressed: onZoomToFit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 36),
            ),
          if (onZoomToFit != null)
            Container(
              width: 1,
              height: 20,
              color: colorScheme.outlineVariant,
            ),
          SizedBox(
            width: 80,
            child: Slider(
              value: zoomLevel,
              min: 0.5,
              max: 2,
              divisions: 30,
              onChanged: onZoomChanged,
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '${(zoomLevel * 100).toInt()}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
