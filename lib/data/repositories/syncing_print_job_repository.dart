import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/firestore_print_job_repository.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

/// Syncing wrapper for [PrintJobRepository] implementing local caching and manual synchronization.
class SyncingPrintJobRepository implements PrintJobRepository {
  /// Creates a [SyncingPrintJobRepository] instance.
  SyncingPrintJobRepository({
    required DatabasePrintJobRepository local,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required DocumentDatabase localDatabase,
  })  : _local = local,
        _auth = auth,
        _firestore = firestore,
        _localDb = localDatabase;

  final DatabasePrintJobRepository _local;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final DocumentDatabase _localDb;

  FirestorePrintJobRepository? get _remote {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestorePrintJobRepository(firestore: _firestore, userId: uid);
  }

  @override
  Future<void> savePrintJob(PrintJob job) async {
    // 1. Write locally
    await _local.savePrintJob(job);

    // 2. Automatically push to remote Firestore if logged in
    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.savePrintJob(job);
      } catch (_) {
        // Fallback
      }
    }
  }

  @override
  Future<List<PrintJob>> getRecentJobs({int limit = 10}) async {
    return _local.getRecentJobs(limit: limit);
  }

  @override
  Future<List<PrintJob>> getJobsBySku(String sku) async {
    return _local.getJobsBySku(sku);
  }

  /// Pulls all print jobs from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestorePrintJobRepository(firestore: _firestore, userId: uid);
    final remoteJobs = await remoteRepo.getRecentJobs(limit: 1000); // Fetch a large range to catch remote logs

    // Clear local cache
    final localJobs = await _local.getRecentJobs(limit: 1000);
    for (final j in localJobs) {
      await _localDb.delete('print_jobs', j.id);
    }

    // Overwrite local cache with remote logs
    for (final j in remoteJobs) {
      await _localDb.save('print_jobs', j.id, _localJobToJson(j));
    }
  }

  Map<String, dynamic> _localJobToJson(PrintJob j) {
    return {
      'id': j.id,
      'productName': j.productName,
      'sku': j.sku,
      'status': j.status.name,
      'printerStation': j.printerStation,
      'printedAt': j.printedAt.toIso8601String(),
      'labelCount': j.labelCount,
      'isVerified': j.isVerified,
    };
  }
}
