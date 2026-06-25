import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationSession', () {
    late PrinterProfile dummyProfile;
    late PrinterTrayProfile dummyTray;
    late CalibrationSheetTemplate dummyTemplate;
    late CalibrationMeasurementPoint point1;
    late CalibrationMeasurementPoint point2;

    setUp(() {
      final now = DateTime(2026, 6, 24);
      dummyTray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
      );

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
          allowStickerSpecificAdjustment: true,
        ),
        trays: [dummyTray],
        createdAt: now,
        updatedAt: now,
      );

      point1 = CalibrationMeasurementPoint(
        id: 'p1',
        label: 'TL',
        expectedX: 10,
        expectedY: 15,
      );
      point2 = CalibrationMeasurementPoint(
        id: 'p2',
        label: 'TR',
        expectedX: 100,
        expectedY: 15,
      );

      dummyTemplate = CalibrationSheetTemplate(
        id: 'temp_1',
        name: 'Template 1',
        points: [point1, point2],
      );
    });

    test('succeeds on valid construction', () {
      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: const [],
      );

      expect(session.id, 'sess_1');
      expect(session.printerProfile, dummyProfile);
      expect(session.trayProfile, dummyTray);
      expect(session.paperConfigurationId, 'paper_1');
      expect(session.sheetTemplate, dummyTemplate);
      expect(session.measurements, isEmpty);
    });

    test('throws AssertionError when id is empty', () {
      expect(
        () => CalibrationSession(
          id: '',
          printerProfile: dummyProfile,
          trayProfile: dummyTray,
          paperConfigurationId: 'paper_1',
          sheetTemplate: dummyTemplate,
          measurements: const [],
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when paperConfigurationId is empty', () {
      expect(
        () => CalibrationSession(
          id: 'sess_1',
          printerProfile: dummyProfile,
          trayProfile: dummyTray,
          paperConfigurationId: '',
          sheetTemplate: dummyTemplate,
          measurements: const [],
        ),
        throwsAssertionError,
      );
    });

    group('Completion Logic', () {
      test('isComplete is false when measurements count is less than points count', () {
        final session = CalibrationSession(
          id: 'sess_1',
          printerProfile: dummyProfile,
          trayProfile: dummyTray,
          paperConfigurationId: 'paper_1',
          sheetTemplate: dummyTemplate,
          measurements: [
            CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
          ],
        );
        expect(session.isComplete, isFalse);
      });

      test('isComplete is false when measurements count is greater than points count', () {
        final session = CalibrationSession(
          id: 'sess_1',
          printerProfile: dummyProfile,
          trayProfile: dummyTray,
          paperConfigurationId: 'paper_1',
          sheetTemplate: dummyTemplate,
          measurements: [
            CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
            CalibrationMeasurement(point: point2, actualX: 100, actualY: 15),
            CalibrationMeasurement(point: point1, actualX: 11, actualY: 16),
          ],
        );
        expect(session.isComplete, isFalse);
      });

      test('isComplete is false on duplicate measurements for the same point', () {
        final session = CalibrationSession(
          id: 'sess_1',
          printerProfile: dummyProfile,
          trayProfile: dummyTray,
          paperConfigurationId: 'paper_1',
          sheetTemplate: dummyTemplate,
          measurements: [
            CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
            CalibrationMeasurement(point: point1, actualX: 11, actualY: 16),
          ],
        );
        expect(session.isComplete, isFalse);
      });

      test('isComplete is true on unique measurements for all template points', () {
        final session = CalibrationSession(
          id: 'sess_1',
          printerProfile: dummyProfile,
          trayProfile: dummyTray,
          paperConfigurationId: 'paper_1',
          sheetTemplate: dummyTemplate,
          measurements: [
            CalibrationMeasurement(point: point1, actualX: 10.5, actualY: 14.8),
            CalibrationMeasurement(point: point2, actualX: 99.8, actualY: 15.2),
          ],
        );
        expect(session.isComplete, isTrue);
      });
    });

    test('verifies defensive copying and immutability', () {
      final measurement = CalibrationMeasurement(point: point1, actualX: 10, actualY: 15);
      final originalList = [measurement];

      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: originalList,
      );

      // Verify defensive copy: original list modification does not affect session
      originalList.add(CalibrationMeasurement(point: point2, actualX: 100, actualY: 15));
      expect(session.measurements.length, 1);
      expect(session.measurements, contains(measurement));

      // Verify session measurements list itself throws UnsupportedError on mutation
      expect(
        () => session.measurements.add(measurement),
        throwsUnsupportedError,
      );
      expect(
        session.measurements.clear,
        throwsUnsupportedError,
      );
    });

    test('supports Equatable equality', () {
      final sessionA = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: const [],
      );
      final sessionB = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: const [],
      );
      final sessionC = CalibrationSession(
        id: 'sess_2',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: const [],
      );

      expect(sessionA, sessionB);
      expect(sessionA, isNot(sessionC));
    });
  });
}
