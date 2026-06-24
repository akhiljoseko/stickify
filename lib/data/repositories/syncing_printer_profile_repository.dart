import 'dart:developer' as developer;
import 'package:stickify/core/core.dart';
import 'package:stickify/data/repositories/syncing_base.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [PrinterProfileRepository] implementing local caching and manual synchronization.
class SyncingPrinterProfileRepository with SyncableRepository<PrinterProfile>
    implements SyncablePrinterProfileRepository {
  /// Creates a [SyncingPrinterProfileRepository] instance.
  SyncingPrinterProfileRepository({
    required this.local,
    required this.syncQueue,
    this.remote,
  });

  /// The local printer profile repository.
  final PrinterProfileRepository local;

  /// The sync queue service.
  final SyncQueue syncQueue;

  /// The remote printer profile repository.
  PrinterProfileRepository? remote;

  static const String _collection = 'printer_profiles';

  @override
  Future<Result<PrinterProfile?, AppError>> getProfileById(String id) async {
    return local.getProfileById(id);
  }

  @override
  Future<Result<List<PrinterProfile>, AppError>> getAllProfiles() async {
    return local.getAllProfiles();
  }

  @override
  Future<Result<void, AppError>> saveProfile(PrinterProfile profile) async {
    developer.log(
      'saveProfile: Saving profile. ID: ${profile.id}, Name: ${profile.displayName}',
      name: 'SYNC_DEBUG',
    );
    return executeSyncMutation(
      localCall: () => local.saveProfile(profile),
      remoteCall: remote != null ? () => remote!.saveProfile(profile) : null,
      syncQueue: syncQueue,
      collection: _collection,
      id: profile.id,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> deleteProfile(String id) async {
    developer.log(
      'deleteProfile: Deleting profile. ID: $id',
      name: 'SYNC_DEBUG',
    );
    return executeSyncMutation(
      localCall: () => local.deleteProfile(id),
      remoteCall: remote != null ? () => remote!.deleteProfile(id) : null,
      syncQueue: syncQueue,
      collection: _collection,
      id: id,
      action: SyncAction.delete,
    );
  }

  /// Pulls all printer profiles from Firestore and overwrites the local cache.
  @override
  Future<Result<void, AppError>> sync(String uid) async {
    developer.log(
      'sync: Starting synchronization of printer profiles for user: $uid',
      name: 'SYNC_DEBUG',
    );
    if (remote == null) {
      return const Result.failure(
        UnexpectedError(
          message:
              'Cannot sync printer profiles: remote repository is not configured.',
        ),
      );
    }

    try {
      // 1. Process pending changes in sync queue for printer profiles
      developer.log(
        'sync: Retrieving pending items from sync queue.',
        name: 'SYNC_DEBUG',
      );
      final pendingResult = await syncQueue.getPending();
      final List<SyncOperation> profileQueue;
      switch (pendingResult) {
        case Success(value: final pending):
          profileQueue = pending
              .where((entry) => entry.collection == _collection)
              .toList();
        case Failure(error: final err):
          return Result.failure(err);
      }
      developer.log(
        'sync: Pending printer profile changes to process: ${profileQueue.length}',
        name: 'SYNC_DEBUG',
      );

      for (final entry in profileQueue) {
        developer.log(
          'sync: Processing queue entry. Key: ${entry.collection}_${entry.id}, Action: ${entry.action}',
          name: 'SYNC_DEBUG',
        );

        if (entry.action == SyncAction.save) {
          final localResult = await local.getProfileById(entry.id);
          switch (localResult) {
            case Success(value: final profile):
              if (profile != null) {
                developer.log(
                  'sync: Found profile locally. Uploading to remote. ID: ${entry.id}',
                  name: 'SYNC_DEBUG',
                );
                final remoteResult = await remote!.saveProfile(profile);
                if (remoteResult is Failure) {
                  return remoteResult;
                }
              } else {
                developer.log(
                  'sync: Profile not found locally. Skipping upload. ID: ${entry.id}',
                  name: 'SYNC_DEBUG',
                );
              }
            case Failure(error: final err):
              return Result.failure(err);
          }
        } else if (entry.action == SyncAction.delete) {
          developer.log(
            'sync: Deleting profile on remote. ID: ${entry.id}',
            name: 'SYNC_DEBUG',
          );
          final remoteResult = await remote!.deleteProfile(entry.id);
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        developer.log(
          'sync: Removing sync queue entry for key: ${entry.collection}_${entry.id}',
          name: 'SYNC_DEBUG',
        );
        await syncQueue.complete(entry);
      }

      // 2. Pull from remote and overwrite local
      developer.log(
        'sync: Fetching remote printer profiles.',
        name: 'SYNC_DEBUG',
      );
      final remoteResult = await remote!.getAllProfiles();
      switch (remoteResult) {
        case Success(value: final remoteProfiles):
          developer.log(
            'sync: Retrieved ${remoteProfiles.length} profiles from remote.',
            name: 'SYNC_DEBUG',
          );

          // Clear local cache
          developer.log(
            'sync: Clearing local printer profiles cache.',
            name: 'SYNC_DEBUG',
          );
          final localProfilesResult = await local.getAllProfiles();
          switch (localProfilesResult) {
            case Success(value: final localProfiles):
              for (final p in localProfiles) {
                final deleteResult = await local.deleteProfile(p.id);
                if (deleteResult is Failure) {
                  return deleteResult;
                }
              }
            case Failure(error: final err):
              return Result.failure(err);
          }

          // Populate local cache with remote documents
          developer.log(
            'sync: Populating local database with remote printer profiles.',
            name: 'SYNC_DEBUG',
          );
          for (final p in remoteProfiles) {
            final saveResult = await local.saveProfile(p);
            if (saveResult is Failure) {
              return saveResult;
            }
          }
          developer.log(
            'sync: Printer profiles synchronization completed successfully.',
            name: 'SYNC_DEBUG',
          );
          return const Result.success(null);

        case Failure(error: final err):
          return Result.failure(err);
      }
    } catch (e, stackTrace) {
      return Result.failure(
        UnexpectedError(
          message: 'Sync process failed unexpectedly.',
          originalError: e,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
