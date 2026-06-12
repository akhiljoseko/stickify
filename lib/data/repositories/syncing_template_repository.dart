import 'package:stickify/core/core.dart';
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
  Future<Result<List<LabelTemplate>, AppError>> fetchTemplates() async {
    return local.fetchTemplates();
  }

  @override
  Future<Result<LabelTemplate, AppError>> fetchTemplate(String id) async {
    return local.fetchTemplate(id);
  }

  @override
  Future<Result<LabelTemplate, AppError>> createTemplate(String name) async {
    final localResult = await local.createTemplate(name);
    switch (localResult) {
      case Success(value: final template):
        final syncKey = 'templates_${template.id}';

        await localDatabase.save('sync_queue', syncKey, {
          'id': template.id,
          'collection': 'templates',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final remoteResult = await remoteRepo.saveTemplate(template);
          if (remoteResult is Success) {
            await localDatabase.delete('sync_queue', syncKey);
          }
        }
        return Result.success(template);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> saveSheetConfig(String templateId, SheetConfig config) async {
    final localResult = await local.saveSheetConfig(templateId, config);
    switch (localResult) {
      case Success():
        final syncKey = 'templates_$templateId';
        await localDatabase.save('sync_queue', syncKey, {
          'id': templateId,
          'collection': 'templates',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final updatedResult = await local.fetchTemplate(templateId);
          if (updatedResult is Success<LabelTemplate, AppError>) {
            final remoteResult = await remoteRepo.saveTemplate(updatedResult.value);
            if (remoteResult is Success) {
              await localDatabase.delete('sync_queue', syncKey);
            }
          }
        }
        return const Result.success(null);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> saveStickerConfig(String templateId, StickerConfig config) async {
    final localResult = await local.saveStickerConfig(templateId, config);
    switch (localResult) {
      case Success():
        final syncKey = 'templates_$templateId';
        await localDatabase.save('sync_queue', syncKey, {
          'id': templateId,
          'collection': 'templates',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final updatedResult = await local.fetchTemplate(templateId);
          if (updatedResult is Success<LabelTemplate, AppError>) {
            final remoteResult = await remoteRepo.saveTemplate(updatedResult.value);
            if (remoteResult is Success) {
              await localDatabase.delete('sync_queue', syncKey);
            }
          }
        }
        return const Result.success(null);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> saveElements(String templateId, List<ElementBlueprint> elements) async {
    final localResult = await local.saveElements(templateId, elements);
    switch (localResult) {
      case Success():
        final syncKey = 'templates_$templateId';
        await localDatabase.save('sync_queue', syncKey, {
          'id': templateId,
          'collection': 'templates',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final updatedResult = await local.fetchTemplate(templateId);
          if (updatedResult is Success<LabelTemplate, AppError>) {
            final remoteResult = await remoteRepo.saveTemplate(updatedResult.value);
            if (remoteResult is Success) {
              await localDatabase.delete('sync_queue', syncKey);
            }
          }
        }
        return const Result.success(null);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> finalizeTemplate(String templateId) async {
    final localResult = await local.finalizeTemplate(templateId);
    switch (localResult) {
      case Success():
        final syncKey = 'templates_$templateId';
        await localDatabase.save('sync_queue', syncKey, {
          'id': templateId,
          'collection': 'templates',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final updatedResult = await local.fetchTemplate(templateId);
          if (updatedResult is Success<LabelTemplate, AppError>) {
            final remoteResult = await remoteRepo.saveTemplate(updatedResult.value);
            if (remoteResult is Success) {
              await localDatabase.delete('sync_queue', syncKey);
            }
          }
        }
        return const Result.success(null);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> saveTemplate(LabelTemplate template) async {
    final localResult = await local.saveTemplate(template);
    switch (localResult) {
      case Success():
        final syncKey = 'templates_${template.id}';
        await localDatabase.save('sync_queue', syncKey, {
          'id': template.id,
          'collection': 'templates',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final remoteResult = await remoteRepo.saveTemplate(template);
          if (remoteResult is Success) {
            await localDatabase.delete('sync_queue', syncKey);
          }
        }
        return const Result.success(null);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> deleteTemplate(String id) async {
    final localResult = await local.deleteTemplate(id);
    switch (localResult) {
      case Success():
        final syncKey = 'templates_$id';
        await localDatabase.save('sync_queue', syncKey, {
          'id': id,
          'collection': 'templates',
          'action': 'delete',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final remoteResult = await remoteRepo.deleteTemplate(id);
          if (remoteResult is Success) {
            await localDatabase.delete('sync_queue', syncKey);
          }
        }
        return const Result.success(null);

      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  /// Pulls all templates from Firestore and overwrites the local cache.
  Future<Result<void, AppError>> sync(String uid) async {
    try {
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
          final localResult = await local.fetchTemplate(id);
          switch (localResult) {
            case Success(value: final template):
              final remoteResult = await remoteRepo.saveTemplate(template);
              if (remoteResult is Failure) {
                return remoteResult;
              }
            case Failure(error: final err):
              return Result.failure(err);
          }
        } else if (action == 'delete') {
          final remoteResult = await remoteRepo.deleteTemplate(id);
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        await localDatabase.delete('sync_queue', syncKey);
      }

      // 2. Pull from remote and overwrite local
      final remoteResult = await remoteRepo.fetchTemplates();
      switch (remoteResult) {
        case Success(value: final remoteTemplates):
          // Clear local cache
          final localTemplatesResult = await local.fetchTemplates();
          switch (localTemplatesResult) {
            case Success(value: final localTemplates):
              for (final t in localTemplates) {
                final deleteResult = await local.deleteTemplate(t.id);
                if (deleteResult is Failure) {
                  return deleteResult;
                }
              }
            case Failure(error: final err):
              return Result.failure(err);
          }

          // Overwrite local cache with remote data (preserving original IDs)
          for (final t in remoteTemplates) {
            await localDatabase.save<LabelTemplateHiveModel>(
              'templates',
              t.id,
              LabelTemplateHiveModel.fromDomain(t),
            );
          }
          return const Result.success(null);

        case Failure(error: final err):
          return Result.failure(err);
      }
    } catch (e, s) {
      return Result.failure(
        UnexpectedError(
          message: 'Template synchronization failed unexpectedly.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
