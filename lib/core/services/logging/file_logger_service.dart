import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stickify/core/services/logging/logger_service.dart';

/// Concrete [LoggerService] that persists records to local files on disk.
/// Handles daily rolling and size-based rolling (exceeding 5MB), keeping up to 5 historical log files.
class FileLoggerService implements LoggerService {
  /// Creates a [FileLoggerService] instance.
  FileLoggerService({this.logDirOverride});

  /// Optional override for the log directory, useful for testing.
  final Directory? logDirOverride;
  static const int _maxFileSize = 5 * 1024 * 1024; // 5 MB
  Directory? _logDir;
  File? _currentLogFile;
  Future<void> _writeQueue = Future.value();

  @override
  Future<void> init() async {
    try {
      _logDir = logDirOverride ?? await getApplicationSupportDirectory();
      _currentLogFile = File('${_logDir!.path}/app.log');
      
      // Perform initial check/rolling on startup
      await _checkAndRollIfNeeded();
    } catch (e) {
      // Fail silently or write to stderr as fallback
      stderr.writeln('Failed to initialize FileLoggerService: $e');
    }
  }

  @override
  void log(LogRecord record) {
    if (_currentLogFile == null) return;

    // Queue the writes sequentially to avoid concurrent file lock/access issues
    _writeQueue = _writeQueue.then((_) async {
      try {
        await _checkAndRollIfNeeded();
        final logLine = _formatRecord(record);
        await _currentLogFile!.writeAsString(
          logLine,
          mode: FileMode.append,
          flush: true,
        );
      } catch (e) {
        stderr.writeln('Error writing log to file: $e');
      }
    });
  }

  String _formatRecord(LogRecord record) {
    final prefix = switch (record.level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
      LogLevel.fatal => '[FATAL]',
    };
    final tagStr = record.tag != null ? ' (${record.tag})' : '';
    final base = '${record.timestamp.toIso8601String()} $prefix$tagStr: ${record.message}';
    final errStr = record.error != null ? '\nError: ${record.error}' : '';
    final stackStr = record.stackTrace != null ? '\nStackTrace: ${record.stackTrace}' : '';
    return '$base$errStr$stackStr\n';
  }

  Future<void> _checkAndRollIfNeeded() async {
    if (_currentLogFile == null || _logDir == null) return;

    final fileExists = _currentLogFile!.existsSync();
    if (!fileExists) return;

    final now = DateTime.now();
    final lastModified = _currentLogFile!.lastModifiedSync();
    final length = _currentLogFile!.lengthSync();

    final dayChanged = now.year != lastModified.year ||
        now.month != lastModified.month ||
        now.day != lastModified.day;

    final sizeExceeded = length >= _maxFileSize;

    if (dayChanged || sizeExceeded) {
      await _rollFiles();
    }
  }

  Future<void> _rollFiles() async {
    if (_logDir == null || _currentLogFile == null) return;

    final path = _logDir!.path;

    // Delete the oldest file if it exists, since we only keep up to 5 backups
    final oldest = File('$path/app_5.log');
    if (oldest.existsSync()) {
      await oldest.delete();
    }

    // Rename backups down the line (app_4 -> app_5, etc.)
    for (var i = 4; i >= 1; i--) {
      final file = File('$path/app_$i.log');
      if (file.existsSync()) {
        final dest = File('$path/app_${i + 1}.log');
        if (dest.existsSync()) {
          await dest.delete();
        }
        await file.rename(dest.path);
      }
    }

    // Rename current log file to app_1.log
    if (_currentLogFile!.existsSync()) {
      final dest = File('$path/app_1.log');
      if (dest.existsSync()) {
        await dest.delete();
      }
      await _currentLogFile!.rename(dest.path);
    }

    // Re-instantiate the main log file
    _currentLogFile = File('$path/app.log');
  }
}
