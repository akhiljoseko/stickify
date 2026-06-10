import 'package:stickify/domain/entities/editor/element_blueprint.dart';

class ShapeElementBlueprint extends ElementBlueprint {
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

  final int fillColorHex;
  final int strokeColorHex;
  final double strokeWidth;
  final double cornerRadius;
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
