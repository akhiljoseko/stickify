import 'package:stickify/domain/entities/editor/element_blueprint.dart';

/// Supported barcode types for rendering barcodes on labels.
enum BlueprintBarcodeType {
  /// Code 128 format barcode.
  code128,

  /// EAN-13 format barcode.
  ean13,
}

/// A blueprint element representing a barcode in the label template.
class BarcodeElementBlueprint extends ElementBlueprint {
  /// Creates a [BarcodeElementBlueprint] configuration.
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

  /// Barcode raw data string or dynamic evaluation token, e.g. `{{product.sku}}`.
  final String data;

  /// True if [data] represents a dynamic token evaluated at print-time.
  final bool isDynamic;

  /// Type encoding style of this barcode.
  final BlueprintBarcodeType barcodeType;

  /// True if the human-readable text label should be displayed beneath the barcode.
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
