// Ignore redundant argument values because tests explicitly verify that passing
// default/neutral values behaves correctly and compiles.
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  late PrinterProfileMatcher matcher;

  setUp(() {
    matcher = PrinterProfileMatcher();
  });

  PrinterProfile createProfile({
    required String id,
    required String systemPrinterName,
    String manufacturer = '',
    String model = '',
    String displayName = 'Printer Profile',
  }) {
    return PrinterProfile(
      id: id,
      displayName: displayName,
      status: PrinterProfileStatus.active,
      printerIdentity: PrinterIdentity(
        systemPrinterName: systemPrinterName,
        manufacturer: manufacturer,
        model: model,
      ),
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
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('PrinterProfileMatcher Tests', () {
    test('Empty profile list returns empty immutable list', () {
      const discovered = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZD421',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ZD421',
      );

      final results = matcher.matchProfiles(
        profiles: [],
        discoveredPrinters: [discovered],
      );

      expect(results, isEmpty);
      expect(() => results.add(PrinterProfileMatchResult(
        profile: createProfile(id: '1', systemPrinterName: 'Zebra'),
        status: PrinterProfileMatchStatus.missing,
      )), throwsA(isA<UnsupportedError>()));
    });

    test('Batch & Independent matching processes all profiles independently in order', () {
      final profileA = createProfile(
        id: 'A',
        systemPrinterName: 'Zebra A',
        manufacturer: 'Zebra',
        model: 'ModelA',
      );
      final profileB = createProfile(
        id: 'B',
        systemPrinterName: 'Zebra B',
        manufacturer: 'Zebra',
        model: 'ModelB',
      );
      final profileC = createProfile(
        id: 'C',
        systemPrinterName: 'Zebra C',
        manufacturer: 'Zebra',
        model: 'ModelC',
      );

      const printer1 = DiscoveredPrinter(
        systemPrinterName: 'Zebra A',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ModelA',
      );
      const printer2 = DiscoveredPrinter(
        systemPrinterName: 'Zebra B Copy',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ModelB',
      );
      const printer3 = DiscoveredPrinter(
        systemPrinterName: 'Zebra D',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ModelD',
      );

      final results = matcher.matchProfiles(
        profiles: [profileA, profileB, profileC],
        discoveredPrinters: [printer1, printer2, printer3],
      );

      expect(results.length, equals(3));

      // Profile A -> Exact Match
      expect(results[0].profile.id, equals('A'));
      expect(results[0].status, equals(PrinterProfileMatchStatus.matched));
      expect(results[0].discoveredPrinter, equals(printer1));

      // Profile B -> Compatible Match
      expect(results[1].profile.id, equals('B'));
      expect(results[1].status, equals(PrinterProfileMatchStatus.compatible));
      expect(results[1].discoveredPrinter, equals(printer2));

      // Profile C -> Missing
      expect(results[2].profile.id, equals('C'));
      expect(results[2].status, equals(PrinterProfileMatchStatus.missing));
      expect(results[2].discoveredPrinter, isNull);
    });

    group('Exact Matching', () {
      test('succeeds on exact system printer name match', () {
        final profile = createProfile(id: '1', systemPrinterName: 'Zebra ZD421');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.matched));
        expect(results.first.discoveredPrinter, equals(printer));
      });

      test('prioritizes exact name match over compatibility match', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Zebra ZD421',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        // printer1 is compatible (same mfg and model, different name)
        const printer1 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        // printer2 is exact match (same system name)
        const printer2 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer1, printer2],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.matched));
        expect(results.first.discoveredPrinter, equals(printer2));
      });
    });

    group('Compatibility Matching', () {
      test('succeeds on matching non-empty manufacturer and model', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Zebra ZD421 Stored',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.compatible));
        expect(results.first.discoveredPrinter, equals(printer));
      });

      test('fails (returns missing) if profile manufacturer is empty', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Zebra ZD421',
          manufacturer: '',
          model: 'ZD421',
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.missing));
        expect(results.first.discoveredPrinter, isNull);
      });

      test('fails (returns missing) if profile model is empty', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Zebra ZD421',
          manufacturer: 'Zebra',
          model: '',
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.missing));
        expect(results.first.discoveredPrinter, isNull);
      });

      test('fails (returns missing) if discovered manufacturer is empty', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Zebra ZD421',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy',
          status: DiscoveredPrinterStatus.online,
          manufacturer: '',
          model: 'ZD421',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.missing));
        expect(results.first.discoveredPrinter, isNull);
      });

      test('fails (returns missing) if discovered model is empty', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Zebra ZD421',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: '',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.missing));
        expect(results.first.discoveredPrinter, isNull);
      });
    });

    group('Duplicate Resolution', () {
      test('selects the first matching discovered printer for multiple exact matches', () {
        final profile = createProfile(id: '1', systemPrinterName: 'Zebra ZD421');

        const printer1 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Mfg1',
        );
        const printer2 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Mfg2',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer1, printer2],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.matched));
        expect(results.first.discoveredPrinter, equals(printer1));
      });

      test('selects the first matching discovered printer for multiple compatible matches', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Stored ZD421',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        const printer1 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy 1',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );
        const printer2 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421 Copy 2',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer1, printer2],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.compatible));
        expect(results.first.discoveredPrinter, equals(printer1));
      });
    });

    group('Missing State', () {
      test('returns missing status when no matches are found', () {
        final profile = createProfile(
          id: '1',
          systemPrinterName: 'Stored Zebra',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );

        const printer = DiscoveredPrinter(
          systemPrinterName: 'Other OS Printer',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'HP',
          model: 'LaserJet',
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(results.first.status, equals(PrinterProfileMatchStatus.missing));
        expect(results.first.discoveredPrinter, isNull);
      });
    });

    group('Collection Safety', () {
      test('returns an unmodifiable result list', () {
        final profile = createProfile(id: '1', systemPrinterName: 'Zebra');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra',
          status: DiscoveredPrinterStatus.online,
        );

        final results = matcher.matchProfiles(
          profiles: [profile],
          discoveredPrinters: [printer],
        );

        expect(
          () => results.add(PrinterProfileMatchResult(
            profile: profile,
            status: PrinterProfileMatchStatus.missing,
          )),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('does not mutate or sort the input lists', () {
        final profile1 = createProfile(id: '2', systemPrinterName: 'Zebra ZD');
        final profile2 = createProfile(id: '1', systemPrinterName: 'HP Print');
        final profilesList = [profile1, profile2];

        const printer1 = DiscoveredPrinter(
          systemPrinterName: 'HP Print',
          status: DiscoveredPrinterStatus.online,
        );
        const printer2 = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD',
          status: DiscoveredPrinterStatus.online,
        );
        final printersList = [printer1, printer2];

        matcher.matchProfiles(
          profiles: profilesList,
          discoveredPrinters: printersList,
        );

        // Verify profiles list is untouched
        expect(profilesList.length, equals(2));
        expect(profilesList[0], equals(profile1));
        expect(profilesList[1], equals(profile2));

        // Verify printers list is untouched
        expect(printersList.length, equals(2));
        expect(printersList[0], equals(printer1));
        expect(printersList[1], equals(printer2));
      });
    });
  });
}
