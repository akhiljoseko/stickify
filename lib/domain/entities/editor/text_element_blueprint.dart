import 'package:stickify/domain/entities/editor/element_blueprint.dart';

enum BlueprintTextAlign { left, center, right, justify }

class TextElementBlueprint extends ElementBlueprint {
  const TextElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    required this.content,
    required this.isDynamic,
    required this.fontSize,
    required this.fontWeightValue, // e.g., 400 (normal), 700 (bold)
    required this.textAlign,
    required this.colorHex,       // ARGB hex value as int, e.g., 0xFF000000
    this.letterSpacing = 0.0,
  });

  final String content;       // raw string OR token e.g. "{{product.name}}"
  final bool isDynamic;       // true if content contains {{ }}
  final double fontSize;
  final int fontWeightValue;   // 100 to 900
  final BlueprintTextAlign textAlign;
  final int colorHex;
  final double letterSpacing;

  @override
  List<Object?> get props => [
        ...super.props,
        content,
        isDynamic,
        fontSize,
        fontWeightValue,
        textAlign,
        colorHex,
        letterSpacing,
      ];

  @override
  TextElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? content,
    bool? isDynamic,
    double? fontSize,
    int? fontWeightValue,
    BlueprintTextAlign? textAlign,
    int? colorHex,
    double? letterSpacing,
  }) {
    return TextElementBlueprint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      content: content ?? this.content,
      isDynamic: isDynamic ?? this.isDynamic,
      fontSize: fontSize ?? this.fontSize,
      fontWeightValue: fontWeightValue ?? this.fontWeightValue,
      textAlign: textAlign ?? this.textAlign,
      colorHex: colorHex ?? this.colorHex,
      letterSpacing: letterSpacing ?? this.letterSpacing,
    );
  }
}
