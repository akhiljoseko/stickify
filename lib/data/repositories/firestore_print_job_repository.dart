import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/firestore/print_job_firestore_model.dart';
import 'package:stickify/domain/domain.dart';

/// Remote repository implementation of [PrintJobRepository] backed by [RemoteDatabaseService].
class FirestorePrintJobRepository implements PrintJobRepository {
  /// Creates a [FirestorePrintJobRepository] instance.
  FirestorePrintJobRepository({
    required this.remoteDb,
    required this.userId,
  });

  /// The abstract remote database service.
  final RemoteDatabaseService remoteDb;

  /// The unique identifier of the authenticated user.
  final String userId;

  String get _collectionPath => 'users/$userId/print_jobs';

  @override
  Future<Result<void, AppError>> savePrintJob(PrintJob job) async {
    try {
      await remoteDb.setData(
        '$_collectionPath/${job.id}',
        PrintJobFirestoreModel.fromDomain(job).toMap(),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to upload print job to remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getRecentJobs({int limit = 10}) async {
    try {
      final list = await remoteDb.getCollection(
        _collectionPath,
        orderBy: 'printedAt',
        descending: true,
        limit: limit,
      );
      final mapped = list.map((json) {
        return PrintJobFirestoreModel.fromMap(json['id'] as String, json).toDomain();
      }).toList();
      return Result.success(mapped);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to fetch recent print jobs from remote database.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getJobsByVariantSku(String variantSku) async {
    try {
      final list = await remoteDb.queryCollection(
        _collectionPath,
        field: 'variantSku',
        isEqualTo: variantSku,
      );
      final mapped = list.map((json) {
        return PrintJobFirestoreModel.fromMap(json['id'] as String, json).toDomain();
      }).toList()
        ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
      return Result.success(mapped);
    } catch (e, s) {
      return Result.failure(
        NetworkError(
          message: 'Failed to query remote print jobs for SKU: $variantSku.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
