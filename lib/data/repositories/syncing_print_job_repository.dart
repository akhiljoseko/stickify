import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/data/repositories/syncing_base.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [PrintJobRepository] implementing local caching and manual synchronization.
class SyncingPrintJobRepository with SyncableRepository<PrintJob> implements SyncablePrintJobRepository {
  /// Creates a [SyncingPrintJobRepository] instance.
  SyncingPrintJobRepository({
    required this.local,
    required this.syncQueue,
    required this.localDatabase,
    this.remote,
  });

  /// The local print job repository.
  final PrintJobRepository local;

  /// The sync queue service.
  final SyncQueue syncQueue;

  /// The local database service interface.
  final LocalDatabase localDatabase;

  /// The remote print job repository.
  PrintJobRepository? remote;

  @override
  Future<Result<void, AppError>> savePrintJob(PrintJob job) async {
    return executeSyncMutation(
      localCall: () => local.savePrintJob(job),
      remoteCall: remote != null ? () => remote!.savePrintJob(job) : null,
      syncQueue: syncQueue,
      collection: 'print_jobs',
      id: job.id,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getRecentJobs({int limit = 10}) async {
    return local.getRecentJobs(limit: limit);
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getJobsByVariantSku(String variantSku) async {
    return local.getJobsByVariantSku(variantSku);
  }

  /// Pulls all print jobs from Firestore and overwrites the local cache.
  @override
  Future<Result<void, AppError>> sync(String uid) async {
    if (remote == null) {
      return const Result.failure(
        UnexpectedError(
          message: 'Cannot sync print jobs: remote repository is not configured.',
        ),
      );
    }

    try {
      // 1. Process pending changes in sync queue for print jobs
      final pendingResult = await syncQueue.getPending();
      final List<SyncOperation> printJobQueue;
      switch (pendingResult) {
        case Success(value: final pending):
          printJobQueue = pending
              .where((entry) => entry.collection == 'print_jobs')
              .toList();
        case Failure(error: final err):
          return Result.failure(err);
      }

      for (final entry in printJobQueue) {
        final model = await localDatabase.get<PrintJobHiveModel>('print_jobs', entry.id);
        if (model != null) {
          final remoteResult = await remote!.savePrintJob(model.toDomain());
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        await syncQueue.complete(entry);
      }

      // 2. Pull from remote and overwrite local
      final remoteResult = await remote!.getRecentJobs(limit: 1000);
      switch (remoteResult) {
        case Success(value: final remoteJobs):
          // Clear local cache
          final localJobsResult = await local.getRecentJobs(limit: 1000);
          switch (localJobsResult) {
            case Success(value: final localJobs):
              for (final j in localJobs) {
                await localDatabase.delete('print_jobs', j.id);
              }
            case Failure(error: final err):
              return Result.failure(err);
          }

          // Overwrite local cache with remote logs
          for (final j in remoteJobs) {
            final saveResult = await local.savePrintJob(j);
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
          message: 'Print job synchronization failed unexpectedly.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
