import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';
import 'package:stickify/domain/domain.dart';

/// Local storage implementation of [TemplateRepository] backed by [LocalDatabase].
class DatabaseTemplateRepository implements TemplateRepository {
  /// Creates a [DatabaseTemplateRepository] instance.
  DatabaseTemplateRepository({required LocalDatabase database})
      : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'templates';

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    final allModels = await _db.getAll<LabelTemplateHiveModel>(_collection);
    final list = allModels.map((m) => m.toDomain()).toList()
      ..sort(
        (a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
      );
    return list;
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    final model = await _db.get<LabelTemplateHiveModel>(_collection, id);
    if (model == null) {
      throw Exception('Template not found: $id');
    }
    return model.toDomain();
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
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
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      sheetConfig: config,
      updatedAt: DateTime.now(),
    );
    await _db.save<LabelTemplateHiveModel>(
      _collection,
      templateId,
      LabelTemplateHiveModel.fromDomain(updated),
    );
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      stickerConfig: config,
      updatedAt: DateTime.now(),
    );
    await _db.save<LabelTemplateHiveModel>(
      _collection,
      templateId,
      LabelTemplateHiveModel.fromDomain(updated),
    );
  }

  @override
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      elements: elements,
      updatedAt: DateTime.now(),
    );
    await _db.save<LabelTemplateHiveModel>(
      _collection,
      templateId,
      LabelTemplateHiveModel.fromDomain(updated),
    );
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    final template = await fetchTemplate(templateId);
    final updated = template.copyWith(
      isFinalized: true,
      updatedAt: DateTime.now(),
    );
    await _db.save<LabelTemplateHiveModel>(
      _collection,
      templateId,
      LabelTemplateHiveModel.fromDomain(updated),
    );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await _db.delete(_collection, id);
  }
}
