import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/services/printing/windows/windows_devmode_manager.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  late WindowsDevModeManager manager;

  setUp(() {
    manager = WindowsDevModeManager();
  });

  group('WindowsDevModeManager Tests', () {
    test('healOnStartup completes without error', () async {
      await expectLater(manager.healOnStartup(), completes);
    });

    test('applySettings returns null on non-existent printer', () async {
      if (!Platform.isWindows) return;

      const printer = PrinterDevice(name: 'NonExistentPrinter12345', url: '');
      const sheet = SheetConfig(
        pageWidth: 100,
        pageHeight: 100,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );

      final token = await manager.applySettings(printer, sheet);
      expect(token, isNull);

      // Clean up the mutex lock
      await manager.restoreSettings(printer, 'NONE');
    });

    test('applySettings succeeds and returns backup token on standard Windows PDF printer', () async {
      if (!Platform.isWindows) return;

      const printer = PrinterDevice(name: 'Microsoft Print to PDF', url: '');
      const sheet = SheetConfig(
        pageWidth: 180,
        pageHeight: 300,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );

      final token = await manager.applySettings(printer, sheet);
      expect(token, isNotNull);

      // Clean up the settings
      await manager.restoreSettings(printer, token!);
    });

    test('mutex blocks concurrent applySettings calls until restoreSettings completes', () async {
      if (!Platform.isWindows) return;

      const printer = PrinterDevice(name: 'Microsoft Print to PDF', url: '');
      const sheet = SheetConfig(
        pageWidth: 180,
        pageHeight: 300,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );

      final stopwatch = Stopwatch()..start();

      final firstToken = await manager.applySettings(printer, sheet);
      expect(firstToken, isNotNull);

      // Launch a restore settings which takes 5 seconds (mocked/delayed)
      final restoreFuture = manager.restoreSettings(printer, firstToken!);

      // Immediate second apply settings should wait until the restore finishes
      final secondToken = await manager.applySettings(printer, sheet);
      stopwatch.stop();

      // Check that the second call waited at least 4.8 seconds
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(4800));

      expect(secondToken, isNotNull);

      // Clean up the second call settings
      await manager.restoreSettings(printer, secondToken!);
      await restoreFuture; // wait for the first restore to finish completely
    });
  });
}
