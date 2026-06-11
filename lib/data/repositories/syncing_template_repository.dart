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
    final syncKey = 'templates_${template.id}';

    await localDatabase.save('sync_queue', syncKey, {
      'id': template.id,
      'collection': 'templates',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveTemplate(template);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    await local.saveSheetConfig(templateId, config);

    final syncKey = 'templates_$templateId';
    await localDatabase.save('sync_queue', syncKey, {
      'id': templateId,
      'collection': 'templates',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        final updatedTemplate = await local.fetchTemplate(templateId);
        await remoteRepo.saveTemplate(updatedTemplate);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    await local.saveStickerConfig(templateId, config);

    final syncKey = 'templates_$templateId';
    await localDatabase.save('sync_queue', syncKey, {
      'id': templateId,
      'collection': 'templates',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        final updatedTemplate = await local.fetchTemplate(templateId);
        await remoteRepo.saveTemplate(updatedTemplate);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements) async {
    await local.saveElements(templateId, elements);

    final syncKey = 'templates_$templateId';
    await localDatabase.save('sync_queue', syncKey, {
      'id': templateId,
      'collection': 'templates',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        final updatedTemplate = await local.fetchTemplate(templateId);
        await remoteRepo.saveTemplate(updatedTemplate);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    await local.finalizeTemplate(templateId);

    final syncKey = 'templates_$templateId';
    await localDatabase.save('sync_queue', syncKey, {
      'id': templateId,
      'collection': 'templates',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        final updatedTemplate = await local.fetchTemplate(templateId);
        await remoteRepo.saveTemplate(updatedTemplate);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> saveTemplate(LabelTemplate template) async {
    await local.saveTemplate(template);

    final syncKey = 'templates_${template.id}';
    await localDatabase.save('sync_queue', syncKey, {
      'id': template.id,
      'collection': 'templates',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveTemplate(template);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await local.deleteTemplate(id);

    final syncKey = 'templates_$id';
    await localDatabase.save('sync_queue', syncKey, {
      'id': id,
      'collection': 'templates',
      'action': 'delete',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.deleteTemplate(id);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  /// Pulls all templates from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreTemplateRepository(remoteDb: remoteDb, userId: uid);

    // 1. Process pending changes in sync queue for templates
    final allQueue = await localDatabase.getAll<dynamic>('sync_queue');
    final templateQueue = allQueue
        .where((entry) => entry is Map && entry['collection'] == 'templates')
        .cast<Map<dynamic, dynamic>>()
        .toList();

    for (final entry in templateQueue) {
      final id = entry['id'] as String;
      final action = entry['action'] as String;
      final syncKey = 'templates_$id';

      if (action == 'save') {
        try {
          final template = await local.fetchTemplate(id);
          await remoteRepo.saveTemplate(template);
        } on Exception catch (_) {
          // Template might have been deleted locally later, ignore
        }
      } else if (action == 'delete') {
        await remoteRepo.deleteTemplate(id);
      }
      await localDatabase.delete('sync_queue', syncKey);
    }

    // 2. Pull from remote and overwrite local
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
