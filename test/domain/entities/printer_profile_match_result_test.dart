// Ignore redundant argument values because tests explicitly verify that passing
// default/neutral values behaves correctly and compiles.
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrinterProfileMatchResult Validation & Equality Tests', () {
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

    group('Valid Constructions', () {
      test('matched status with non-null printer succeeds', () {
        final result = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.matched,
          discoveredPrinter: dummyPrinter,
        );
        expect(result.status, equals(PrinterProfileMatchStatus.matched));
        expect(result.discoveredPrinter, equals(dummyPrinter));
        expect(result.profile, equals(dummyProfile));
      });

      test('compatible status with non-null printer succeeds', () {
        final result = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.compatible,
          discoveredPrinter: dummyPrinter,
        );
        expect(result.status, equals(PrinterProfileMatchStatus.compatible));
        expect(result.discoveredPrinter, equals(dummyPrinter));
      });

      test('incompatible status with non-null printer succeeds', () {
        final result = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.incompatible,
          discoveredPrinter: dummyPrinter,
        );
        expect(result.status, equals(PrinterProfileMatchStatus.incompatible));
        expect(result.discoveredPrinter, equals(dummyPrinter));
      });

      test('missing status with null printer succeeds', () {
        final result = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.missing,
          discoveredPrinter: null,
        );
        expect(result.status, equals(PrinterProfileMatchStatus.missing));
        expect(result.discoveredPrinter, listNull);
      });
    });

    group('Assertion Validations', () {
      test('matched status requires a discovered printer', () {
        expect(
          () => PrinterProfileMatchResult(
            profile: dummyProfile,
            status: PrinterProfileMatchStatus.matched,
            discoveredPrinter: null,
          ),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('matched status requires a discovered printer'),
            ),
          ),
        );
      });

      test('compatible status requires a discovered printer', () {
        expect(
          () => PrinterProfileMatchResult(
            profile: dummyProfile,
            status: PrinterProfileMatchStatus.compatible,
            discoveredPrinter: null,
          ),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('compatible status requires a discovered printer'),
            ),
          ),
        );
      });

      test('incompatible status requires a discovered printer', () {
        expect(
          () => PrinterProfileMatchResult(
            profile: dummyProfile,
            status: PrinterProfileMatchStatus.incompatible,
            discoveredPrinter: null,
          ),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('incompatible status requires a discovered printer'),
            ),
          ),
        );
      });

      test('missing status cannot contain a discovered printer', () {
        expect(
          () => PrinterProfileMatchResult(
            profile: dummyProfile,
            status: PrinterProfileMatchStatus.missing,
            discoveredPrinter: dummyPrinter,
          ),
          throwsA(
            isA<AssertionError>().having(
              (e) => e.message,
              'message',
              contains('missing status cannot contain a discovered printer'),
            ),
          ),
        );
      });
    });

    group('Equality and String Representation', () {
      test('supports Equatable value equality', () {
        final result1 = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.matched,
          discoveredPrinter: dummyPrinter,
        );
        final result2 = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.matched,
          discoveredPrinter: dummyPrinter,
        );
        final result3 = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.compatible,
          discoveredPrinter: dummyPrinter,
        );

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('has a helpful toString representation', () {
        final resultWithPrinter = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.matched,
          discoveredPrinter: dummyPrinter,
        );
        final resultWithoutPrinter = PrinterProfileMatchResult(
          profile: dummyProfile,
          status: PrinterProfileMatchStatus.missing,
          discoveredPrinter: null,
        );

        expect(
          resultWithPrinter.toString(),
          equals(
            'PrinterProfileMatchResult(profileId: profile_1, status: PrinterProfileMatchStatus.matched, hasDiscoveredPrinter: true)',
          ),
        );
        expect(
          resultWithoutPrinter.toString(),
          equals(
            'PrinterProfileMatchResult(profileId: profile_1, status: PrinterProfileMatchStatus.missing, hasDiscoveredPrinter: false)',
          ),
        );
      });
    });
  });
}
// Helper to allow null matching expect
const Matcher listNull = _NullMatcher();

class _NullMatcher extends Matcher {
  const _NullMatcher();
  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) => item == null;
  @override
  Description describe(Description description) => description.add('null');
}
