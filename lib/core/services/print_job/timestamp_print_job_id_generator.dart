import 'package:stickify/domain/domain.dart';

/// Concrete implementation of [PrintJobIdGenerator] that generates IDs based on
/// the current timestamp in milliseconds.
class TimestampPrintJobIdGenerator implements PrintJobIdGenerator {
  const TimestampPrintJobIdGenerator();

  @override
  String generateId() {
    return 'job-${DateTime.now().millisecondsSinceEpoch}';
  }
}
