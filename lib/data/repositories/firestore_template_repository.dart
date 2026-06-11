import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/domain.dart';

/// Firestore-based implementation of [TemplateRepository] partitioned by user.
class FirestoreTemplateRepository implements TemplateRepository {
  /// Creates a [FirestoreTemplateRepository] instance.
  FirestoreTemplateRepository({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get templatesRef => _templatesRef;
  Map<String, dynamic> templateToJson(LabelTemplate t) => _templateToJson(t);

  CollectionReference<Map<String, dynamic>> get _templatesRef =>
      _firestore.collection('users').doc(_userId).collection('templates');

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    final snapshot = await _templatesRef.get();
    final list = snapshot.docs.map((doc) => _templateFromFirestore(doc.id, doc.data())).toList()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return list;
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    final doc = await _templatesRef.doc(id).get();
    final data = doc.data();
    if (data == null) {
      throw Exception('Template not found in Firestore: $id');
    }
    return _templateFromFirestore(doc.id, data);
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
    final id = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final template = LabelTemplate(
      id: id,
      name: name,
      updatedAt: DateTime.now(),
    );
    await _templatesRef.doc(id).set(_templateToJson(template));
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      sheetConfig: config,
      updatedAt: DateTime.now(),
    );
    await _templatesRef.doc(templateId).set(_templateToJson(updated));
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      stickerConfig: config,
      updatedAt: DateTime.now(),
    );
    await _templatesRef.doc(templateId).set(_templateToJson(updated));
  }

  @override
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      elements: elements,
      updatedAt: DateTime.now(),
    );
    await _templatesRef.doc(templateId).set(_templateToJson(updated));
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      isFinalized: true,
      updatedAt: DateTime.now(),
    );
    await _templatesRef.doc(templateId).set(_templateToJson(updated));
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _templatesRef.doc(id).delete();
  }

  Map<String, dynamic> _templateToJson(LabelTemplate t) {
    return {
      'id': t.id,
      'name': t.name,
      'isFinalized': t.isFinalized,
      'updatedAt': t.updatedAt != null ? Timestamp.fromDate(t.updatedAt!) : null,
      'sheetConfig': t.sheetConfig == null ? null : _sheetConfigToJson(t.sheetConfig!),
      'stickerConfig': t.stickerConfig == null ? null : _stickerConfigToJson(t.stickerConfig!),
      'elements': t.elements.map(_elementToJson).toList(),
    };
  }

  LabelTemplate _templateFromFirestore(String id, Map<String, dynamic> json) {
    DateTime? parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return null;
    }

    return LabelTemplate(
      id: id,
      name: json['name'] as String,
      isFinalized: json['isFinalized'] as bool? ?? false,
      updatedAt: parseDateTime(json['updatedAt']),
      sheetConfig: json['sheetConfig'] == null
          ? null
          : _sheetConfigFromJson(json['sheetConfig'] as Map<String, dynamic>),
      stickerConfig: json['stickerConfig'] == null
          ? null
          : _stickerConfigFromJson(json['stickerConfig'] as Map<String, dynamic>),
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

  StickerConfig _stickerConfigFromJson(Map<String, dynamic> json) => StickerConfig(
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
          content: json['content'] as String? ?? '',
          isDynamic: json['isDynamic'] as bool? ?? false,
          fontSize: (json['fontSize'] as num? ?? 12).toDouble(),
          fontWeightValue: json['fontWeightValue'] as int? ?? 400,
          textAlign: BlueprintTextAlign.values.firstWhere(
            (e) => e.name == json['textAlign'],
            orElse: () => BlueprintTextAlign.left,
          ),
          colorHex: json['colorHex'] as int? ?? 0xFF000000,
        );
      case 'shape':
        return ShapeElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          fillColorHex: json['fillColorHex'] as int? ?? 0xFFFFFFFF,
          strokeColorHex: json['strokeColorHex'] as int? ?? 0xFF000000,
          strokeWidth: (json['strokeWidth'] as num? ?? 1.0).toDouble(),
          cornerRadius: (json['cornerRadius'] as num? ?? 0.0).toDouble(),
          isFilled: json['isFilled'] as bool? ?? false,
        );
      case 'barcode':
        return BarcodeElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          data: json['data'] as String? ?? '',
          isDynamic: json['isDynamic'] as bool? ?? false,
          barcodeType: BlueprintBarcodeType.values.firstWhere(
            (e) => e.name == json['barcodeType'],
            orElse: () => BlueprintBarcodeType.code128,
          ),
          showLabel: json['showLabel'] as bool? ?? true,
        );
      case 'qr':
        return QrElementBlueprint(
          id: id,
          x: x,
          y: y,
          width: width,
          height: height,
          rotation: rotation,
          data: json['data'] as String? ?? '',
          isDynamic: json['isDynamic'] as bool? ?? false,
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
          fit: BlueprintBoxFit.values.firstWhere(
            (e) => e.name == json['fit'],
            orElse: () => BlueprintBoxFit.contain,
          ),
        );
      default:
        throw UnimplementedError('Unknown blueprint type in json: $type');
    }
  }
}
