import 'package:stickify/core/core.dart';
import 'package:stickify/data/repositories/syncing_base.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [TemplateRepository] implementing local caching and manual synchronization.
class SyncingTemplateRepository with SyncableRepository<LabelTemplate> implements SyncableTemplateRepository {
  /// Creates a [SyncingTemplateRepository] instance.
  SyncingTemplateRepository({
    required this.local,
    required this.syncQueue,
    this.remote,
  });

  /// The local template repository.
  final TemplateRepository local;

  /// The sync queue service.
  final SyncQueue syncQueue;

  /// The remote template repository.
  TemplateRepository? remote;

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
        final syncResult = await executeSyncMutation(
          localCall: () async => Result.success(template),
          remoteCall: remote != null ? () => remote!.saveTemplate(template) : null,
          syncQueue: syncQueue,
          collection: 'templates',
          id: template.id,
          action: SyncAction.save,
        );
        switch (syncResult) {
          case Success():
            return Result.success(template);
          case Failure(error: final err):
            return Result.failure(err);
        }
      case Failure(error: final err):
        return Result.failure(err);
    }
  }

  @override
  Future<Result<void, AppError>> saveSheetConfig(String templateId, SheetConfig config) async {
    return executeSyncMutation(
      localCall: () => local.saveSheetConfig(templateId, config),
      remoteCall: remote != null
          ? () async {
              final updatedResult = await local.fetchTemplate(templateId);
              switch (updatedResult) {
                case Success(value: final template):
                  return remote!.saveTemplate(template);
                case Failure(error: final err):
                  return Result.failure(err);
              }
            }
          : null,
      syncQueue: syncQueue,
      collection: 'templates',
      id: templateId,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> saveStickerConfig(String templateId, StickerConfig config) async {
    return executeSyncMutation(
      localCall: () => local.saveStickerConfig(templateId, config),
      remoteCall: remote != null
          ? () async {
              final updatedResult = await local.fetchTemplate(templateId);
              switch (updatedResult) {
                case Success(value: final template):
                  return remote!.saveTemplate(template);
                case Failure(error: final err):
                  return Result.failure(err);
              }
            }
          : null,
      syncQueue: syncQueue,
      collection: 'templates',
      id: templateId,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> saveElements(String templateId, List<ElementBlueprint> elements) async {
    return executeSyncMutation(
      localCall: () => local.saveElements(templateId, elements),
      remoteCall: remote != null
          ? () async {
              final updatedResult = await local.fetchTemplate(templateId);
              switch (updatedResult) {
                case Success(value: final template):
                  return remote!.saveTemplate(template);
                case Failure(error: final err):
                  return Result.failure(err);
              }
            }
          : null,
      syncQueue: syncQueue,
      collection: 'templates',
      id: templateId,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> finalizeTemplate(String templateId) async {
    return executeSyncMutation(
      localCall: () => local.finalizeTemplate(templateId),
      remoteCall: remote != null
          ? () async {
              final updatedResult = await local.fetchTemplate(templateId);
              switch (updatedResult) {
                case Success(value: final template):
                  return remote!.saveTemplate(template);
                case Failure(error: final err):
                  return Result.failure(err);
              }
            }
          : null,
      syncQueue: syncQueue,
      collection: 'templates',
      id: templateId,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> saveTemplate(LabelTemplate template) async {
    return executeSyncMutation(
      localCall: () => local.saveTemplate(template),
      remoteCall: remote != null ? () => remote!.saveTemplate(template) : null,
      syncQueue: syncQueue,
      collection: 'templates',
      id: template.id,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> deleteTemplate(String id) async {
    return executeSyncMutation(
      localCall: () => local.deleteTemplate(id),
      remoteCall: remote != null ? () => remote!.deleteTemplate(id) : null,
      syncQueue: syncQueue,
      collection: 'templates',
      id: id,
      action: SyncAction.delete,
    );
  }

  /// Pulls all templates from Firestore and overwrites the local cache.
  @override
  Future<Result<void, AppError>> sync(String uid) async {
    if (remote == null) {
      return const Result.failure(
        UnexpectedError(
          message: 'Cannot sync templates: remote repository is not configured.',
        ),
      );
    }

    try {
      // 1. Process pending changes in sync queue for templates
      final pendingResult = await syncQueue.getPending();
      final List<SyncOperation> templateQueue;
      switch (pendingResult) {
        case Success(value: final pending):
          templateQueue = pending
              .where((entry) => entry.collection == 'templates')
              .toList();
        case Failure(error: final err):
          return Result.failure(err);
      }

      for (final entry in templateQueue) {
        if (entry.action == SyncAction.save) {
          final localResult = await local.fetchTemplate(entry.id);
          switch (localResult) {
            case Success(value: final template):
              final remoteResult = await remote!.saveTemplate(template);
              if (remoteResult is Failure) {
                return remoteResult;
              }
            case Failure(error: final err):
              return Result.failure(err);
          }
        } else if (entry.action == SyncAction.delete) {
          final remoteResult = await remote!.deleteTemplate(entry.id);
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        await syncQueue.complete(entry);
      }

      // 2. Pull from remote and overwrite local
      final remoteResult = await remote!.fetchTemplates();
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
            final saveResult = await local.saveTemplate(t);
            if (saveResult is Failure) {
              return saveResult;
            }
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
