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
    required this.local,
    required this.auth,
    required this.remoteDb,
    required this.localDatabase,
  });

  /// The local template repository.
  final DatabaseTemplateRepository local;

  /// The auth service interface.
  final AuthService auth;

  /// The remote database service interface.
  final RemoteDatabaseService remoteDb;

  /// The local database service interface.
  final LocalDatabase localDatabase;

  FirestoreTemplateRepository? get _remote {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreTemplateRepository(remoteDb: remoteDb, userId: uid);
  }

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    return local.fetchTemplates();
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    return local.fetchTemplate(id);
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
    final template = await local.createTemplate(name);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.createTemplate(name);
      } on Exception catch (_) {
        // Fallback
      }
    }
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    await local.saveSheetConfig(templateId, config);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveSheetConfig(templateId, config);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    await local.saveStickerConfig(templateId, config);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveStickerConfig(templateId, config);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements) async {
    await local.saveElements(templateId, elements);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveElements(templateId, elements);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    await local.finalizeTemplate(templateId);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.finalizeTemplate(templateId);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await local.deleteTemplate(id);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.deleteTemplate(id);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  /// Pulls all templates from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreTemplateRepository(remoteDb: remoteDb, userId: uid);
    final remoteTemplates = await remoteRepo.fetchTemplates();

    // Clear local cache
    final localTemplates = await local.fetchTemplates();
    for (final t in localTemplates) {
      await local.deleteTemplate(t.id);
    }

    // Overwrite local cache with remote data (preserving original IDs)
    for (final t in remoteTemplates) {
      await localDatabase.save<LabelTemplateHiveModel>(
        'templates',
        t.id,
        LabelTemplateHiveModel.fromDomain(t),
      );
    }
  }
}
