import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/core/services/remote_database_service.dart';
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

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.savePrintJob(job);
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
