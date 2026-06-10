import 'package:stickify/domain/entities/editor/element_blueprint.dart';

enum BlueprintBarcodeType { code128, ean13 }

class BarcodeElementBlueprint extends ElementBlueprint {
  const BarcodeElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    required this.data,
    required this.isDynamic,
    required this.barcodeType,
    required this.showLabel,
  });

  final String data;          // raw or token e.g. "{{product.sku}}"
  final bool isDynamic;
  final BlueprintBarcodeType barcodeType;
  final bool showLabel;

  @override
  List<Object?> get props => [
        ...super.props,
        data,
        isDynamic,
        barcodeType,
        showLabel,
      ];

  @override
  BarcodeElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? data,
    bool? isDynamic,
    BlueprintBarcodeType? barcodeType,
    bool? showLabel,
  }) {
    return BarcodeElementBlueprint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      data: data ?? this.data,
      isDynamic: isDynamic ?? this.isDynamic,
      barcodeType: barcodeType ?? this.barcodeType,
      showLabel: showLabel ?? this.showLabel,
    );
  }
}
