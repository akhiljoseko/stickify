import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

class LabelTemplateHiveModel extends HiveObject {
  LabelTemplateHiveModel({
    required this.id,
    required this.name,
    required this.isFinalized,
    this.updatedAt,
    this.sheetConfig,
    this.stickerConfig,
    this.elements = const [],
    this.imageUrl,
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
      imageUrl: t.imageUrl,
    );
  }

  final String id;
  final String name;
  final bool isFinalized;
  final DateTime? updatedAt;
  final SheetConfigHiveModel? sheetConfig;
  final StickerConfigHiveModel? stickerConfig;
  final List<ElementBlueprintHiveModel> elements;
  final String? imageUrl;

  LabelTemplate toDomain() {
    return LabelTemplate(
      id: id,
      name: name,
      isFinalized: isFinalized,
      updatedAt: updatedAt,
      sheetConfig: sheetConfig?.toDomain(),
      stickerConfig: stickerConfig?.toDomain(),
      elements: elements.map((e) => e.toDomain()).toList(),
      imageUrl: imageUrl,
    );
  }
}

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

  final double pageWidth;
  final double pageHeight;
  final double marginTop;
  final double marginBottom;
  final double marginLeft;
  final double marginRight;
  final int columns;
  final int rows;
  final double columnGap;
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

  final double widthMm;
  final double heightMm;
  final double cornerRadiusMm;
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

  final double x;
  final double y;

  StickerPoint toDomain() {
    return StickerPoint(x, y);
  }
}

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
    this.maxLines,
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
    int? maxLines;

    if (eb is TextElementBlueprint) {
      type = 'text';
      content = eb.content;
      isDynamic = eb.isDynamic;
      fontSize = eb.fontSize;
      fontWeightValue = eb.fontWeightValue;
      textAlign = eb.textAlign.name;
      colorHex = eb.colorHex;
      maxLines = eb.maxLines;
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
      maxLines: maxLines,
    );
  }

  final String id;
  final String type;
  final double x;
  final double y;
  final double width;
  final double height;
  final double rotation;

  // text
  final String? content;
  final bool? isDynamic;
  final double? fontSize;
  final int? fontWeightValue;
  final String? textAlign;
  final int? colorHex;

  // shape
  final int? fillColorHex;
  final int? strokeColorHex;
  final double? strokeWidth;
  final double? cornerRadius;
  final bool? isFilled;

  // barcode / qr
  final String? data;
  final String? barcodeType;
  final bool? showLabel;

  // image
  final String? assetPath;
  final String? networkUrl;
  final String? localFilePath;
  final String? fit;
  final int? maxLines;

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
          maxLines: maxLines ?? 1,
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
