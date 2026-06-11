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
  Future<void> savePrintJob(PrintJob job) async {
    await local.savePrintJob(job);

    final syncKey = 'print_jobs_${job.id}';
    await localDatabase.save('sync_queue', syncKey, {
      'id': job.id,
      'collection': 'print_jobs',
      'action': 'save',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.savePrintJob(job);
        await localDatabase.delete('sync_queue', syncKey);
      } on Exception catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<List<PrintJob>> getRecentJobs({int limit = 10}) async {
    return local.getRecentJobs(limit: limit);
  }

  @override
  Future<List<PrintJob>> getJobsBySku(String sku) async {
    return local.getJobsBySku(sku);
  }

  /// Pulls all print jobs from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
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
        await remoteRepo.savePrintJob(model.toDomain());
      }
      await localDatabase.delete('sync_queue', syncKey);
    }

    // 2. Pull from remote and overwrite local
    final remoteJobs = await remoteRepo.getRecentJobs(limit: 1000);

    // Clear local cache
    final localJobs = await local.getRecentJobs(limit: 1000);
    for (final j in localJobs) {
      await localDatabase.delete('print_jobs', j.id);
    }

    // Overwrite local cache with remote logs using DatabasePrintJobRepository save method
    for (final j in remoteJobs) {
      await local.savePrintJob(j);
    }
  }
}
