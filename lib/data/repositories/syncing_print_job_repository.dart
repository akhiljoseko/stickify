import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/firestore_print_job_repository.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

/// Syncing wrapper for [PrintJobRepository] implementing local caching and manual synchronization.
class SyncingPrintJobRepository implements PrintJobRepository {
  /// Creates a [SyncingPrintJobRepository] instance.
  SyncingPrintJobRepository({
    required this.local,
    required this.auth,
    required this.remoteDb,
    required this.localDatabase,
  });

  /// The local print job repository.
  final DatabasePrintJobRepository local;

  /// The auth service interface.
  final AuthService auth;

  /// The remote database service interface.
  final RemoteDatabaseService remoteDb;

  /// The local database service interface.
  final LocalDatabase localDatabase;

  FirestorePrintJobRepository? get _remote {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestorePrintJobRepository(remoteDb: remoteDb, userId: uid);
  }

  @override
  Future<Result<void, AppError>> savePrintJob(PrintJob job) async {
    final localResult = await local.savePrintJob(job);
    switch (localResult) {
      case Success():
        final syncKey = 'print_jobs_${job.id}';
        await localDatabase.save('sync_queue', syncKey, {
          'id': job.id,
          'collection': 'print_jobs',
          'action': 'save',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });

        final remoteRepo = _remote;
        if (remoteRepo != null) {
          final remoteResult = await remoteRepo.savePrintJob(job);
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
  Future<Result<List<PrintJob>, AppError>> getRecentJobs({int limit = 10}) async {
    return local.getRecentJobs(limit: limit);
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getJobsBySku(String sku) async {
    return local.getJobsBySku(sku);
  }

  /// Pulls all print jobs from Firestore and overwrites the local cache.
  Future<Result<void, AppError>> sync(String uid) async {
    try {
      final remoteRepo = FirestorePrintJobRepository(remoteDb: remoteDb, userId: uid);

      // 1. Process pending changes in sync queue for print jobs
      final allQueue = await localDatabase.getAll<dynamic>('sync_queue');
      final printJobQueue = allQueue
          .where((entry) => entry is Map && entry['collection'] == 'print_jobs')
          .cast<Map<dynamic, dynamic>>()
          .toList();

      for (final entry in printJobQueue) {
        final id = entry['id'] as String;
        final syncKey = 'print_jobs_$id';

        final model = await localDatabase.get<PrintJobHiveModel>('print_jobs', id);
        if (model != null) {
          final remoteResult = await remoteRepo.savePrintJob(model.toDomain());
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        await localDatabase.delete('sync_queue', syncKey);
      }

      // 2. Pull from remote and overwrite local
      final remoteResult = await remoteRepo.getRecentJobs(limit: 1000);
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
