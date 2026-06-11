import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/data/models/firestore/template_firestore_model.dart';
import 'package:stickify/domain/domain.dart';

/// Remote repository implementation of [TemplateRepository] backed by [RemoteDatabaseService].
class FirestoreTemplateRepository implements TemplateRepository {
  /// Creates a [FirestoreTemplateRepository] instance.
  FirestoreTemplateRepository({
    required this.remoteDb,
    required this.userId,
  });

  /// The abstract remote database service.
  final RemoteDatabaseService remoteDb;

  /// The unique identifier of the authenticated user.
  final String userId;

  String get _collectionPath => 'users/$userId/templates';

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    final list = await remoteDb.getCollection(_collectionPath);
    final mapped = list.map((json) {
      return TemplateFirestoreModel.fromMap(json['id'] as String, json).toDomain();
    }).toList()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return mapped;
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    final data = await remoteDb.getData('$_collectionPath/$id');
    if (data == null) {
      throw Exception('Template not found in remote storage: $id');
    }
    return TemplateFirestoreModel.fromMap(id, data).toDomain();
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
    final id = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final template = LabelTemplate(
      id: id,
      name: name,
      updatedAt: DateTime.now(),
    );
    await remoteDb.setData(
      '$_collectionPath/$id',
      TemplateFirestoreModel.fromDomain(template).toMap(),
    );
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      sheetConfig: config,
      updatedAt: DateTime.now(),
    );
    await remoteDb.setData(
      '$_collectionPath/$templateId',
      TemplateFirestoreModel.fromDomain(updated).toMap(),
    );
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      stickerConfig: config,
      updatedAt: DateTime.now(),
    );
    await remoteDb.setData(
      '$_collectionPath/$templateId',
      TemplateFirestoreModel.fromDomain(updated).toMap(),
    );
  }

  @override
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      elements: elements,
      updatedAt: DateTime.now(),
    );
    await remoteDb.setData(
      '$_collectionPath/$templateId',
      TemplateFirestoreModel.fromDomain(updated).toMap(),
    );
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      isFinalized: true,
      updatedAt: DateTime.now(),
    );
    await remoteDb.setData(
      '$_collectionPath/$templateId',
      TemplateFirestoreModel.fromDomain(updated).toMap(),
    );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await remoteDb.deleteData('$_collectionPath/$id');
  }
}
