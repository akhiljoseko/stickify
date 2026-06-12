import 'dart:math' as math;
import 'package:stickify/domain/entities/sticker_config.dart';

/// Utilities for 2D polygon calculations, point containment, and shape geometry.
class PolygonUtils {
  PolygonUtils._();

  /// Checks if a point [p] lies inside a polygon defined by [vertices] using the ray-casting algorithm.
  static bool isPointInPolygon(StickerPoint p, List<StickerPoint> vertices) {
    if (vertices.length < 3) return false;
    var inside = false;
    var j = vertices.length - 1;
    for (var i = 0; i < vertices.length; i++) {
      final vi = vertices[i];
      final vj = vertices[j];

      final intersect = ((vi.y > p.y) != (vj.y > p.y)) &&
          (p.x < (vj.x - vi.x) * (p.y - vi.y) / (vj.y - vi.y) + vi.x);
      if (intersect) {
        inside = !inside;
      }
      j = i;
    }
    return inside;
  }

  /// Calculates the 4 corner points of a bounding box after applying rotation (in degrees) around its center.
  static List<StickerPoint> getRotatedCorners({
    required double x,
    required double y,
    required double width,
    required double height,
    required double rotationDegrees,
  }) {
    final cx = x + width / 2.0;
    final cy = y + height / 2.0;

    final corners = [
      StickerPoint(x, y), // Top-left
      StickerPoint(x + width, y), // Top-right
      StickerPoint(x + width, y + height), // Bottom-right
      StickerPoint(x, y + height), // Bottom-left
    ];

    if (rotationDegrees == 0.0) {
      return corners;
    }

    final rad = rotationDegrees * (math.pi / 180.0);
    final cosRad = math.cos(rad);
    final sinRad = math.sin(rad);

    return corners.map((pt) {
      final dx = pt.x - cx;
      final dy = pt.y - cy;
      final rx = cx + dx * cosRad - dy * sinRad;
      final ry = cy + dx * sinRad + dy * cosRad;
      return StickerPoint(rx, ry);
    }).toList();
  }

  /// Checks if a rectangular element (with rotation around center) is fully inside a polygon [vertices].
  static bool isBoxInPolygon({
    required double x,
    required double y,
    required double width,
    required double height,
    required double rotationDegrees,
    required List<StickerPoint> vertices,
  }) {
    if (vertices.isEmpty) return true; // Empty printable area means full sticker is printable
    if (vertices.length < 3) return false;

    final corners = getRotatedCorners(
      x: x,
      y: y,
      width: width,
      height: height,
      rotationDegrees: rotationDegrees,
    );

    for (final corner in corners) {
      if (!isPointInPolygon(corner, vertices)) {
        return false;
      }
    }
    return true;
  }
}
