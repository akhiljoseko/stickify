import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/data/repositories/firestore_template_repository.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [TemplateRepository] implementing local caching and manual synchronization.
class SyncingTemplateRepository implements TemplateRepository {
  /// Creates a [SyncingTemplateRepository] instance.
  SyncingTemplateRepository({
    required DatabaseTemplateRepository local,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required DocumentDatabase localDatabase,
  })  : _local = local,
        _auth = auth,
        _firestore = firestore,
        _localDb = localDatabase;

  final DatabaseTemplateRepository _local;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DocumentDatabase _localDb;

  FirestoreTemplateRepository? get _remote {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreTemplateRepository(firestore: _firestore, userId: uid);
  }

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    return _local.fetchTemplates();
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    return _local.fetchTemplate(id);
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
    final template = await _local.createTemplate(name);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.templatesRef.doc(template.id).set(remoteRepo.templateToJson(template));
      } catch (_) {
        // Fallback
      }
    }
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    await _local.saveSheetConfig(templateId, config);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveSheetConfig(templateId, config);
      } catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    await _local.saveStickerConfig(templateId, config);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveStickerConfig(templateId, config);
      } catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements) async {
    await _local.saveElements(templateId, elements);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveElements(templateId, elements);
      } catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    await _local.finalizeTemplate(templateId);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.finalizeTemplate(templateId);
      } catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _local.deleteTemplate(id);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.deleteTemplate(id);
      } catch (_) {
        // Fallback
      }
    }
  }

  /// Pulls all templates from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreTemplateRepository(firestore: _firestore, userId: uid);
    final remoteTemplates = await remoteRepo.fetchTemplates();

    // Clear local cache
    final localTemplates = await _local.fetchTemplates();
    for (final t in localTemplates) {
      await _local.deleteTemplate(t.id);
    }

    // Overwrite local cache with remote data (preserving original IDs)
    for (final t in remoteTemplates) {
      await _localDb.save('templates', t.id, _localTemplateToJson(t));
    }
  }

  Map<String, dynamic> _localTemplateToJson(LabelTemplate t) {
    return {
      'id': t.id,
      'name': t.name,
      'isFinalized': t.isFinalized,
      'updatedAt': t.updatedAt?.toIso8601String(),
      'sheetConfig': t.sheetConfig == null ? null : _sheetConfigToJson(t.sheetConfig!),
      'stickerConfig': t.stickerConfig == null ? null : _stickerConfigToJson(t.stickerConfig!),
      'elements': t.elements.map(_elementToJson).toList(),
    };
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

  Map<String, dynamic> _stickerConfigToJson(StickerConfig c) => {
        'widthMm': c.widthMm,
        'heightMm': c.heightMm,
        'cornerRadiusMm': c.cornerRadiusMm,
        'printableArea': c.printableArea.map((p) => {'x': p.x, 'y': p.y}).toList(),
      };

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
}
