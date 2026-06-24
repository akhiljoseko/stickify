import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrinterCompatibilityIssue Tests', () {
    test('succeeds on valid construction', () {
      const issue = PrinterCompatibilityIssue(
        severity: PrinterCompatibilityStatus.warning,
        code: 'driver_mismatch',
        message: 'A driver mismatch occurred.',
      );

      expect(issue.severity, equals(PrinterCompatibilityStatus.warning));
      expect(issue.code, equals('driver_mismatch'));
      expect(issue.message, equals('A driver mismatch occurred.'));
    });

    test('enforces non-empty code', () {
      expect(
        () => PrinterCompatibilityIssue(
          severity: PrinterCompatibilityStatus.warning,
          code: '',
          message: 'Some message',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('enforces non-empty message', () {
      expect(
        () => PrinterCompatibilityIssue(
          severity: PrinterCompatibilityStatus.warning,
          code: 'some_code',
          message: '',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports Equatable value equality', () {
      const issue1 = PrinterCompatibilityIssue(
        severity: PrinterCompatibilityStatus.warning,
        code: 'driver_mismatch',
        message: 'A driver mismatch occurred.',
      );
      const issue2 = PrinterCompatibilityIssue(
        severity: PrinterCompatibilityStatus.warning,
        code: 'driver_mismatch',
        message: 'A driver mismatch occurred.',
      );
      const issue3 = PrinterCompatibilityIssue(
        severity: PrinterCompatibilityStatus.incompatible,
        code: 'driver_mismatch',
        message: 'A driver mismatch occurred.',
      );

      expect(issue1, equals(issue2));
      expect(issue1, isNot(equals(issue3)));
    });
  });

  group('PrinterProfileCompatibility Tests', () {
    late PrinterProfile dummyProfile;
    late DiscoveredPrinter dummyPrinter;

    setUp(() {
      final now = DateTime(2026, 6, 24);
      dummyProfile = PrinterProfile(
        id: 'profile_1',
        displayName: 'ZT411 Profile',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'Zebra ZT411'),
        capabilities: const PrinterCapabilities(
          supportsCustomPaperSize: true,
          supportsPortraitCustomPaper: true,
          supportsLandscapeCustomPaper: false,
          supportsManualFeed: false,
          supportsBorderlessPrinting: false,
          supportsTraySelection: true,
        ),
        optimizationPreferences: const OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          preferShrinkOverShift: false,
          allowStickerSpecificAdjustment: true,
        ),
        trays: [
          PrinterTrayProfile(
            trayIdentifier: 'tray_1',
            displayName: 'Tray 1',
            supportedPaperConfigurations: const [],
            calibration: PrinterCalibration(
              enabled: false,
              calibrationRules: const [],
            ),
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      dummyPrinter = const DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.online,
      );
    });

    test('succeeds for compatible status with empty issues', () {
      final comp = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.compatible,
        issues: const [],
      );

      expect(comp.status, equals(PrinterCompatibilityStatus.compatible));
      expect(comp.issues, isEmpty);
    });

    test('throws AssertionError for compatible status with issues', () {
      expect(
        () => PrinterProfileCompatibility(
          profile: dummyProfile,
          printer: dummyPrinter,
          status: PrinterCompatibilityStatus.compatible,
          issues: const [
            PrinterCompatibilityIssue(
              severity: PrinterCompatibilityStatus.warning,
              code: 'some_code',
              message: 'some message',
            ),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError for warning status with empty issues', () {
      expect(
        () => PrinterProfileCompatibility(
          profile: dummyProfile,
          printer: dummyPrinter,
          status: PrinterCompatibilityStatus.warning,
          issues: const [],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError for incompatible status with empty issues', () {
      expect(
        () => PrinterProfileCompatibility(
          profile: dummyProfile,
          printer: dummyPrinter,
          status: PrinterCompatibilityStatus.incompatible,
          issues: const [],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws AssertionError for warning status containing incompatible issues', () {
      expect(
        () => PrinterProfileCompatibility(
          profile: dummyProfile,
          printer: dummyPrinter,
          status: PrinterCompatibilityStatus.warning,
          issues: const [
            PrinterCompatibilityIssue(
              severity: PrinterCompatibilityStatus.incompatible,
              code: 'model_mismatch',
              message: 'Model mismatch',
            ),
          ],
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('succeeds for warning status with only warning issues', () {
      final comp = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.warning,
        issues: const [
          PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.warning,
            code: 'driver_mismatch',
            message: 'Driver mismatch',
          ),
        ],
      );

      expect(comp.status, equals(PrinterCompatibilityStatus.warning));
      expect(comp.issues.length, equals(1));
    });

    test('succeeds for incompatible status with at least one incompatible issue', () {
      final comp = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.incompatible,
        issues: const [
          PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.warning,
            code: 'driver_mismatch',
            message: 'Driver mismatch',
          ),
          PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.incompatible,
            code: 'model_mismatch',
            message: 'Model mismatch',
          ),
        ],
      );

      expect(comp.status, equals(PrinterCompatibilityStatus.incompatible));
      expect(comp.issues.length, equals(2));
    });

    test('enforces issues list immutability', () {
      final comp = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.compatible,
        issues: const [],
      );

      expect(
        () => comp.issues.add(
          const PrinterCompatibilityIssue(
            severity: PrinterCompatibilityStatus.warning,
            code: 'code',
            message: 'msg',
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('supports Equatable value equality', () {
      const issue = PrinterCompatibilityIssue(
        severity: PrinterCompatibilityStatus.warning,
        code: 'driver_mismatch',
        message: 'Driver mismatch',
      );

      final comp1 = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.warning,
        issues: const [issue],
      );
      final comp2 = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.warning,
        issues: const [issue],
      );
      final comp3 = PrinterProfileCompatibility(
        profile: dummyProfile,
        printer: dummyPrinter,
        status: PrinterCompatibilityStatus.compatible,
        issues: const [],
      );

      expect(comp1, equals(comp2));
      expect(comp1, isNot(equals(comp3)));
    });
  });
}
