import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/services/logging/composite_logger_service.dart';
import 'package:stickify/core/services/logging/console_logger_service.dart';
import 'package:stickify/core/services/logging/file_logger_service.dart';
import 'package:stickify/core/services/logging/logger_service.dart';

class MockLoggerService implements LoggerService {
  final List<LogRecord> loggedRecords = [];
  bool isInitialized = false;

  @override
  Future<void> init() async {
    isInitialized = true;
  }

  @override
  void log(LogRecord record) {
    loggedRecords.add(record);
  }
}

void main() {
  group('Logging Framework Unit Tests', () {
    test('LogRecord toString formats correctly', () {
      final timestamp = DateTime(2026, 6, 20, 12, 34, 56);
      final record = LogRecord(
        timestamp: timestamp,
        level: LogLevel.info,
        message: 'Test message',
        tag: 'Database',
      );

      final str = record.toString();
      expect(str, contains('2026-06-20T12:34:56.000'));
      expect(str, contains('[INFO]'));
      expect(str, contains('(Database)'));
      expect(str, contains('Test message'));
    });

    test('LogRecord toString with error and stack trace formatting', () {
      final timestamp = DateTime(2026, 6, 20, 12, 34, 56);
      final record = LogRecord(
        timestamp: timestamp,
        level: LogLevel.error,
        message: 'Failed to connect',
        tag: 'Network',
        error: 'TimeoutException',
        stackTrace: StackTrace.fromString('stack_trace_line_1'),
      );

      final str = record.toString();
      expect(str, contains('2026-06-20T12:34:56.000'));
      expect(str, contains('[ERROR]'));
      expect(str, contains('(Network)'));
      expect(str, contains('Failed to connect'));
      expect(str, contains('Error: TimeoutException'));
      expect(str, contains('StackTrace: stack_trace_line_1'));
    });

    test('Log filters logs below the configured minLevel', () {
      final mockLogger = MockLoggerService();
      Log.initialize(logger: mockLogger, minLevel: LogLevel.warning);

      Log.debug('Debug msg');
      Log.info('Info msg');
      Log.warning('Warning msg');
      Log.error('Error msg');
      Log.fatal('Fatal msg');

      expect(mockLogger.loggedRecords.length, 3);
      expect(mockLogger.loggedRecords[0].level, LogLevel.warning);
      expect(mockLogger.loggedRecords[0].message, 'Warning msg');
      expect(mockLogger.loggedRecords[1].level, LogLevel.error);
      expect(mockLogger.loggedRecords[2].level, LogLevel.fatal);
    });

    test('ConsoleLoggerService logs without error', () async {
      const consoleLogger = ConsoleLoggerService();
      await consoleLogger.init();
      
      // Should run successfully without throwing exceptions
      consoleLogger.log(
        LogRecord(
          timestamp: DateTime.now(),
          level: LogLevel.info,
          message: 'Hello Console Log',
        ),
      );
    });

    test('CompositeLoggerService broadcasts logs to all child loggers', () async {
      final child1 = MockLoggerService();
      final child2 = MockLoggerService();
      final composite = CompositeLoggerService([child1, child2]);

      await composite.init();
      expect(child1.isInitialized, isTrue);
      expect(child2.isInitialized, isTrue);

      final record = LogRecord(
        timestamp: DateTime.now(),
        level: LogLevel.debug,
        message: 'Broadcasting message',
      );
      composite.log(record);

      expect(child1.loggedRecords.length, 1);
      expect(child1.loggedRecords.first.message, 'Broadcasting message');
      expect(child2.loggedRecords.length, 1);
      expect(child2.loggedRecords.first.message, 'Broadcasting message');
    });

    group('FileLoggerService Tests', () {
      late Directory tempDir;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('stickify_logging_test');
      });

      tearDown(() async {
        if (tempDir.existsSync()) {
          try {
            await tempDir.delete(recursive: true);
          } catch (_) {}
        }
      });

      test('FileLoggerService writes log records to app.log', () async {
        final fileLogger = FileLoggerService(logDirOverride: tempDir);
        await fileLogger.init();

        final record = LogRecord(
          timestamp: DateTime.now(),
          level: LogLevel.warning,
          message: 'Local warning message',
          tag: 'TestTag',
        );

        fileLogger.log(record);

        // Wait for the sequential queue to execute the writing
        await Future<void>.delayed(const Duration(milliseconds: 100));

        final logFile = File('${tempDir.path}/app.log');
        expect(logFile.existsSync(), isTrue);

        final content = logFile.readAsStringSync();
        expect(content, contains('[WARN]'));
        expect(content, contains('(TestTag)'));
        expect(content, contains('Local warning message'));
      });

      test('FileLoggerService rolls files when size limit exceeded', () async {
        final fileLogger = FileLoggerService(logDirOverride: tempDir);
        await fileLogger.init();

        // Write a mock huge block to trigger rollover
        final logFile = File('${tempDir.path}/app.log');
        
        // Write exactly 5MB of data to the log file to trigger size roll on next log
        final hugeContent = 'A' * (5 * 1024 * 1024);
        logFile.writeAsStringSync(hugeContent);

        // Next log should trigger rolling
        fileLogger.log(
          LogRecord(
            timestamp: DateTime.now(),
            level: LogLevel.info,
            message: 'Roll this log',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 150));

        final rolledFile = File('${tempDir.path}/app_1.log');
        expect(rolledFile.existsSync(), isTrue);
        expect(rolledFile.lengthSync(), 5 * 1024 * 1024);

        final newCurrentLog = File('${tempDir.path}/app.log');
        expect(newCurrentLog.existsSync(), isTrue);
        expect(newCurrentLog.readAsStringSync(), contains('Roll this log'));
      });

      test('FileLoggerService rolls files on daily changes', () async {
        final fileLogger = FileLoggerService(logDirOverride: tempDir);
        await fileLogger.init();

        final yesterday = DateTime.now().subtract(const Duration(hours: 25));
        File('${tempDir.path}/app.log')
          ..writeAsStringSync('Yesterday log content')
          ..setLastModifiedSync(yesterday);

        // Next log should trigger rolling because day changed
        fileLogger.log(
          LogRecord(
            timestamp: DateTime.now(),
            level: LogLevel.info,
            message: 'Today log message',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 150));

        final rolledFile = File('${tempDir.path}/app_1.log');
        expect(rolledFile.existsSync(), isTrue);
        expect(rolledFile.readAsStringSync(), 'Yesterday log content');

        final newCurrentLog = File('${tempDir.path}/app.log');
        expect(newCurrentLog.existsSync(), isTrue);
        expect(newCurrentLog.readAsStringSync(), contains('Today log message'));
      });

      test('FileLoggerService caps backups to maximum of 5 historical files', () async {
        final fileLogger = FileLoggerService(logDirOverride: tempDir);
        await fileLogger.init();

        // Create pre-existing backups app_1.log through app_5.log
        for (var i = 1; i <= 5; i++) {
          File('${tempDir.path}/app_$i.log').writeAsStringSync('Backup $i');
        }

        // Fill current app.log
        final hugeContent = 'A' * (5 * 1024 * 1024);
        File('${tempDir.path}/app.log')
          ..writeAsStringSync('Current log data')
          ..writeAsStringSync(hugeContent);

        // Trigger rollover
        fileLogger.log(
          LogRecord(
            timestamp: DateTime.now(),
            level: LogLevel.info,
            message: 'Roll and delete app_5',
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 200));

        // app_6.log must NOT exist (capped at 5)
        expect(File('${tempDir.path}/app_6.log').existsSync(), isFalse);

        // app_5.log should contain what was previously in app_4.log
        expect(File('${tempDir.path}/app_5.log').readAsStringSync(), 'Backup 4');
        expect(File('${tempDir.path}/app_1.log').lengthSync(), 5 * 1024 * 1024);
        expect(File('${tempDir.path}/app.log').readAsStringSync(), contains('Roll and delete app_5'));
      });
    });
  });
}
