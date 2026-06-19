import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/domain.dart';

/// Firestore persistence model for Label Templates.
class TemplateFirestoreModel {
  TemplateFirestoreModel({
    required this.id,
    required this.name,
    required this.isFinalized,
    this.updatedAt,
    this.sheetConfig,
    this.stickerConfig,
    this.elements = const [],
    this.imageUrl,
  });

  factory TemplateFirestoreModel.fromDomain(LabelTemplate t) {
    return TemplateFirestoreModel(
      id: t.id,
      name: t.name,
      isFinalized: t.isFinalized,
      updatedAt: t.updatedAt,
      sheetConfig: t.sheetConfig == null
          ? null
          : SheetConfigFirestoreModel.fromDomain(t.sheetConfig!),
      stickerConfig: t.stickerConfig == null
          ? null
          : StickerConfigFirestoreModel.fromDomain(t.stickerConfig!),
      elements: t.elements.map(ElementBlueprintFirestoreModel.fromDomain).toList(),
      imageUrl: t.imageUrl,
    );
  }

  factory TemplateFirestoreModel.fromMap(String id, Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    }

    return TemplateFirestoreModel(
      id: id,
      name: json['name'] as String? ?? '',
      isFinalized: json['isFinalized'] as bool? ?? false,
      updatedAt: parseDateTime(json['updatedAt']),
      sheetConfig: json['sheetConfig'] == null
          ? null
          : SheetConfigFirestoreModel.fromMap(json['sheetConfig'] as Map<String, dynamic>),
      stickerConfig: json['stickerConfig'] == null
          ? null
          : StickerConfigFirestoreModel.fromMap(json['stickerConfig'] as Map<String, dynamic>),
      elements: (json['elements'] as List? ?? [])
          .map((e) => ElementBlueprintFirestoreModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String id;
  final String name;
  final bool isFinalized;
  final DateTime? updatedAt;
  final SheetConfigFirestoreModel? sheetConfig;
  final StickerConfigFirestoreModel? stickerConfig;
  final List<ElementBlueprintFirestoreModel> elements;
  final String? imageUrl;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'isFinalized': isFinalized,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'sheetConfig': sheetConfig?.toMap(),
      'stickerConfig': stickerConfig?.toMap(),
      'elements': elements.map((e) => e.toMap()).toList(),
      'imageUrl': imageUrl,
    };
  }

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

class SheetConfigFirestoreModel {
  SheetConfigFirestoreModel({
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

  factory SheetConfigFirestoreModel.fromDomain(SheetConfig c) {
    return SheetConfigFirestoreModel(
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

  factory SheetConfigFirestoreModel.fromMap(Map<String, dynamic> json) {
    return SheetConfigFirestoreModel(
      pageWidth: (json['pageWidth'] as num? ?? 0.0).toDouble(),
      pageHeight: (json['pageHeight'] as num? ?? 0.0).toDouble(),
      marginTop: (json['marginTop'] as num? ?? 0.0).toDouble(),
      marginBottom: (json['marginBottom'] as num? ?? 0.0).toDouble(),
      marginLeft: (json['marginLeft'] as num? ?? 0.0).toDouble(),
      marginRight: (json['marginRight'] as num? ?? 0.0).toDouble(),
      columns: json['columns'] as int? ?? 1,
      rows: json['rows'] as int? ?? 1,
      columnGap: (json['columnGap'] as num? ?? 0.0).toDouble(),
      rowGap: (json['rowGap'] as num? ?? 0.0).toDouble(),
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

  Map<String, dynamic> toMap() => {
        'pageWidth': pageWidth,
        'pageHeight': pageHeight,
        'marginTop': marginTop,
        'marginBottom': marginBottom,
        'marginLeft': marginLeft,
        'marginRight': marginRight,
        'columns': columns,
        'rows': rows,
        'columnGap': columnGap,
        'rowGap': rowGap,
      };

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

class StickerConfigFirestoreModel {
  StickerConfigFirestoreModel({
    required this.widthMm,
    required this.heightMm,
    required this.cornerRadiusMm,
    this.printableArea = const [],
  });

  factory StickerConfigFirestoreModel.fromDomain(StickerConfig c) {
    return StickerConfigFirestoreModel(
      widthMm: c.widthMm,
      heightMm: c.heightMm,
      cornerRadiusMm: c.cornerRadiusMm,
      printableArea: c.printableArea.map(StickerPointFirestoreModel.fromDomain).toList(),
    );
  }

  factory StickerConfigFirestoreModel.fromMap(Map<String, dynamic> json) {
    return StickerConfigFirestoreModel(
      widthMm: (json['widthMm'] as num? ?? 0.0).toDouble(),
      heightMm: (json['heightMm'] as num? ?? 0.0).toDouble(),
      cornerRadiusMm: (json['cornerRadiusMm'] as num? ?? 0.0).toDouble(),
      printableArea: (json['printableArea'] as List? ?? [])
          .map((item) => StickerPointFirestoreModel.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final double widthMm;
  final double heightMm;
  final double cornerRadiusMm;
  final List<StickerPointFirestoreModel> printableArea;

  Map<String, dynamic> toMap() => {
        'widthMm': widthMm,
        'heightMm': heightMm,
        'cornerRadiusMm': cornerRadiusMm,
        'printableArea': printableArea.map((p) => p.toMap()).toList(),
      };

  StickerConfig toDomain() {
    return StickerConfig(
      widthMm: widthMm,
      heightMm: heightMm,
      cornerRadiusMm: cornerRadiusMm,
      printableArea: printableArea.map((p) => p.toDomain()).toList(),
    );
  }
}

class StickerPointFirestoreModel {
  StickerPointFirestoreModel(this.x, this.y);

  factory StickerPointFirestoreModel.fromDomain(StickerPoint p) {
    return StickerPointFirestoreModel(p.x, p.y);
  }

  factory StickerPointFirestoreModel.fromMap(Map<String, dynamic> json) {
    return StickerPointFirestoreModel(
      (json['x'] as num? ?? 0.0).toDouble(),
      (json['y'] as num? ?? 0.0).toDouble(),
    );
  }

  final double x;
  final double y;

  Map<String, dynamic> toMap() => {'x': x, 'y': y};

  StickerPoint toDomain() => StickerPoint(x, y);
}

class ElementBlueprintFirestoreModel {
  ElementBlueprintFirestoreModel({
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

  factory ElementBlueprintFirestoreModel.fromDomain(ElementBlueprint eb) {
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

    return ElementBlueprintFirestoreModel(
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

  factory ElementBlueprintFirestoreModel.fromMap(Map<String, dynamic> json) {
    return ElementBlueprintFirestoreModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      x: (json['x'] as num? ?? 0.0).toDouble(),
      y: (json['y'] as num? ?? 0.0).toDouble(),
      width: (json['width'] as num? ?? 0.0).toDouble(),
      height: (json['height'] as num? ?? 0.0).toDouble(),
      rotation: (json['rotation'] as num? ?? 0.0).toDouble(),
      content: json['content'] as String?,
      isDynamic: json['isDynamic'] as bool?,
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      fontWeightValue: json['fontWeightValue'] as int?,
      textAlign: json['textAlign'] as String?,
      colorHex: json['colorHex'] as int?,
      fillColorHex: json['fillColorHex'] as int?,
      strokeColorHex: json['strokeColorHex'] as int?,
      strokeWidth: (json['strokeWidth'] as num?)?.toDouble(),
      cornerRadius: (json['cornerRadius'] as num?)?.toDouble(),
      isFilled: json['isFilled'] as bool?,
      data: json['data'] as String?,
      barcodeType: json['barcodeType'] as String?,
      showLabel: json['showLabel'] as bool?,
      assetPath: json['assetPath'] as String?,
      networkUrl: json['networkUrl'] as String?,
      localFilePath: json['localFilePath'] as String?,
      fit: json['fit'] as String?,
      maxLines: json['maxLines'] as int?,
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

  // text max lines
  final int? maxLines;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'rotation': rotation,
      'content': content,
      'isDynamic': isDynamic,
      'fontSize': fontSize,
      'fontWeightValue': fontWeightValue,
      'textAlign': textAlign,
      'colorHex': colorHex,
      'fillColorHex': fillColorHex,
      'strokeColorHex': strokeColorHex,
      'strokeWidth': strokeWidth,
      'cornerRadius': cornerRadius,
      'isFilled': isFilled,
      'data': data,
      'barcodeType': barcodeType,
      'showLabel': showLabel,
      'assetPath': assetPath,
      'networkUrl': networkUrl,
      'localFilePath': localFilePath,
      'fit': fit,
      'maxLines': maxLines,
    };
  }

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
