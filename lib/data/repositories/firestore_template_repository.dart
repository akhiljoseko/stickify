import 'package:stickify/core/core.dart';
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

  Future<LabelTemplate> _getTemplate(String id) async {
    final data = await remoteDb.getData('$_collectionPath/$id');
    if (data == null) {
      throw Exception('Template not found in remote storage: $id');
    }
    return TemplateFirestoreModel.fromMap(id, data).toDomain();
  }

  @override
  Future<Result<List<LabelTemplate>, AppError>> fetchTemplates() async {
    try {
      final list = await remoteDb.getCollection(_collectionPath);
      final mapped = list.map((json) {
        return TemplateFirestoreModel.fromMap(json['id'] as String, json).toDomain();
      }).toList()
        ..sort(
          (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      return Result.success(mapped);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to fetch templates from remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<LabelTemplate, AppError>> fetchTemplate(String id) async {
    try {
      final template = await _getTemplate(id);
      return Result.success(template);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to fetch template from remote database: $id',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<LabelTemplate, AppError>> createTemplate(String name) async {
    try {
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
      return Result.success(template);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to create template on remote database: $name',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> saveSheetConfig(String templateId, SheetConfig config) async {
    try {
      final template = await _getTemplate(templateId);
      final updated = template.copyWith(
        sheetConfig: config,
        updatedAt: DateTime.now(),
      );
      await remoteDb.setData(
        '$_collectionPath/$templateId',
        TemplateFirestoreModel.fromDomain(updated).toMap(),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to save sheet configuration to remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> saveStickerConfig(String templateId, StickerConfig config) async {
    try {
      final template = await _getTemplate(templateId);
      final updated = template.copyWith(
        stickerConfig: config,
        updatedAt: DateTime.now(),
      );
      await remoteDb.setData(
        '$_collectionPath/$templateId',
        TemplateFirestoreModel.fromDomain(updated).toMap(),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to save sticker configuration to remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> saveElements(String templateId, List<ElementBlueprint> elements) async {
    try {
      final template = await _getTemplate(templateId);
      final updated = template.copyWith(
        elements: elements,
        updatedAt: DateTime.now(),
      );
      await remoteDb.setData(
        '$_collectionPath/$templateId',
        TemplateFirestoreModel.fromDomain(updated).toMap(),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to save layout elements to remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> finalizeTemplate(String templateId) async {
    try {
      final template = await _getTemplate(templateId);
      final updated = template.copyWith(
        isFinalized: true,
        updatedAt: DateTime.now(),
      );
      await remoteDb.setData(
        '$_collectionPath/$templateId',
        TemplateFirestoreModel.fromDomain(updated).toMap(),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to finalize template on remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> saveTemplate(LabelTemplate template) async {
    try {
      await remoteDb.setData(
        '$_collectionPath/${template.id}',
        TemplateFirestoreModel.fromDomain(template).toMap(),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to save template to remote database: ${template.name}',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> deleteTemplate(String id) async {
    try {
      await remoteDb.deleteData('$_collectionPath/$id');
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to delete template from remote database: $id',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
