import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/domain/domain.dart';

/// Local storage implementation of [PrintJobRepository] backed by [LocalDatabase].
class DatabasePrintJobRepository implements PrintJobRepository {
  /// Creates a [DatabasePrintJobRepository] instance.
  DatabasePrintJobRepository({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'print_jobs';

  @override
  Future<Result<void, AppError>> savePrintJob(PrintJob job) async {
    try {
      await _db.save<PrintJobHiveModel>(
        _collection,
        job.id,
        PrintJobHiveModel.fromDomain(job),
      );
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to save print job locally.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getRecentJobs({int limit = 10}) async {
    try {
      final allModels = await _db.getAll<PrintJobHiveModel>(_collection);
      final list = allModels.map((m) => m.toDomain()).toList()
        ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
      return Result.success(list.take(limit).toList());
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to fetch recent print jobs.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getJobsByVariantSku(String variantSku) async {
    try {
      final allModels = await _db.getAll<PrintJobHiveModel>(_collection);
      final filtered = allModels
          .map((m) => m.toDomain())
          .where((j) => j.variantSku == variantSku)
          .toList()
          ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
      return Result.success(filtered);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to fetch print jobs for SKU: $variantSku.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
