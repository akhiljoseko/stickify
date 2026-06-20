import 'dart:developer' as developer;
import 'package:stickify/core/services/logging/logger_service.dart';

/// concrete [LoggerService] that formats and outputs records to the developer console.
class ConsoleLoggerService implements LoggerService {
  /// Creates a [ConsoleLoggerService] instance.
  const ConsoleLoggerService();

  @override
  Future<void> init() async {
    // No initialization needed for Console output
  }

  @override
  void log(LogRecord record) {
    // Map LogLevel to an integer code for developer log levels
    // Typically, higher values indicate higher severity
    final rawLevel = switch (record.level) {
      LogLevel.debug => 500,
      LogLevel.info => 800,
      LogLevel.warning => 900,
      LogLevel.error => 1000,
      LogLevel.fatal => 1200,
    };

    developer.log(
      record.message,
      time: record.timestamp,
      level: rawLevel,
      name: record.tag ?? 'App',
      error: record.error,
      stackTrace: record.stackTrace,
    );
  }
}
