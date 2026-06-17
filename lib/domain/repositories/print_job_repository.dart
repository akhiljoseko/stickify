import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/print_job.dart';

/// Abstract repository interface for print job data operations.
///
/// Belongs to the global domain layer. Concrete implementations live in
/// `lib/data/repositories/`. Cubits depend only on this interface,
/// never on the concrete implementation.
abstract interface class PrintJobRepository {
  /// Returns the N most recently completed or in-progress print jobs.
  ///
  /// [limit] controls how many jobs to return (default: 10).
  Future<Result<List<PrintJob>, AppError>> getRecentJobs({int limit = 10});

  /// Returns a paginated list of print jobs before the given [before] timestamp.
  ///
  /// [limit] controls page size (default: 20). Pass [before] as the
  /// [printedAt] of the oldest item on the current page to fetch the next page.
  /// Pass `null` to fetch the first (most recent) page.
  Future<Result<List<PrintJob>, AppError>> getJobsPaginated({
    int limit = 20,
    DateTime? before,
  });

  /// Returns all print jobs associated with a specific product [variantSku].
  Future<Result<List<PrintJob>, AppError>> getJobsByVariantSku(String variantSku);

  /// Saves a print job to the repository database.
  Future<Result<void, AppError>> savePrintJob(PrintJob job);
}
