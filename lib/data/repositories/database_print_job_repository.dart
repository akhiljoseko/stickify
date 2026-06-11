import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

/// Local storage implementation of [PrintJobRepository] backed by [LocalDatabase].
class DatabasePrintJobRepository implements PrintJobRepository {
  /// Creates a [DatabasePrintJobRepository] instance.
  DatabasePrintJobRepository({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'print_jobs';

  @override
  Future<void> savePrintJob(PrintJob job) async {
    await _db.save<PrintJobHiveModel>(
      _collection,
      job.id,
      PrintJobHiveModel.fromDomain(job),
    );
  }

  @override
  Future<List<PrintJob>> getRecentJobs({int limit = 10}) async {
    final allModels = await _db.getAll<PrintJobHiveModel>(_collection);
    final list = allModels.map((m) => m.toDomain()).toList()
      ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
    return list.take(limit).toList();
  }

  @override
  Future<List<PrintJob>> getJobsBySku(String sku) async {
    final allModels = await _db.getAll<PrintJobHiveModel>(_collection);
    return allModels
        .map((m) => m.toDomain())
        .where((j) => j.sku == sku)
        .toList()
        ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
  }
}
