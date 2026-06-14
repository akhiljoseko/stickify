import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/services/printing/windows/windows_paper_validator.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  late WindowsPaperValidator validator;

  setUp(() {
    validator = WindowsPaperValidator();
  });

  group('WindowsPaperValidator Tests', () {
    test('returns true immediately on non-Windows platforms', () async {
      // We can only force testing the non-Windows check if we are not on Windows,
      // but we can also verify that it compiles and returns true.
      if (!Platform.isWindows) {
        const printer = PrinterDevice(name: 'TestPrinter', url: '');
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

        final result = await validator.isPaperSizeSupported(printer, sheet);
        expect(result, isTrue);
      }
    });

    test('returns true (passes) for standard A4 sheet size on Microsoft Print to PDF', () async {
      if (!Platform.isWindows) return;

      const printer = PrinterDevice(name: 'Microsoft Print to PDF', url: '');
      const sheet = SheetConfig(
        pageWidth: 210, // A4 Width
        pageHeight: 297, // A4 Height
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );

      final result = await validator.isPaperSizeSupported(printer, sheet);
      expect(result, isTrue);
    });

    test('returns false for extremely custom size that is not registered', () async {
      if (!Platform.isWindows) return;

      const printer = PrinterDevice(name: 'Microsoft Print to PDF', url: '');
      const sheet = SheetConfig(
        pageWidth: 888, // Custom large width
        pageHeight: 999, // Custom large height
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );

      final result = await validator.isPaperSizeSupported(printer, sheet);
      expect(result, isFalse);
    });

    test('fail-open: returns true on non-existent printer (since script fails/exits non-zero)', () async {
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

      final result = await validator.isPaperSizeSupported(printer, sheet);
      expect(result, isTrue);
    });
  });
}
