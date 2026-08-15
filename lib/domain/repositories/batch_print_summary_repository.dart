import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/batch_print_summary.dart';

/// Contract for managing batch print summary persistence and historical retention.
abstract class BatchPrintSummaryRepository {
  /// Saves a new [summary] record.
  Future<Result<void, AppError>> saveSummary(BatchPrintSummary summary);

  /// Retrieves all batch print summaries stored within the retention window,
  /// ordered by `printedAt` descending (most recent first).
  Future<Result<List<BatchPrintSummary>, AppError>> fetchRecentSummaries();

  /// Deletes batch print summaries older than [duration] (e.g. 7 days).
  Future<Result<void, AppError>> deleteSummariesOlderThan(Duration duration);
}
