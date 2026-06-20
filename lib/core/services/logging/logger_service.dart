import 'dart:async';

/// Defines the severity levels for log records.
enum LogLevel {
  /// Fine-grained informational events that are most useful to debug an application.
  debug,

  /// Informational messages that highlight the progress of the application at coarse-grained level.
  info,

  /// Potentially harmful situations of interest.
  warning,

  /// Error events that might still allow the application to continue running.
  error,

  /// Severe error events that will presumably lead the application to abort.
  fatal,
}

/// A structured container for a single log statement.
class LogRecord {
  /// Creates a [LogRecord] instance.
  const LogRecord({
    required this.timestamp,
    required this.level,
    required this.message,
    this.tag,
    this.error,
    this.stackTrace,
  });

  /// The timestamp of the log event.
  final DateTime timestamp;

  /// The severity of the log event.
  final LogLevel level;

  /// The main message content of the log.
  final String message;

  /// An optional tag to categorize the log source (e.g. 'Auth', 'Database', 'PDF').
  final String? tag;

  /// An optional error object associated with this log.
  final Object? error;

  /// An optional stack trace associated with this log.
  final StackTrace? stackTrace;

  @override
  String toString() {
    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
      LogLevel.fatal => '[FATAL]',
    };
    final tagStr = tag != null ? ' ($tag)' : '';
    final errStr = error != null ? '\nError: $error' : '';
    final stackStr = stackTrace != null ? '\nStackTrace: $stackTrace' : '';
    return '${timestamp.toIso8601String()} $prefix$tagStr: $message$errStr$stackStr';
  }
}

/// Abstract contract for logging implementations.
abstract class LoggerService {
  /// Initializes the logging output (e.g. opening log files, establishing handles).
  Future<void> init();

  /// Logs a structured [LogRecord] to the target destination.
  void log(LogRecord record);
}

/// Global static logging wrapper for convenient use across the application.
class Log {
  Log._();

  static LogLevel _minLevel = LogLevel.info;
  static LoggerService? _logger;

  /// Initializes the global logging helper with a target [logger] implementation
  /// and a minimum severity [minLevel] for filtering logs.
  static void initialize({
    required LoggerService logger,
    LogLevel minLevel = LogLevel.info,
  }) {
    _logger = logger;
    _minLevel = minLevel;
  }

  /// Logs a [LogLevel.debug] message.
  static void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a [LogLevel.info] message.
  static void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a [LogLevel.warning] message.
  static void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a [LogLevel.error] message.
  static void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Logs a [LogLevel.fatal] message.
  static void fatal(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.fatal, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index < _minLevel.index) return;
    final record = LogRecord(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      tag: tag,
      error: error,
      stackTrace: stackTrace,
    );
    _logger?.log(record);
  }
}
