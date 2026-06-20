import 'package:stickify/domain/entities/editor/element_blueprint.dart';

/// A blueprint element representing a Nutrition Facts table in the label template.
class NutritionTableElementBlueprint extends ElementBlueprint {
  /// Creates a [NutritionTableElementBlueprint] configuration.
  const NutritionTableElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    this.colorHex = 0xFF000000,
  });

  /// Color value of the text and borders in 32-bit ARGB hex integer format (e.g. 0xFF000000).
  final int colorHex;

  @override
  List<Object?> get props => [
        ...super.props,
        colorHex,
      ];

  @override
  NutritionTableElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    int? colorHex,
  }) {
    return NutritionTableElementBlueprint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      colorHex: colorHex ?? this.colorHex,
    );
  }
}
