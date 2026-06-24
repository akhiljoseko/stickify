// Testing redundant arguments is necessary to verify default parameters and fallback behaviors.
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrintExecutionConfiguration Tests', () {
    final testTray = PrinterTrayProfile(
      trayIdentifier: 'tray_1',
      displayName: 'Main Tray',
      supportedPaperConfigurations: const [
        PaperConfigurationReference(id: 'paper_A4', displayName: 'A4 Paper'),
      ],
      calibration: PrinterCalibration(
        enabled: true,
        calibrationRules: const [
          CalibrationRule(
            target: CalibrationTarget.sheet(),
            transformation: PrintStickerTransform(offsetX: 1),
          ),
        ],
      ),
    );

    test('Valid legacy path (null parameters) is accepted', () {
      const config = PrintExecutionConfiguration();
      expect(config.selectedTray, isNull);
      expect(config.paperConfigurationId, isNull);
    });

    test('Valid legacy path (explicit null tray and config ID) is accepted', () {
      const config = PrintExecutionConfiguration(
        selectedTray: null,
        paperConfigurationId: null,
      );
      expect(config.selectedTray, isNull);
      expect(config.paperConfigurationId, isNull);
    });

    test('Valid calibrated path (tray and paperConfigurationId provided) is accepted', () {
      final config = PrintExecutionConfiguration(
        selectedTray: testTray,
        paperConfigurationId: 'paper_A4',
      );
      expect(config.selectedTray, equals(testTray));
      expect(config.paperConfigurationId, equals('paper_A4'));
    });

    test('Invalid configuration (tray provided but paperConfigurationId is null) throws AssertionError', () {
      expect(
        () => PrintExecutionConfiguration(
          selectedTray: testTray,
          paperConfigurationId: null,
        ),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('paperConfigurationId is required when a printer tray is selected'),
          ),
        ),
      );
    });

    test('Supports Equatable equality checks', () {
      final config1 = PrintExecutionConfiguration(
        selectedTray: testTray,
        paperConfigurationId: 'paper_A4',
      );
      final config2 = PrintExecutionConfiguration(
        selectedTray: testTray,
        paperConfigurationId: 'paper_A4',
      );
      const config3 = PrintExecutionConfiguration();

      expect(config1, equals(config2));
      expect(config1, isNot(equals(config3)));
    });
  });
}
