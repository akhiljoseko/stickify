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
  Future<List<PrintJob>> getRecentJobs({int limit = 10});

  /// Returns all print jobs associated with a specific product [sku].
  Future<List<PrintJob>> getJobsBySku(String sku);
}
