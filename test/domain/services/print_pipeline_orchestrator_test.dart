import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrintPipelineOrchestrator Tests', () {
    const ruleMatcher = CalibrationRuleMatcher();
    const transformComposer = CalibrationTransformComposer();
    const calibrationResolver = PrinterCalibrationCoordinateResolver(
      ruleMatcher: ruleMatcher,
      transformComposer: transformComposer,
    );
    const compatibilityAnalyzer = TemplatePrinterCompatibilityAnalyzer();
    const transformGenerator = IntelligentTransformGenerator();

    const orchestrator = PrintPipelineOrchestrator(
      calibrationResolver: calibrationResolver,
      compatibilityAnalyzer: compatibilityAnalyzer,
      transformGenerator: transformGenerator,
      transformComposer: transformComposer,
    );

    late LabelTemplate template;
    late PrinterTrayProfile trayWithCalibration;
    late PrinterProfile printer;

    setUp(() {
      template = const LabelTemplate(
        id: 'portrait_tpl',
        name: 'Portrait Template',
        sheetConfig: SheetConfig(
          pageWidth: 200,
          pageHeight: 300,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 2,
          rows: 2,
          columnGap: 10,
          rowGap: 10,
        ),
        stickerConfig: StickerConfig(
          widthMm: 85,
          heightMm: 90,
          cornerRadiusMm: 3,
          printableArea: [],
        ),
      );

      final defaultTray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [
          PaperConfigurationReference(id: 'portrait_tpl', displayName: 'Portrait Template'),
        ],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
        nonPrintableMarginLeft: 5,
        nonPrintableMarginRight: 5,
        nonPrintableMarginTop: 5,
        nonPrintableMarginBottom: 5,
      );

      // Printer capabilities with some margins
      printer = PrinterProfile(
        id: 'p1',
        displayName: 'Test Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'Test Printer'),
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
        trays: [defaultTray],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
    });

    test('Calibration only, no conflicts', () {
      // Tray profile has active calibration rule but no conflicts exist
      trayWithCalibration = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [
          PaperConfigurationReference(id: 'portrait_tpl', displayName: 'Portrait Template'),
        ],
        calibration: PrinterCalibration(
          enabled: true,
          calibrationRules: const [
            CalibrationRule(
              target: CalibrationTarget.sheet(),
              transformation: PrintStickerTransform(
                offsetX: 1,
                offsetY: 2,
              ),
            ),
          ],
        ),
        nonPrintableMarginLeft: 5,
        nonPrintableMarginRight: 5,
        nonPrintableMarginTop: 5,
        nonPrintableMarginBottom: 5,
      );

      final result = orchestrator.resolve(
        template: template,
        printer: printer,
        tray: trayWithCalibration,
        paperConfigurationId: 'portrait_tpl',
      );

      expect(result, isA<Success<PrintCoordinateContext, AppError>>());
      final context = (result as Success<PrintCoordinateContext, AppError>).value;
      
      // Since no conflicts exist (left/right margins are 5mm, stickers start at 10mm margins),
      // only calibration rules are applied.
      final transform = context.resolveFor(row: 0, column: 0, absoluteSlotIndex: 0);
      expect(transform.offsetX, equals(1.0));
      expect(transform.offsetY, equals(2.0));
      expect(transform.scaleX, equals(1.0));
    });

    test('Calibration + optimization composition', () {
      // Calibration shifts left by 1 mm (which would make left = 9 mm, creating 3 mm overlap conflict on left)
      // Shift margin to 12 mm to force a left-margin conflict (template margin is 10 mm)
      trayWithCalibration = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [
          PaperConfigurationReference(id: 'portrait_tpl', displayName: 'Portrait Template'),
        ],
        calibration: PrinterCalibration(
          enabled: true,
          calibrationRules: const [
            CalibrationRule(
              target: CalibrationTarget.sheet(),
              transformation: PrintStickerTransform(
                offsetX: -1, // calibration shifts left by 1mm
              ),
            ),
          ],
        ),
        nonPrintableMarginLeft: 12, // 10mm starts, so 2mm overlap conflict on left
        nonPrintableMarginRight: 5,
        nonPrintableMarginTop: 5,
        nonPrintableMarginBottom: 5,
      );
      final printerWithConflict = PrinterProfile(
        id: 'p1',
        displayName: 'High Margin Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'p1'),
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
        trays: [trayWithCalibration],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = orchestrator.resolve(
        template: template,
        printer: printerWithConflict,
        tray: trayWithCalibration,
        paperConfigurationId: 'portrait_tpl',
      );

      expect(result, isA<Success<PrintCoordinateContext, AppError>>());
      final context = (result as Success<PrintCoordinateContext, AppError>).value;

      // Calibration offsetX = -1.0
      // In calibrated space, left = 10 - 1 = 9 mm. Conflict overlap = 12 - 9 = 3 mm.
      // Global shift optimization shifts right by 3 mm.
      // Composed offsetX = -1.0 + 3.0 = 2.0.
      final transform = context.resolveFor(row: 0, column: 0, absoluteSlotIndex: 0);
      expect(transform.offsetX, equals(2.0));
      expect(transform.offsetY, equals(0.0));
    });

    test('Conflict detection uses calibrated positions (prevents false conflicts)', () {
      // Calibration shifts right by 3 mm (left becomes 13 mm, which is > 12 mm margin)
      trayWithCalibration = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [
          PaperConfigurationReference(id: 'portrait_tpl', displayName: 'Portrait Template'),
        ],
        calibration: PrinterCalibration(
          enabled: true,
          calibrationRules: const [
            CalibrationRule(
              target: CalibrationTarget.sheet(),
              transformation: PrintStickerTransform(
                offsetX: 3, // shifts right by 3mm
              ),
            ),
          ],
        ),
        nonPrintableMarginLeft: 12, // Template starts at 10mm, so would conflict by 2mm
        nonPrintableMarginRight: 5,
        nonPrintableMarginTop: 5,
        nonPrintableMarginBottom: 5,
      );

      // High left margin at 12 mm
      final printerWithConflict = PrinterProfile(
        id: 'p1',
        displayName: 'High Margin Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'p1'),
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
        trays: [trayWithCalibration],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = orchestrator.resolve(
        template: template,
        printer: printerWithConflict,
        tray: trayWithCalibration,
        paperConfigurationId: 'portrait_tpl',
      );

      expect(result, isA<Success<PrintCoordinateContext, AppError>>());
      final context = (result as Success<PrintCoordinateContext, AppError>).value;

      // Since calibration shifted the sticker safely past the margin,
      // no conflicts are detected post-calibration. Only calibration is applied.
      final transform = context.resolveFor(row: 0, column: 0, absoluteSlotIndex: 0);
      expect(transform.offsetX, equals(3.0));
      expect(transform.offsetY, equals(0.0));
    });
  });
}
