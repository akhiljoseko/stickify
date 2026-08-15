import 'dart:async';

import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/batch_print_summary.dart';
import 'package:stickify/domain/repositories/batch_print_summary_repository.dart';
import 'package:stickify/domain/services/local_database.dart';

/// Implementation of [BatchPrintSummaryRepository] using [LocalDatabase].
class LocalBatchPrintSummaryRepository implements BatchPrintSummaryRepository {
  /// Creates a [LocalBatchPrintSummaryRepository].
  LocalBatchPrintSummaryRepository({
    required this._database,
  });

  final LocalDatabase _database;
  final StreamController<List<BatchPrintSummary>> _summariesController =
      StreamController<List<BatchPrintSummary>>.broadcast();

  static const _collectionName = 'batch_print_summaries';

  @override
  Stream<List<BatchPrintSummary>> get onSummariesChanged =>
      _summariesController.stream;

  @override
  Future<Result<void, AppError>> saveSummary(BatchPrintSummary summary) async {
    try {
      await _database.save<Map<String, dynamic>>(
        _collectionName,
        summary.id,
        summary.toJson(),
      );
      final recent = await fetchRecentSummaries();
      if (recent is Success<List<BatchPrintSummary>, AppError>) {
        _summariesController.add(recent.value);
      }
      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseError(message: 'Failed to save batch print summary: $e'),
      );
    }
  }

  @override
  Future<Result<List<BatchPrintSummary>, AppError>> fetchRecentSummaries() async {
    try {
      final rawList = await _database.getAll<dynamic>(_collectionName);
      final summaries = <BatchPrintSummary>[];

      for (final item in rawList) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          summaries.add(BatchPrintSummary.fromJson(map));
        }
      }

      summaries.sort((a, b) => b.printedAt.compareTo(a.printedAt));

      return Result.success(summaries);
    } catch (e) {
      return Result.failure(
        DatabaseError(message: 'Failed to fetch recent batch print summaries: $e'),
      );
    }
  }

  @override
  Future<Result<void, AppError>> deleteSummariesOlderThan(Duration duration) async {
    try {
      final rawList = await _database.getAll<dynamic>(_collectionName);
      final cutoff = DateTime.now().subtract(duration);

      for (final item in rawList) {
        if (item is Map) {
          final map = Map<String, dynamic>.from(item);
          final summary = BatchPrintSummary.fromJson(map);
          if (summary.printedAt.isBefore(cutoff)) {
            await _database.delete(_collectionName, summary.id);
          }
        }
      }

      final recent = await fetchRecentSummaries();
      if (recent is Success<List<BatchPrintSummary>, AppError>) {
        _summariesController.add(recent.value);
      }

      return const Result.success(null);
    } catch (e) {
      return Result.failure(
        DatabaseError(message: 'Failed to delete old batch print summaries: $e'),
      );
    }
  }
}
