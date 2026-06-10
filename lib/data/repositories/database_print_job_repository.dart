import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

class DatabasePrintJobRepository implements PrintJobRepository {
  DatabasePrintJobRepository({required DocumentDatabase database}) : _db = database;

  final DocumentDatabase _db;
  static const String _collection = 'print_jobs';

  @override
  Future<void> savePrintJob(PrintJob job) async {
    await _db.save(_collection, job.id, _jobToJson(job));
  }

  @override
  Future<List<PrintJob>> getRecentJobs({int limit = 10}) async {
    final allData = await _db.getAll(_collection);
    final list = allData.map(_jobFromJson).toList()
      ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
    return list.take(limit).toList();
  }

  @override
  Future<List<PrintJob>> getJobsBySku(String sku) async {
    final allData = await _db.getAll(_collection);
    return allData
        .map(_jobFromJson)
        .where((j) => j.sku == sku)
        .toList();
  }

  Map<String, dynamic> _jobToJson(PrintJob j) {
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

  PrintJob _jobFromJson(Map<String, dynamic> json) {
    return PrintJob(
      id: json['id'] as String,
      productName: json['productName'] as String,
      sku: json['sku'] as String,
      status: PrintJobStatus.values.firstWhere((e) => e.name == json['status']),
      printerStation: json['printerStation'] as String,
      printedAt: DateTime.parse(json['printedAt'] as String),
      labelCount: json['labelCount'] as int,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}
