import 'package:stickify/domain/entities/editor/element_blueprint.dart';

/// A blueprint element representing a shape (e.g. rounded rectangle) in the label template.
class ShapeElementBlueprint extends ElementBlueprint {
  /// Creates a [ShapeElementBlueprint] configuration.
  const ShapeElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    required this.fillColorHex,
    required this.strokeColorHex,
    required this.strokeWidth,
    required this.cornerRadius,
    required this.isFilled,
  });

  /// Fill color value of the shape in 32-bit ARGB hex integer format.
  final int fillColorHex;

  /// Stroke border color value of the shape in 32-bit ARGB hex integer format.
  final int strokeColorHex;

  /// Width of the stroke border in logical pixels.
  final double strokeWidth;

  /// Corner radius of the shape in logical pixels (useful for drawing rounded rectangles).
  final double cornerRadius;

  /// True if the shape should be drawn with a solid color fill.
  final bool isFilled;

  @override
  List<Object?> get props => [
        ...super.props,
        fillColorHex,
        strokeColorHex,
        strokeWidth,
        cornerRadius,
        isFilled,
      ];

  @override
  ShapeElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? fillColorHex,
    int? strokeColorHex,
    double? strokeWidth,
    double? cornerRadius,
    bool? isFilled,
  }) {
    return ShapeElementBlueprint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      fillColorHex: fillColorHex ?? this.fillColorHex,
      strokeColorHex: strokeColorHex ?? this.strokeColorHex,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      isFilled: isFilled ?? this.isFilled,
    );
  }
}
