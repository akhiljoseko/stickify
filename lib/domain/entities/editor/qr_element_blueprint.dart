import 'package:stickify/domain/entities/editor/element_blueprint.dart';

class QrElementBlueprint extends ElementBlueprint {
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

  final String data;          // raw or token e.g. "{{product.sku}}"
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
