import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationGenerationRequest', () {
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
          preferShrinkOverShift: false,
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

    test('succeeds on complete session', () {
      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
          CalibrationMeasurement(point: point2, actualX: 100, actualY: 15),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      expect(request.session, session);
    });

    test('throws AssertionError on incomplete session', () {
      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: const [],
      );

      expect(
        () => CalibrationGenerationRequest(session: session),
        throwsAssertionError,
      );
    });

    test('supports Equatable equality', () {
      final session1 = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
          CalibrationMeasurement(point: point2, actualX: 100, actualY: 15),
        ],
      );
      final session2 = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: dummyTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
          CalibrationMeasurement(point: point2, actualX: 100, actualY: 15),
        ],
      );

      final requestA = CalibrationGenerationRequest(session: session1);
      final requestB = CalibrationGenerationRequest(session: session2);

      expect(requestA, requestB);
    });
  });
}
