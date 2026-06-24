// Ignore redundant argument values because tests explicitly verify that passing
// default/neutral values behaves correctly and compiles.
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  late PrinterProfileCompatibilityAnalyzer analyzer;

  setUp(() {
    analyzer = PrinterProfileCompatibilityAnalyzer();
  });

  PrinterProfile createProfile({
    required String id,
    String systemPrinterName = 'Zebra ZD421',
    String manufacturer = 'Zebra',
    String model = 'ZD421',
    String driverName = 'ZDesigner ZD421',
  }) {
    return PrinterProfile(
      id: id,
      displayName: 'Printer Profile',
      status: PrinterProfileStatus.active,
      printerIdentity: PrinterIdentity(
        systemPrinterName: systemPrinterName,
        manufacturer: manufacturer,
        model: model,
        driverName: driverName,
        driverVersion: '1.0',
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
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  group('PrinterProfileCompatibilityAnalyzer Tests', () {
    test('Compatible: All metadata matches exactly', () {
      final profile = createProfile(
        id: '1',
        manufacturer: 'Zebra',
        model: 'ZD421',
        driverName: 'ZDesigner ZD421',
      );
      const printer = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZD421',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ZD421',
        driverName: 'ZDesigner ZD421',
      );

      final result = analyzer.analyze(profile: profile, printer: printer);

      expect(result.status, equals(PrinterCompatibilityStatus.compatible));
      expect(result.issues, isEmpty);
    });

    group('Warning Scenarios', () {
      test('Missing manufacturer yields warning and code missing_manufacturer', () {
        final profile = createProfile(id: '1', manufacturer: 'Zebra');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: '', // missing
          model: 'ZD421',
          driverName: 'ZDesigner ZD421',
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.warning));
        expect(result.issues.length, equals(1));
        expect(result.issues.first.code, equals('missing_manufacturer'));
        expect(result.issues.first.severity, equals(PrinterCompatibilityStatus.warning));
      });

      test('Missing model yields warning and code missing_model', () {
        final profile = createProfile(id: '1', model: 'ZD421');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: '', // missing
          driverName: 'ZDesigner ZD421',
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.warning));
        expect(result.issues.length, equals(1));
        expect(result.issues.first.code, equals('missing_model'));
        expect(result.issues.first.severity, equals(PrinterCompatibilityStatus.warning));
      });

      test('Missing driver yields warning and code missing_driver', () {
        final profile = createProfile(id: '1', driverName: 'ZDesigner ZD421');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
          driverName: '', // missing
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.warning));
        expect(result.issues.length, equals(1));
        expect(result.issues.first.code, equals('missing_driver'));
        expect(result.issues.first.severity, equals(PrinterCompatibilityStatus.warning));
      });

      test('Driver mismatch yields warning and code driver_mismatch', () {
        final profile = createProfile(id: '1', driverName: 'ZDesigner Legacy');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421',
          driverName: 'ZDesigner Modern', // mismatched
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.warning));
        expect(result.issues.length, equals(1));
        expect(result.issues.first.code, equals('driver_mismatch'));
        expect(result.issues.first.severity, equals(PrinterCompatibilityStatus.warning));
      });

      test('Multiple warnings keep warning status and preserve execution ordering', () {
        final profile = createProfile(id: '1', driverName: 'ZDesigner Legacy');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: '', // 1. missing manufacturer warning
          model: 'ZD421',
          driverName: '', // 2. missing driver warning
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.warning));
        expect(result.issues.length, equals(2));
        // Execution order: Manufacturer -> Model -> Driver (mfg is checked before driver name)
        expect(result.issues[0].code, equals('missing_manufacturer'));
        expect(result.issues[1].code, equals('missing_driver'));
      });
    });

    group('Incompatible Scenarios', () {
      test('Manufacturer mismatch yields incompatible status and code manufacturer_mismatch', () {
        final profile = createProfile(id: '1', manufacturer: 'Zebra');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'HP Print',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'HP', // mismatch
          model: 'ZD421',
          driverName: 'ZDesigner ZD421',
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.incompatible));
        expect(result.issues.length, equals(1));
        expect(result.issues.first.code, equals('manufacturer_mismatch'));
        expect(result.issues.first.severity, equals(PrinterCompatibilityStatus.incompatible));
      });

      test('Model mismatch yields incompatible status and code model_mismatch', () {
        final profile = createProfile(id: '1', model: 'ZD420');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'Zebra',
          model: 'ZD421', // mismatch
          driverName: 'ZDesigner ZD421',
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.incompatible));
        expect(result.issues.length, equals(1));
        expect(result.issues.first.code, equals('model_mismatch'));
        expect(result.issues.first.severity, equals(PrinterCompatibilityStatus.incompatible));
      });
    });

    group('Mixed Severity Aggregation', () {
      test('Incompatible overrides warning severity', () {
        final profile = createProfile(
          id: '1',
          manufacturer: 'Zebra',
          driverName: 'ZDesigner Legacy',
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'HP Print',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'HP', // incompatible: manufacturer_mismatch
          model: 'ZD421',
          driverName: 'ZDesigner Modern', // warning: driver_mismatch
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(result.status, equals(PrinterCompatibilityStatus.incompatible));
        expect(result.issues.length, equals(2));
        expect(result.issues[0].code, equals('manufacturer_mismatch'));
        expect(result.issues[1].code, equals('driver_mismatch'));
      });
    });

    group('Empty Metadata Behavior', () {
      test('Empty values on both sides does not trigger mismatch', () {
        final profile = createProfile(
          id: '1',
          manufacturer: '', // empty in profile
          model: '', // empty in profile
          driverName: '', // empty in profile
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: '', // empty in printer -> will trigger warning missing_manufacturer
          model: '', // empty in printer -> will trigger warning missing_model
          driverName: '', // empty in printer -> will trigger warning missing_driver
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        // Should trigger missing warnings, but no mismatch incompatible issues.
        expect(result.status, equals(PrinterCompatibilityStatus.warning));
        expect(
          result.issues.any((issue) => issue.code.contains('mismatch')),
          isFalse,
        );
      });
    });

    group('Collection Safety & Immutability', () {
      test('Returned issues list is unmodifiable', () {
        final profile = createProfile(id: '1');
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
        );

        final result = analyzer.analyze(profile: profile, printer: printer);

        expect(
          () => result.issues.add(
            const PrinterCompatibilityIssue(
              severity: PrinterCompatibilityStatus.warning,
              code: 'code',
              message: 'message',
            ),
          ),
          throwsA(isA<UnsupportedError>()),
        );
      });

      test('Does not mutate caller input profile or discovered printer', () {
        final profile = createProfile(
          id: '1',
          manufacturer: 'Zebra',
          model: 'ZD421',
        );
        const printer = DiscoveredPrinter(
          systemPrinterName: 'Zebra ZD421',
          status: DiscoveredPrinterStatus.online,
          manufacturer: 'HP',
          model: 'LaserJet',
        );

        analyzer.analyze(profile: profile, printer: printer);

        // Verify inputs are unchanged
        expect(profile.printerIdentity.manufacturer, equals('Zebra'));
        expect(profile.printerIdentity.model, equals('ZD421'));
        expect(printer.manufacturer, equals('HP'));
        expect(printer.model, equals('LaserJet'));
      });
    });
  });
}
