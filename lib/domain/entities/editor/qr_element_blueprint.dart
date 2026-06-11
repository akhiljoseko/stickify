import 'package:stickify/domain/entities/editor/element_blueprint.dart';

/// A blueprint element representing a QR code in the label template.
class QrElementBlueprint extends ElementBlueprint {
  /// Creates a [QrElementBlueprint] configuration.
  const QrElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    required this.data,
    required this.isDynamic,
  });

  /// QR code raw data payload or evaluation token.
  final String data;

  /// True if [data] represents a dynamic token evaluated at print-time.
  final bool isDynamic;

  @override
  List<Object?> get props => [
        ...super.props,
        data,
        isDynamic,
      ];

  @override
  QrElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? data,
    bool? isDynamic,
  }) {
    return QrElementBlueprint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      data: data ?? this.data,
      isDynamic: isDynamic ?? this.isDynamic,
    );
  }
}
