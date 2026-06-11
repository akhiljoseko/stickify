import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';

/// A custom painter that draws a closed polygon outline defined by a set of [StickerPoint]s.
///
/// Used in the sticker template designer view to outline the printable area boundary.
class PolygonPainter extends CustomPainter {
  /// Creates a [PolygonPainter] instance.
  const PolygonPainter({
    required this.points,
    required this.scale,
    required this.color,
    this.strokeWidth = 1.5,
    this.showMarkers = false,
    this.markerColor = Colors.blue,
  });

  /// The list of [StickerPoint] vertices.
  final List<StickerPoint> points;

  /// Layout scale factor from millimeters (mm) to screen logical pixels.
  final double scale;

  /// Outline border stroke color.
  final Color color;

  /// Outline border stroke width.
  final double strokeWidth;

  /// True if draggable numeric vertex markers should be painted.
  final bool showMarkers;

  /// Marker circle color.
  final Color markerColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final path = Path()
      ..moveTo(points[0].x * scale, points[0].y * scale);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].x * scale, points[i].y * scale);
    }
    if (points.length > 2) {
      path.close();
    }

    canvas.drawPath(path, paint);

    if (showMarkers) {
      final markerPaint = Paint()
        ..color = markerColor
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      for (var i = 0; i < points.length; i++) {
        final pt = points[i];
        final px = pt.x * scale;
        final py = pt.y * scale;

        // Draw badge circle
        canvas
          ..drawCircle(Offset(px, py), 8, markerPaint)
          ..drawCircle(Offset(px, py), 8, borderPaint);

        // Draw index centered inside the circle
        final textPainter = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        textPainter.paint(
          canvas,
          Offset(px - textPainter.width / 2, py - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant PolygonPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.scale != scale ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.showMarkers != showMarkers ||
        oldDelegate.markerColor != markerColor;
  }
}
