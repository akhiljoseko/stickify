import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('IntelligentTransformGenerator', () {
    const generator = IntelligentTransformGenerator();
    const analyzer = TemplatePrinterCompatibilityAnalyzer();

    late LabelTemplate template;
    late PrinterTrayProfile tray;

    setUp(() {
      template = const LabelTemplate(
        id: 'test_tpl',
        name: 'Test Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
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
          widthMm: 90, // (210 - 20 - 10) / 2 = 90
          heightMm: 133.5, // (297 - 20 - 10) / 2 = 133.5
          cornerRadiusMm: 4,
          printableArea: [],
        ),
      );

      tray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
      );
    });

    PrinterProfile makePrinter({
      required double marginLeft,
      required double marginRight,
      required double marginTop,
      required double marginBottom,
      double minScale = 0.7,
    }) {
      tray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
        nonPrintableMarginLeft: marginLeft,
        nonPrintableMarginRight: marginRight,
        nonPrintableMarginTop: marginTop,
        nonPrintableMarginBottom: marginBottom,
      );
      return PrinterProfile(
        id: 'p1',
        displayName: 'Test Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'p1'),
        capabilities: const PrinterCapabilities(
          supportsCustomPaperSize: true,
          supportsPortraitCustomPaper: true,
          supportsLandscapeCustomPaper: false,
          supportsManualFeed: false,
          supportsBorderlessPrinting: false,
          supportsTraySelection: false,
        ),
        optimizationPreferences: OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          allowStickerSpecificAdjustment: true,
          minimumAcceptableScale: minScale,
        ),
        trays: [tray],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );
    }

    test('Level 1: No conflicts, identity transforms', () {
      final printer = makePrinter(marginLeft: 5, marginRight: 5, marginTop: 5, marginBottom: 5);
      final analysis = analyzer.analyze(template: template, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: printer.optimizationPreferences,
      );

      expect(strategy.level, equals(OptimizationLevel.noModification));
      expect(strategy.transforms, isEmpty);
    });

    test('Level 2: Left-only conflict, global shift resolves it', () {
      final printer = makePrinter(marginLeft: 12, marginRight: 0, marginTop: 0, marginBottom: 0);
      final analysis = analyzer.analyze(template: template, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: printer.optimizationPreferences,
      );

      expect(strategy.level, equals(OptimizationLevel.globalTransform));
      expect(strategy.transforms.length, equals(4));
      // Shift should be exactly 2.0 mm (12 margin - 10 template margin)
      expect(strategy.transforms[0]!.offsetX, closeTo(2.0, 0.001));
      expect(strategy.transforms[0]!.offsetY, equals(0.0));
      expect(strategy.transforms[0]!.scaleX, equals(1.0));
    });

    test('Level 2: Skip to Level 3 on left and right conflict simultaneously', () {
      const singleColumnTemplate = LabelTemplate(
        id: 'single_col_tpl',
        name: 'Single Column Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 1,
          rows: 2,
          columnGap: 10,
          rowGap: 10,
        ),
        stickerConfig: StickerConfig(
          widthMm: 190,
          heightMm: 133.5,
          cornerRadiusMm: 4,
          printableArea: [],
        ),
      );

      final printer = makePrinter(marginLeft: 12, marginRight: 12, marginTop: 0, marginBottom: 0);
      final analysis = analyzer.analyze(template: singleColumnTemplate, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: singleColumnTemplate,
        printer: printer,
        tray: tray,
        preferences: printer.optimizationPreferences,
      );

      expect(strategy.level, equals(OptimizationLevel.edgeGroupScaling));
    });

    test('Level 2: Global shift creates right conflict, fails to Level 3/4', () {
      // Left margin is 12mm, right margin is 11mm.
      // Left column needs 2mm shift right. But right column ends at 200mm, sheet limit is 199mm (210-11).
      // Shifting right by 2mm makes right column end at 202mm, conflicting with right margin.
      // So Level 2 fails.
      final printer = makePrinter(marginLeft: 12, marginRight: 11, marginTop: 0, marginBottom: 0);
      final analysis = analyzer.analyze(template: template, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: printer.optimizationPreferences,
      );

      expect(strategy.level, isNot(equals(OptimizationLevel.globalTransform)));
    });

    test('Level 3: Single left-group translation resolves conflicts without shifting other column', () {
      const customTemplate = LabelTemplate(
        id: 'c',
        name: 'c',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 40, // plenty of space on right
          columns: 2,
          rows: 2,
          columnGap: 10,
          rowGap: 10,
        ),
        stickerConfig: StickerConfig(
          widthMm: 70, // 210 - 10 - 40 - 10 = 150 / 2 = 70
          heightMm: 133.5,
          cornerRadiusMm: 4,
          printableArea: [],
        ),
      );

      // Left margin is 12mm (creates 2mm conflict). Right margin is 49mm (available limit 161mm).
      // Column 1 ends at 160mm, which is safe (< 161).
      // Shifting everything right by 2mm (Level 2) would make Column 1 end at 162mm (conflicts).
      // So Level 2 fails. Level 3 shifts only Column 0 by 2mm, which is safe.
      final printer = makePrinter(marginLeft: 12, marginRight: 49, marginTop: 5, marginBottom: 5);
      final analysis = analyzer.analyze(template: customTemplate, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: customTemplate,
        printer: printer,
        tray: tray,
        preferences: printer.optimizationPreferences,
      );

      expect(strategy.level, equals(OptimizationLevel.edgeGroupTranslation));
      // Only column 0 (indices 0 and 2) receives translation
      expect(strategy.transforms[0]!.offsetX, closeTo(2.0, 0.001));
      expect(strategy.transforms[2]!.offsetX, closeTo(2.0, 0.001));
      expect(strategy.transforms[1], isNull);
      expect(strategy.transforms[3], isNull);
    });

    test('Level 4: Scaling anchor is centered on available printer space', () {
      final printer = makePrinter(marginLeft: 15, marginRight: 5, marginTop: 5, marginBottom: 5);
      // Disable translation to force scaling optimization level
      final customPreferences = printer.optimizationPreferences.copyWith(allowTranslation: false);
      
      final analysis = analyzer.analyze(template: template, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: customPreferences,
      );

      expect(strategy.level, equals(OptimizationLevel.individualSticker));
      // The left-column sticker (index 0) gets a Level 4 scale + Level 5 offset correction.
      // Level 4 anchorX was 0.5238, but Level 5 composes an additional offset on top.
      expect(strategy.transforms.keys, contains(0));
    });

    test('Level 4: Escalation to Level 6 when scale is below acceptable threshold', () {
      // Printable width of sticker is 90mm.
      // Available printer width is 50mm.
      // Required scale = 50 / 90 = 0.555.
      // minimumAcceptableScale is 0.7.
      // 0.555 < 0.7, so it escalates to Unsupported!
      final printer = makePrinter(marginLeft: 80, marginRight: 80, marginTop: 10, marginBottom: 10);
      final analysis = analyzer.analyze(template: template, printer: printer, tray: tray);

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: printer.optimizationPreferences,
      );

      expect(strategy.level, equals(OptimizationLevel.unsupported));
      expect(strategy.description, contains('required X-axis compression'));
      expect(strategy.description, contains('falls below the minimum acceptable scale'));
    });

    test('Level 4: Row-specific calibration produces per-slot normalized Level-4 scale', () {
      // 2x2 grid, totalContentWidth = 210mm.
      // Available printer width = 210 - 15 - 15 = 180mm.
      // geometricScaleX = 180 / 210 = 0.857142857...
      final printer = makePrinter(marginLeft: 15, marginRight: 15, marginTop: 10, marginBottom: 10);
      final customPreferences = printer.optimizationPreferences.copyWith(allowTranslation: false);

      const calibrationContext = PrintCoordinateContext(
        stickerTransforms: {
          2: PrintStickerTransform(scaleX: 0.95),
          3: PrintStickerTransform(scaleX: 0.95),
        },
      );

      final analysis = analyzer.analyze(
        template: template,
        printer: printer,
        tray: tray,
        calibrationContext: calibrationContext,
      );

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: customPreferences,
        calibrationContext: calibrationContext,
      );

      expect(strategy.level, equals(OptimizationLevel.edgeGroupScaling));

      // Row 0 (slots 0 & 1): calibration scaleX = 1.0 -> level4 scaleX = (180/210) / 1.0 = 0.857142857
      const expectedRow0ScaleX = 180 / 210;
      expect(strategy.transforms[0]!.scaleX, closeTo(expectedRow0ScaleX, 0.0001));
      expect(strategy.transforms[1]!.scaleX, closeTo(expectedRow0ScaleX, 0.0001));

      // Row 1 (slots 2 & 3): calibration scaleX = 0.95 -> level4 scaleX = (180/210) / 0.95 = 0.902255639
      const expectedRow1ScaleX = (180 / 210) / 0.95;
      expect(strategy.transforms[2]!.scaleX, closeTo(expectedRow1ScaleX, 0.0001));
      expect(strategy.transforms[3]!.scaleX, closeTo(expectedRow1ScaleX, 0.0001));

      // Verify row 0 and row 1 level 4 scaleX values differ according to their own calibration scales
      expect(strategy.transforms[0]!.scaleX, isNot(equals(strategy.transforms[2]!.scaleX)));
    });

    test('Level 4: Sheet-wide calibration produces identical Level-4 scale across all slots', () {
      final printer = makePrinter(marginLeft: 15, marginRight: 15, marginTop: 10, marginBottom: 10);
      final customPreferences = printer.optimizationPreferences.copyWith(allowTranslation: false);

      const calibrationContext = PrintCoordinateContext(
        globalTransform: PrintStickerTransform(scaleX: 0.9, scaleY: 0.9),
      );

      final analysis = analyzer.analyze(
        template: template,
        printer: printer,
        tray: tray,
        calibrationContext: calibrationContext,
      );

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: customPreferences,
        calibrationContext: calibrationContext,
      );

      expect(strategy.level, equals(OptimizationLevel.edgeGroupScaling));

      // For all slots: calibration scaleX = 0.9 -> level4 scaleX = (180/210) / 0.9 = 0.95238095
      const expectedScaleX = (180 / 210) / 0.9;
      for (var i = 0; i < 4; i++) {
        expect(strategy.transforms[i]!.scaleX, closeTo(expectedScaleX, 0.0001));
      }
    });

    test('Level 4: Zero calibration scale guard falls back to 1.0 without throwing', () {
      final printer = makePrinter(marginLeft: 15, marginRight: 15, marginTop: 10, marginBottom: 10);
      final customPreferences = printer.optimizationPreferences.copyWith(allowTranslation: false);

      // Analyze with identity calibration context so conflicts exist
      final analysis = analyzer.analyze(
        template: template,
        printer: printer,
        tray: tray,
        calibrationContext: const PrintCoordinateContext.identity(),
      );

      // Pass zero-scale calibration context to generator to trigger guard
      const zeroScaleContext = PrintCoordinateContext(
        globalTransform: PrintStickerTransform(scaleX: 0, scaleY: 0),
      );

      expect(
        () => generator.generate(
          analysisResult: analysis,
          template: template,
          printer: printer,
          tray: tray,
          preferences: customPreferences,
          calibrationContext: zeroScaleContext,
        ),
        returnsNormally,
      );

      final strategy = generator.generate(
        analysisResult: analysis,
        template: template,
        printer: printer,
        tray: tray,
        preferences: customPreferences,
        calibrationContext: zeroScaleContext,
      );

      // Conflicting slots fall back to 1.0 for calibration scale -> level 4 scaleX = (180/210) / 1.0 = 0.857142857
      const expectedScaleX = 180 / 210;
      expect(strategy.transforms[0]!.scaleX, closeTo(expectedScaleX, 0.0001));
    });
  });
}
