import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';
import 'package:stickify/domain/domain.dart';

/// Local storage implementation of [TemplateRepository] backed by [LocalDatabase].
class DatabaseTemplateRepository implements TemplateRepository {
  /// Creates a [DatabaseTemplateRepository] instance.
  DatabaseTemplateRepository({required LocalDatabase database})
      : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'templates';

  Future<LabelTemplate> _getTemplate(String id) async {
    final model = await _db.get<LabelTemplateHiveModel>(_collection, id);
    if (model == null) {
      throw Exception('Template not found: $id');
    }
    return model.toDomain();
  }

  @override
  Future<Result<List<LabelTemplate>, AppError>> fetchTemplates() async {
    try {
      final allModels = await _db.getAll<LabelTemplateHiveModel>(_collection);
      final list = allModels.map((m) => m.toDomain()).toList()
        ..sort(
          (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
        );
      return Result.success(list);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to fetch templates.',
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
        DatabaseError(
          message: 'Failed to fetch template: $id',
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
      await _db.save<LabelTemplateHiveModel>(
        _collection,
        id,
        LabelTemplateHiveModel.fromDomain(template),
      );
      return Result.success(template);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to create template: $name',
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
      await _db.save<LabelTemplateHiveModel>(
        _collection,
        templateId,
        LabelTemplateHiveModel.fromDomain(updated),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to save sheet configuration.',
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
      await _db.save<LabelTemplateHiveModel>(
        _collection,
        templateId,
        LabelTemplateHiveModel.fromDomain(updated),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to save sticker configuration.',
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
      await _db.save<LabelTemplateHiveModel>(
        _collection,
        templateId,
        LabelTemplateHiveModel.fromDomain(updated),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to save layout elements.',
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
      await _db.save<LabelTemplateHiveModel>(
        _collection,
        templateId,
        LabelTemplateHiveModel.fromDomain(updated),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to finalize template.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> saveTemplate(LabelTemplate template) async {
    try {
      await _db.save<LabelTemplateHiveModel>(
        _collection,
        template.id,
        LabelTemplateHiveModel.fromDomain(template),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to save template: ${template.name}',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<void, AppError>> deleteTemplate(String id) async {
    try {
      await _db.delete(_collection, id);
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to delete template: $id',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
