// ignore_for_file: one_member_abstracts

/// Abstract service interface for generating unique print job IDs.
abstract interface class PrintJobIdGenerator {
  /// Generates a unique print job ID.
  String generateId();
}
