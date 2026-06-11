import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/domain/domain.dart';

/// Local JSON-based storage implementation of [TemplateRepository].
///
/// Interfaces directly with [DocumentDatabase] to fetch, create, update, or delete [LabelTemplate] configurations.
class DatabaseTemplateRepository implements TemplateRepository {
  /// Creates a [DatabaseTemplateRepository] backed by [database].
  DatabaseTemplateRepository({required DocumentDatabase database})
    : _db = database;

  final DocumentDatabase _db;
  static const String _collection = 'templates';

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    final allData = await _db.getAll(_collection);
    final list = allData.map(_templateFromJson).toList()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return list;
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    final data = await _db.get(_collection, id);
    if (data == null) {
      throw Exception('Template not found: $id');
    }
    return _templateFromJson(data);
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
    final id = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final template = LabelTemplate(
      id: id,
      name: name,
      updatedAt: DateTime.now(),
    );
    await _db.save(_collection, id, _templateToJson(template));
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      sheetConfig: config,
      updatedAt: DateTime.now(),
    );
    await _db.save(_collection, templateId, _templateToJson(updated));
  }

  @override
  Future<void> saveStickerConfig(
    String templateId,
    StickerConfig config,
  ) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      stickerConfig: config,
      updatedAt: DateTime.now(),
    );
    await _db.save(_collection, templateId, _templateToJson(updated));
  }

  @override
  Future<void> saveElements(
    String templateId,
    List<ElementBlueprint> elements,
  ) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      elements: elements,
      updatedAt: DateTime.now(),
    );
    await _db.save(_collection, templateId, _templateToJson(updated));
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      isFinalized: true,
      updatedAt: DateTime.now(),
    );
    await _db.save(_collection, templateId, _templateToJson(updated));
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _db.delete(_collection, id);
  }

  Map<String, dynamic> _templateToJson(LabelTemplate t) {
    return {
      'id': t.id,
      'name': t.name,
      'isFinalized': t.isFinalized,
      'updatedAt': t.updatedAt?.toIso8601String(),
      'sheetConfig': t.sheetConfig == null
          ? null
          : _sheetConfigToJson(t.sheetConfig!),
      'stickerConfig': t.stickerConfig == null
          ? null
          : _stickerConfigToJson(t.stickerConfig!),
      'elements': t.elements.map(_elementToJson).toList(),
    };
  }

  LabelTemplate _templateFromJson(Map<String, dynamic> json) {
    return LabelTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      isFinalized: json['isFinalized'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      sheetConfig: json['sheetConfig'] == null
          ? null
          : _sheetConfigFromJson(json['sheetConfig'] as Map<String, dynamic>),
      stickerConfig: json['stickerConfig'] == null
          ? null
          : _stickerConfigFromJson(
              json['stickerConfig'] as Map<String, dynamic>,
            ),
      elements: (json['elements'] as List? ?? [])
          .map((e) => _elementFromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> _sheetConfigToJson(SheetConfig c) => {
    'pageWidth': c.pageWidth,
    'pageHeight': c.pageHeight,
    'marginTop': c.marginTop,
    'marginBottom': c.marginBottom,
    'marginLeft': c.marginLeft,
    'marginRight': c.marginRight,
    'columns': c.columns,
    'rows': c.rows,
    'columnGap': c.columnGap,
    'rowGap': c.rowGap,
  };

  SheetConfig _sheetConfigFromJson(Map<String, dynamic> json) => SheetConfig(
    pageWidth: (json['pageWidth'] as num).toDouble(),
    pageHeight: (json['pageHeight'] as num).toDouble(),
    marginTop: (json['marginTop'] as num).toDouble(),
    marginBottom: (json['marginBottom'] as num).toDouble(),
    marginLeft: (json['marginLeft'] as num).toDouble(),
    marginRight: (json['marginRight'] as num).toDouble(),
    columns: json['columns'] as int,
    rows: json['rows'] as int,
    columnGap: (json['columnGap'] as num).toDouble(),
    rowGap: (json['rowGap'] as num).toDouble(),
  );

  Map<String, dynamic> _stickerConfigToJson(StickerConfig c) => {
    'widthMm': c.widthMm,
    'heightMm': c.heightMm,
    'cornerRadiusMm': c.cornerRadiusMm,
    'printableArea': c.printableArea.map((p) => {'x': p.x, 'y': p.y}).toList(),
  };

  StickerConfig _stickerConfigFromJson(Map<String, dynamic> json) =>
      StickerConfig(
        widthMm: (json['widthMm'] as num).toDouble(),
        heightMm: (json['heightMm'] as num).toDouble(),
        cornerRadiusMm: (json['cornerRadiusMm'] as num).toDouble(),
        printableArea: (json['printableArea'] as List? ?? []).map((item) {
          final m = item as Map<String, dynamic>;
          return StickerPoint(
            (m['x'] as num).toDouble(),
            (m['y'] as num).toDouble(),
          );
        }).toList(),
      );

  Map<String, dynamic> _elementToJson(ElementBlueprint eb) {
    final base = {
      'id': eb.id,
      'x': eb.x,
      'y': eb.y,
      'width': eb.width,
      'height': eb.height,
      'rotation': eb.rotation,
    };
    if (eb is TextElementBlueprint) {
      return {
        ...base,
        'type': 'text',
        'content': eb.content,
        'isDynamic': eb.isDynamic,
        'fontSize': eb.fontSize,
        'fontWeightValue': eb.fontWeightValue,
        'textAlign': eb.textAlign.name,
        'colorHex': eb.colorHex,
      };
    } else if (eb is ShapeElementBlueprint) {
      return {
        ...base,
        'type': 'shape',
        'fillColorHex': eb.fillColorHex,
        'strokeColorHex': eb.strokeColorHex,
        'strokeWidth': eb.strokeWidth,
        'cornerRadius': eb.cornerRadius,
        'isFilled': eb.isFilled,
      };
    } else if (eb is BarcodeElementBlueprint) {
      return {
        ...base,
        'type': 'barcode',
        'data': eb.data,
        'isDynamic': eb.isDynamic,
        'barcodeType': eb.barcodeType.name,
        'showLabel': eb.showLabel,
      };
    } else if (eb is QrElementBlueprint) {
      return {
        ...base,
        'type': 'qr',
        'data': eb.data,
        'isDynamic': eb.isDynamic,
      };
    } else if (eb is ImageElementBlueprint) {
      return {
        ...base,
        'type': 'image',
        'assetPath': eb.assetPath,
        'networkUrl': eb.networkUrl,
        'localFilePath': eb.localFilePath,
        'fit': eb.fit.name,
      };
    }
    throw UnimplementedError('Unknown blueprint type: ${eb.runtimeType}');
  }

  ElementBlueprint _elementFromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final id = json['id'] as String;
    final x = (json['x'] as num).toDouble();
    final y = (json['y'] as num).toDouble();
    final width = (json['width'] as num).toDouble();
    final height = (json['height'] as num).toDouble();
    final rotation = (json['rotation'] as num).toDouble();

    switch (type) {
      case 'text':
        return TextElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          content: json['content'] as String,
          isDynamic: json['isDynamic'] as bool,
          fontSize: (json['fontSize'] as num).toDouble(),
          fontWeightValue: json['fontWeightValue'] as int,
          textAlign: BlueprintTextAlign.values.firstWhere(
            (e) => e.name == json['textAlign'],
          ),
          colorHex: json['colorHex'] as int,
        );
      case 'shape':
        return ShapeElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          fillColorHex: json['fillColorHex'] as int,
          strokeColorHex: json['strokeColorHex'] as int,
          strokeWidth: (json['strokeWidth'] as num).toDouble(),
          cornerRadius: (json['cornerRadius'] as num).toDouble(),
          isFilled: json['isFilled'] as bool,
        );
      case 'barcode':
        return BarcodeElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          data: json['data'] as String,
          isDynamic: json['isDynamic'] as bool,
          barcodeType: BlueprintBarcodeType.values.firstWhere(
            (e) => e.name == json['barcodeType'],
          ),
          showLabel: json['showLabel'] as bool,
        );
      case 'qr':
        return QrElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          data: json['data'] as String,
          isDynamic: json['isDynamic'] as bool,
        );
      case 'image':
        return ImageElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          assetPath: json['assetPath'] as String?,
          networkUrl: json['networkUrl'] as String?,
          localFilePath: json['localFilePath'] as String?,
          fit: BlueprintBoxFit.values.firstWhere((e) => e.name == json['fit']),
        );
      default:
        throw UnimplementedError('Unknown blueprint type in json: $type');
    }
  }
}
