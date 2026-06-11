import 'package:stickify/domain/entities/editor/element_blueprint.dart';

/// Supported text alignments inside a text element blueprint box.
enum BlueprintTextAlign {
  /// Align text to the left margin.
  left,

  /// Center the text horizontally.
  center,

  /// Align text to the right margin.
  right,

  /// Justify the text across the full width.
  justify,
}

/// A blueprint element representing a text block in the label template.
class TextElementBlueprint extends ElementBlueprint {
  /// Creates a [TextElementBlueprint] configuration.
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
    required this.fontWeightValue,
    required this.textAlign,
    required this.colorHex,
    this.letterSpacing = 0.0,
  });

  /// The raw content string (e.g., "Ingredients:") or a dynamic token expression (e.g., `{{product.name}}`).
  final String content;

  /// True if [content] contains dynamic evaluation tokens (e.g., `{{product.sku}}`).
  final bool isDynamic;

  /// Font size of the text in logical points.
  final double fontSize;

  /// Font weight weight value, ranging from 100 to 900 (e.g., 400 for regular, 700 for bold).
  final int fontWeightValue;

  /// Alignment of the text inside the bounding width box.
  final BlueprintTextAlign textAlign;

  /// Color value of the text in 32-bit ARGB hex integer format (e.g. 0xFF000000).
  final int colorHex;

  /// Letter spacing of the text characters.
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
