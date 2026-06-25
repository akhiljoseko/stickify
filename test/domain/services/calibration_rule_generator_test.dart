import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationRuleGenerator', () {
    late CalibrationRuleGenerator generator;
    late PrinterProfile dummyProfile;
    late PrinterTrayProfile dummyTray;

    setUp(() {
      generator = const CalibrationRuleGenerator();

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
    });

    test('Zero offset/scale: identity transform rule when matching expectations', () {
      final point1 = CalibrationMeasurementPoint(id: 'p1', label: 'TL', expectedX: 10, expectedY: 15);
      final point2 = CalibrationMeasurementPoint(id: 'p2', label: 'TR', expectedX: 100, expectedY: 15);
      final point3 = CalibrationMeasurementPoint(id: 'p3', label: 'BL', expectedX: 10, expectedY: 150);
      final point4 = CalibrationMeasurementPoint(id: 'p4', label: 'BR', expectedX: 100, expectedY: 150);

      final sheetTemplate = CalibrationSheetTemplate(
        id: 'temp_4',
        name: 'Template 4',
        points: [point1, point2, point3, point4],
      );

      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: sheetTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 10, actualY: 15),
          CalibrationMeasurement(point: point2, actualX: 100, actualY: 15),
          CalibrationMeasurement(point: point3, actualX: 10, actualY: 150),
          CalibrationMeasurement(point: point4, actualX: 100, actualY: 150),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      final result = generator.generate(request);

      expect(result.generatedRules.length, equals(1));
      final rule = result.generatedRules.first;
      expect(rule.target.type, equals(TargetType.sheet));
      expect(rule.transformation.offsetX, closeTo(0.0, 1e-6));
      expect(rule.transformation.offsetY, closeTo(0.0, 1e-6));
      expect(rule.transformation.scaleX, closeTo(1.0, 1e-6));
      expect(rule.transformation.scaleY, closeTo(1.0, 1e-6));
    });

    test('Positive offset correction: negative rule offset generated from drift', () {
      final point1 = CalibrationMeasurementPoint(id: 'p1', label: 'TL', expectedX: 10, expectedY: 15);
      final point2 = CalibrationMeasurementPoint(id: 'p2', label: 'TR', expectedX: 100, expectedY: 15);

      final sheetTemplate = CalibrationSheetTemplate(
        id: 'temp_2',
        name: 'Template 2',
        points: [point1, point2],
      );

      // Printer drifted right by 2mm and down by 3mm
      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: sheetTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 12, actualY: 18),
          CalibrationMeasurement(point: point2, actualX: 102, actualY: 18),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      final result = generator.generate(request);

      expect(result.generatedRules.length, equals(1));
      final rule = result.generatedRules.first;
      expect(rule.transformation.offsetX, closeTo(-2.0, 1e-6));
      expect(rule.transformation.offsetY, closeTo(-3.0, 1e-6));
      expect(rule.transformation.scaleX, closeTo(1.0, 1e-6));
      expect(rule.transformation.scaleY, closeTo(1.0, 1e-6));
    });

    test('Scale correction: scaleX/scaleY computed from distances', () {
      final point1 = CalibrationMeasurementPoint(id: 'p1', label: 'TL', expectedX: 10, expectedY: 15);
      final point2 = CalibrationMeasurementPoint(id: 'p2', label: 'TR', expectedX: 110, expectedY: 15);
      final point3 = CalibrationMeasurementPoint(id: 'p3', label: 'BL', expectedX: 10, expectedY: 115);
      final point4 = CalibrationMeasurementPoint(id: 'p4', label: 'BR', expectedX: 110, expectedY: 115);

      final sheetTemplate = CalibrationSheetTemplate(
        id: 'temp_4',
        name: 'Template 4',
        points: [point1, point2, point3, point4],
      );

      // Apply scaling: scaleX = 0.98, scaleY = 0.97 (with no offset, i.e. relative to origin)
      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: sheetTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 9.8, actualY: 14.55),
          CalibrationMeasurement(point: point2, actualX: 107.8, actualY: 14.55),
          CalibrationMeasurement(point: point3, actualX: 9.8, actualY: 111.55),
          CalibrationMeasurement(point: point4, actualX: 107.8, actualY: 111.55),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      final result = generator.generate(request);

      expect(result.generatedRules.length, equals(1));
      final rule = result.generatedRules.first;

      // Average deltas:
      // actualX: 9.8 (delta -0.2), 107.8 (delta -2.2), 9.8 (delta -0.2), 107.8 (delta -2.2) -> avg deltaX = -1.2
      // actualY: 14.55 (delta -0.45), 14.55 (delta -0.45), 111.55 (delta -3.45), 111.55 (delta -3.45) -> avg deltaY = -1.95
      // Corrected offsets (inverse):
      expect(rule.transformation.offsetX, closeTo(1.2, 1e-6));
      expect(rule.transformation.offsetY, closeTo(1.95, 1e-6));

      // Scales:
      // X pairs with diff expectedX:
      // (p1, p2): expected=100, actual=98 -> 0.98
      // (p1, p4): expected=100, actual=98 -> 0.98
      // (p3, p2): expected=100, actual=98 -> 0.98
      // (p3, p4): expected=100, actual=98 -> 0.98
      // mean = 0.98
      expect(rule.transformation.scaleX, closeTo(0.98, 1e-6));

      // Y pairs with diff expectedY:
      // (p1, p3): expected=100, actual=97 -> 0.97
      // (p1, p4): expected=100, actual=97 -> 0.97
      // (p2, p3): expected=100, actual=97 -> 0.97
      // (p2, p4): expected=100, actual=97 -> 0.97
      // mean = 0.97
      expect(rule.transformation.scaleY, closeTo(0.97, 1e-6));
    });

    test('Single point session: scale is 1.0, offset is still calculated', () {
      final point = CalibrationMeasurementPoint(id: 'p1', label: 'C', expectedX: 50, expectedY: 50);
      final sheetTemplate = CalibrationSheetTemplate(id: 'temp_1', name: 'Template 1', points: [point]);

      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: sheetTemplate,
        measurements: [
          CalibrationMeasurement(point: point, actualX: 53, actualY: 48),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      final result = generator.generate(request);

      expect(result.generatedRules.length, equals(1));
      final rule = result.generatedRules.first;

      expect(rule.transformation.offsetX, closeTo(-3.0, 1e-6));
      expect(rule.transformation.offsetY, closeTo(2.0, 1e-6));
      expect(rule.transformation.scaleX, closeTo(1.0, 1e-6));
      expect(rule.transformation.scaleY, closeTo(1.0, 1e-6));
    });

    test('Sufficient horizontal, insufficient vertical separation', () {
      final point1 = CalibrationMeasurementPoint(id: 'p1', label: 'L', expectedX: 10, expectedY: 15);
      final point2 = CalibrationMeasurementPoint(id: 'p2', label: 'R', expectedX: 110, expectedY: 15);

      final sheetTemplate = CalibrationSheetTemplate(
        id: 'temp_2',
        name: 'Template 2',
        points: [point1, point2],
      );

      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: sheetTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 9.8, actualY: 14),
          CalibrationMeasurement(point: point2, actualX: 107.8, actualY: 14),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      final result = generator.generate(request);

      expect(result.generatedRules.length, equals(1));
      final rule = result.generatedRules.first;

      // scaleX computed from (p1, p2) distance
      expect(rule.transformation.scaleX, closeTo(0.98, 1e-6));
      // scaleY is 1.0 because expectedY is identical (15)
      expect(rule.transformation.scaleY, closeTo(1.0, 1e-6));
    });

    test('Sufficient vertical, insufficient horizontal separation', () {
      final point1 = CalibrationMeasurementPoint(id: 'p1', label: 'T', expectedX: 10, expectedY: 15);
      final point2 = CalibrationMeasurementPoint(id: 'p2', label: 'B', expectedX: 10, expectedY: 115);

      final sheetTemplate = CalibrationSheetTemplate(
        id: 'temp_2',
        name: 'Template 2',
        points: [point1, point2],
      );

      final session = CalibrationSession(
        id: 'sess_1',
        printerProfile: dummyProfile,
        trayProfile: dummyTray,
        paperConfigurationId: 'paper_1',
        sheetTemplate: sheetTemplate,
        measurements: [
          CalibrationMeasurement(point: point1, actualX: 10, actualY: 14.55),
          CalibrationMeasurement(point: point2, actualX: 10, actualY: 111.55),
        ],
      );

      final request = CalibrationGenerationRequest(session: session);
      final result = generator.generate(request);

      expect(result.generatedRules.length, equals(1));
      final rule = result.generatedRules.first;

      // scaleX is 1.0 because expectedX is identical (10)
      expect(rule.transformation.scaleX, closeTo(1.0, 1e-6));
      // scaleY computed from (p1, p2) distance
      expect(rule.transformation.scaleY, closeTo(0.97, 1e-6));
    });
  });
}
