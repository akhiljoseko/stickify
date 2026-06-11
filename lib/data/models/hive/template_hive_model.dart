import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

part 'template_hive_model.g.dart';

@HiveType(typeId: 4)
class LabelTemplateHiveModel extends HiveObject {
  LabelTemplateHiveModel({
    required this.id,
    required this.name,
    required this.isFinalized,
    this.updatedAt,
    this.sheetConfig,
    this.stickerConfig,
    this.elements = const [],
  });

  factory LabelTemplateHiveModel.fromDomain(LabelTemplate t) {
    return LabelTemplateHiveModel(
      id: t.id,
      name: t.name,
      isFinalized: t.isFinalized,
      updatedAt: t.updatedAt,
      sheetConfig: t.sheetConfig == null
          ? null
          : SheetConfigHiveModel.fromDomain(t.sheetConfig!),
      stickerConfig: t.stickerConfig == null
          ? null
          : StickerConfigHiveModel.fromDomain(t.stickerConfig!),
      elements: t.elements.map(ElementBlueprintHiveModel.fromDomain).toList(),
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final bool isFinalized;

  @HiveField(3)
  final DateTime? updatedAt;

  @HiveField(4)
  final SheetConfigHiveModel? sheetConfig;

  @HiveField(5)
  final StickerConfigHiveModel? stickerConfig;

  @HiveField(6)
  final List<ElementBlueprintHiveModel> elements;

  LabelTemplate toDomain() {
    return LabelTemplate(
      id: id,
      name: name,
      isFinalized: isFinalized,
      updatedAt: updatedAt,
      sheetConfig: sheetConfig?.toDomain(),
      stickerConfig: stickerConfig?.toDomain(),
      elements: elements.map((e) => e.toDomain()).toList(),
    );
  }
}

@HiveType(typeId: 5)
class SheetConfigHiveModel extends HiveObject {
  SheetConfigHiveModel({
    required this.pageWidth,
    required this.pageHeight,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
    required this.columns,
    required this.rows,
    required this.columnGap,
    required this.rowGap,
  });

  factory SheetConfigHiveModel.fromDomain(SheetConfig c) {
    return SheetConfigHiveModel(
      pageWidth: c.pageWidth,
      pageHeight: c.pageHeight,
      marginTop: c.marginTop,
      marginBottom: c.marginBottom,
      marginLeft: c.marginLeft,
      marginRight: c.marginRight,
      columns: c.columns,
      rows: c.rows,
      columnGap: c.columnGap,
      rowGap: c.rowGap,
    );
  }

  @HiveField(0)
  final double pageWidth;

  @HiveField(1)
  final double pageHeight;

  @HiveField(2)
  final double marginTop;

  @HiveField(3)
  final double marginBottom;

  @HiveField(4)
  final double marginLeft;

  @HiveField(5)
  final double marginRight;

  @HiveField(6)
  final int columns;

  @HiveField(7)
  final int rows;

  @HiveField(8)
  final double columnGap;

  @HiveField(9)
  final double rowGap;

  SheetConfig toDomain() {
    return SheetConfig(
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      marginTop: marginTop,
      marginBottom: marginBottom,
      marginLeft: marginLeft,
      marginRight: marginRight,
      columns: columns,
      rows: rows,
      columnGap: columnGap,
      rowGap: rowGap,
    );
  }
}

@HiveType(typeId: 6)
class StickerConfigHiveModel extends HiveObject {
  StickerConfigHiveModel({
    required this.widthMm,
    required this.heightMm,
    required this.cornerRadiusMm,
    this.printableArea = const [],
  });

  factory StickerConfigHiveModel.fromDomain(StickerConfig c) {
    return StickerConfigHiveModel(
      widthMm: c.widthMm,
      heightMm: c.heightMm,
      cornerRadiusMm: c.cornerRadiusMm,
      printableArea: c.printableArea.map(StickerPointHiveModel.fromDomain).toList(),
    );
  }

  @HiveField(0)
  final double widthMm;

  @HiveField(1)
  final double heightMm;

  @HiveField(2)
  final double cornerRadiusMm;

  @HiveField(3)
  final List<StickerPointHiveModel> printableArea;

  StickerConfig toDomain() {
    return StickerConfig(
      widthMm: widthMm,
      heightMm: heightMm,
      cornerRadiusMm: cornerRadiusMm,
      printableArea: printableArea.map((p) => p.toDomain()).toList(),
    );
  }
}

@HiveType(typeId: 7)
class StickerPointHiveModel extends HiveObject {
  StickerPointHiveModel({
    required this.x,
    required this.y,
  });

  factory StickerPointHiveModel.fromDomain(StickerPoint p) {
    return StickerPointHiveModel(
      x: p.x,
      y: p.y,
    );
  }

  @HiveField(0)
  final double x;

  @HiveField(1)
  final double y;

  StickerPoint toDomain() {
    return StickerPoint(x, y);
  }
}

@HiveType(typeId: 8)
class ElementBlueprintHiveModel extends HiveObject {
  ElementBlueprintHiveModel({
    required this.id,
    required this.type,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
    this.content,
    this.isDynamic,
    this.fontSize,
    this.fontWeightValue,
    this.textAlign,
    this.colorHex,
    this.fillColorHex,
    this.strokeColorHex,
    this.strokeWidth,
    this.cornerRadius,
    this.isFilled,
    this.data,
    this.barcodeType,
    this.showLabel,
    this.assetPath,
    this.networkUrl,
    this.localFilePath,
    this.fit,
  });

  factory ElementBlueprintHiveModel.fromDomain(ElementBlueprint eb) {
    var type = '';
    String? content;
    bool? isDynamic;
    double? fontSize;
    int? fontWeightValue;
    String? textAlign;
    int? colorHex;
    int? fillColorHex;
    int? strokeColorHex;
    double? strokeWidth;
    double? cornerRadius;
    bool? isFilled;
    String? data;
    String? barcodeType;
    bool? showLabel;
    String? assetPath;
    String? networkUrl;
    String? localFilePath;
    String? fit;

    if (eb is TextElementBlueprint) {
      type = 'text';
      content = eb.content;
      isDynamic = eb.isDynamic;
      fontSize = eb.fontSize;
      fontWeightValue = eb.fontWeightValue;
      textAlign = eb.textAlign.name;
      colorHex = eb.colorHex;
    } else if (eb is ShapeElementBlueprint) {
      type = 'shape';
      fillColorHex = eb.fillColorHex;
      strokeColorHex = eb.strokeColorHex;
      strokeWidth = eb.strokeWidth;
      cornerRadius = eb.cornerRadius;
      isFilled = eb.isFilled;
    } else if (eb is BarcodeElementBlueprint) {
      type = 'barcode';
      data = eb.data;
      isDynamic = eb.isDynamic;
      barcodeType = eb.barcodeType.name;
      showLabel = eb.showLabel;
    } else if (eb is QrElementBlueprint) {
      type = 'qr';
      data = eb.data;
      isDynamic = eb.isDynamic;
    } else if (eb is ImageElementBlueprint) {
      type = 'image';
      assetPath = eb.assetPath;
      networkUrl = eb.networkUrl;
      localFilePath = eb.localFilePath;
      fit = eb.fit.name;
    }

    return ElementBlueprintHiveModel(
      id: eb.id,
      type: type,
      x: eb.x,
      y: eb.y,
      width: eb.width,
      height: eb.height,
      rotation: eb.rotation,
      content: content,
      isDynamic: isDynamic,
      fontSize: fontSize,
      fontWeightValue: fontWeightValue,
      textAlign: textAlign,
      colorHex: colorHex,
      fillColorHex: fillColorHex,
      strokeColorHex: strokeColorHex,
      strokeWidth: strokeWidth,
      cornerRadius: cornerRadius,
      isFilled: isFilled,
      data: data,
      barcodeType: barcodeType,
      showLabel: showLabel,
      assetPath: assetPath,
      networkUrl: networkUrl,
      localFilePath: localFilePath,
      fit: fit,
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final double x;

  @HiveField(3)
  final double y;

  @HiveField(4)
  final double width;

  @HiveField(5)
  final double height;

  @HiveField(6)
  final double rotation;

  // text
  @HiveField(7)
  final String? content;

  @HiveField(8)
  final bool? isDynamic;

  @HiveField(9)
  final double? fontSize;

  @HiveField(10)
  final int? fontWeightValue;

  @HiveField(11)
  final String? textAlign;

  @HiveField(12)
  final int? colorHex;

  // shape
  @HiveField(13)
  final int? fillColorHex;

  @HiveField(14)
  final int? strokeColorHex;

  @HiveField(15)
  final double? strokeWidth;

  @HiveField(16)
  final double? cornerRadius;

  @HiveField(17)
  final bool? isFilled;

  // barcode / qr
  @HiveField(18)
  final String? data;

  @HiveField(19)
  final String? barcodeType;

  @HiveField(20)
  final bool? showLabel;

  // image
  @HiveField(21)
  final String? assetPath;

  @HiveField(22)
  final String? networkUrl;

  @HiveField(23)
  final String? localFilePath;

  @HiveField(24)
  final String? fit;

  ElementBlueprint toDomain() {
    switch (type) {
      case 'text':
        return TextElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          content: content ?? '',
          isDynamic: isDynamic ?? false,
          fontSize: fontSize ?? 12.0,
          fontWeightValue: fontWeightValue ?? 400,
          textAlign: BlueprintTextAlign.values.firstWhere(
            (e) => e.name == textAlign,
            orElse: () => BlueprintTextAlign.left,
          ),
          colorHex: colorHex ?? 0xFF000000,
        );
      case 'shape':
        return ShapeElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          fillColorHex: fillColorHex ?? 0xFFFFFFFF,
          strokeColorHex: strokeColorHex ?? 0xFF000000,
          strokeWidth: strokeWidth ?? 1.0,
          cornerRadius: cornerRadius ?? 0.0,
          isFilled: isFilled ?? false,
        );
      case 'barcode':
        return BarcodeElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          data: data ?? '',
          isDynamic: isDynamic ?? false,
          barcodeType: BlueprintBarcodeType.values.firstWhere(
            (e) => e.name == barcodeType,
            orElse: () => BlueprintBarcodeType.code128,
          ),
          showLabel: showLabel ?? true,
        );
      case 'qr':
        return QrElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          data: data ?? '',
          isDynamic: isDynamic ?? false,
        );
      case 'image':
        return ImageElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          assetPath: assetPath,
          networkUrl: networkUrl,
          localFilePath: localFilePath,
          fit: BlueprintBoxFit.values.firstWhere(
            (e) => e.name == fit,
            orElse: () => BlueprintBoxFit.contain,
          ),
        );
      default:
        throw UnimplementedError('Unknown blueprint type: $type');
    }
  }
}
