import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('TemplatePrinterCompatibilityAnalyzer', () {
    const analyzer = TemplatePrinterCompatibilityAnalyzer();

    late LabelTemplate templatePortrait;
    late LabelTemplate templateLandscape;
    late PrinterTrayProfile tray;

    setUp(() {
      templatePortrait = const LabelTemplate(
        id: 'portrait_tpl',
        name: 'Portrait Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 2,
          rows: 3,
          columnGap: 5,
          rowGap: 5,
        ),
        stickerConfig: StickerConfig(
          widthMm: 92.5, // (210 - 20 - 5) / 2 = 92.5
          heightMm: 89, // (297 - 20 - 10) / 3 = 89
          cornerRadiusMm: 3,
          printableArea: [],
        ),
      );

      templateLandscape = const LabelTemplate(
        id: 'landscape_tpl',
        name: 'Landscape Template',
        sheetConfig: SheetConfig(
          pageWidth: 297,
          pageHeight: 210,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 3,
          rows: 2,
          columnGap: 5,
          rowGap: 5,
        ),
        stickerConfig: StickerConfig(
          widthMm: 89,
          heightMm: 92.5,
          cornerRadiusMm: 3,
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

    test('Identity mapping, no conflicts', () {
      final printer = PrinterProfile(
        id: 'p1',
        displayName: 'Zero Margin Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'p1'),
        capabilities: const PrinterCapabilities(
          supportsCustomPaperSize: true,
          supportsPortraitCustomPaper: true,
          supportsLandscapeCustomPaper: true,
          supportsManualFeed: false,
          supportsBorderlessPrinting: true,
          supportsTraySelection: false,
        ),
        optimizationPreferences: const OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          allowStickerSpecificAdjustment: true,
        ),
        trays: [tray],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = analyzer.analyze(
        template: templatePortrait,
        printer: printer,
        tray: tray,
      );

      expect(result.hasConflicts, isFalse);
      expect(result.recommendedOptimizationLevel, equals(OptimizationLevel.noModification));
    });

    test('Identity mapping, left edge conflict, global shift resolves it', () {
      final trayWithMargin = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
        nonPrintableMarginLeft: 12, // template has 10mm left margin, so it overflows by 2mm
      );
      final printer = PrinterProfile(
        id: 'p1',
        displayName: 'Left Margin Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'p1'),
        capabilities: const PrinterCapabilities(
          supportsCustomPaperSize: true,
          supportsPortraitCustomPaper: true,
          supportsLandscapeCustomPaper: true,
          supportsManualFeed: false,
          supportsBorderlessPrinting: false,
          supportsTraySelection: false,
        ),
        optimizationPreferences: const OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          allowStickerSpecificAdjustment: true,
        ),
        trays: [tray],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = analyzer.analyze(
        template: templatePortrait,
        printer: printer,
        tray: trayWithMargin,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.length, equals(1));
      expect(result.conflicts.first.affectedEdge, equals(EdgeGroup.left));
      expect(result.conflicts.first.overlapMm, closeTo(2.0, 0.001));
      // All stickers in the first column (indices 0, 2, 4) are affected
      expect(result.conflicts.first.affectedStickerIndices, equals([0, 2, 4]));
      expect(result.recommendedOptimizationLevel, equals(OptimizationLevel.globalTransform));
    });

    test('90 degree rotation mapping, conflict correctly detected in rotated space', () {
      // Portrait template on Landscape-only printer
      final trayWithMargin = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [],
        ),
        nonPrintableMarginLeft: 15, // margins in printer coordinates
      );
      final printer = PrinterProfile(
        id: 'p1',
        displayName: 'Landscape Only Printer',
        status: PrinterProfileStatus.active,
        printerIdentity: const PrinterIdentity(systemPrinterName: 'p1'),
        capabilities: const PrinterCapabilities(
          supportsCustomPaperSize: true,
          supportsPortraitCustomPaper: false, // forces rotation
          supportsLandscapeCustomPaper: true,
          supportsManualFeed: false,
          supportsBorderlessPrinting: false,
          supportsTraySelection: false,
        ),
        optimizationPreferences: const OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          allowStickerSpecificAdjustment: true,
        ),
        trays: [tray],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = analyzer.analyze(
        template: templatePortrait,
        printer: printer,
        tray: trayWithMargin,
      );

      // In rotated space, the template's Top-Left (which was safe at 10mm margins) is rotated.
      // The physical sheet coordinates are rotated 90 deg clockwise.
      // Original y bounds: y goes from 10 to 287 (for the grid).
      // Rotated X coordinates: x' = pageHeight - y.
      // So bottom edge of grid (y=287) maps to x' = 297 - 287 = 10mm.
      // Top edge of grid (y=10) maps to x' = 297 - 10 = 287mm.
      // Since printerMarginLeft is 15mm, x' = 10mm is less than 15mm, causing a conflict on Left!
      expect(result.hasConflicts, isTrue);
      expect(result.conflicts.any((c) => c.affectedEdge == EdgeGroup.left), isTrue);
    });

    test('Rotated mapping (landscape template on portrait-only printer)', () {
      final printer = PrinterProfile(
        id: 'p1',
        displayName: 'Portrait Only Printer',
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
        optimizationPreferences: const OptimizationPreferences(
          allowScaling: true,
          allowTranslation: true,
          allowStickerSpecificAdjustment: true,
        ),
        trays: [tray],
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      final result = analyzer.analyze(
        template: templateLandscape,
        printer: printer,
        tray: tray,
      );

      // Landscape template on portrait-only printer is now handled via rotation
      // instead of being rejected as unsupported. The rotation swaps axes so
      // coordinates are correctly projected into printer space. No conflicts
      // expected here since the tray has 0mm margins by default.
      expect(result.hasConflicts, isFalse);
      expect(result.recommendedOptimizationLevel, equals(OptimizationLevel.noModification));
    });
  });
}
