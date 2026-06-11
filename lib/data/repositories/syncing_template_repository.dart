import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/data/repositories/firestore_template_repository.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [TemplateRepository] implementing local caching and manual synchronization.
class SyncingTemplateRepository implements TemplateRepository {
  /// Creates a [SyncingTemplateRepository] instance.
  SyncingTemplateRepository({
    required DatabaseTemplateRepository local,
    required AuthService auth,
    required RemoteDatabaseService remoteDb,
    required LocalDatabase localDatabase,
  })  : _local = local,
        _auth = auth,
        _remoteDb = remoteDb,
        _localDb = localDatabase;

  final DatabaseTemplateRepository _local;
  final AuthService _auth;
  final RemoteDatabaseService _remoteDb;
  final LocalDatabase _localDb;

  FirestoreTemplateRepository? get _remote {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreTemplateRepository(remoteDb: _remoteDb, userId: uid);
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
        await remoteRepo.createTemplate(name);
      } on Object catch (_) {
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
      } on Object catch (_) {
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
      } on Object catch (_) {
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
      } on Object catch (_) {
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
      } on Object catch (_) {
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
      } on Object catch (_) {
        // Fallback
      }
    }
  }

  /// Pulls all templates from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreTemplateRepository(remoteDb: _remoteDb, userId: uid);
    final remoteTemplates = await remoteRepo.fetchTemplates();

    // Clear local cache
    final localTemplates = await _local.fetchTemplates();
    for (final t in localTemplates) {
      await _local.deleteTemplate(t.id);
    }

    // Overwrite local cache with remote data (preserving original IDs)
    for (final t in remoteTemplates) {
      await _localDb.save<LabelTemplateHiveModel>(
        'templates',
        t.id,
        LabelTemplateHiveModel.fromDomain(t),
      );
    }
  }
}
