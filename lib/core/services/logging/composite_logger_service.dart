import 'package:stickify/core/services/logging/logger_service.dart';

/// Concrete [LoggerService] that broadcasts [LogRecord]s to multiple child loggers.
class CompositeLoggerService implements LoggerService {
  /// Creates a [CompositeLoggerService] with a list of child [loggers].
  const CompositeLoggerService(this.loggers);

  /// The list of child loggers that will receive log records.
  final List<LoggerService> loggers;

  @override
  Future<void> init() async {
    // Initialize all child loggers in parallel
    await Future.wait(loggers.map((logger) => logger.init()));
  }

  @override
  void log(LogRecord record) {
    for (final logger in loggers) {
      logger.log(record);
    }
  }
}
