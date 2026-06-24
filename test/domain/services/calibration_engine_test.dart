import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationRuleMatcher Tests', () {
    const totalRows = 4;
    const totalColumns = 3;

    test('Sheet target matches any slot', () {
      const rule = CalibrationRule(
        target: CalibrationTarget.sheet(),
        transformation: PrintStickerTransform.identity(),
      );

      final match = CalibrationRuleMatcher.matches(
        rule: rule,
        row: 1,
        column: 2,
        absoluteStickerIndex: 5,
        totalRows: totalRows,
        totalColumns: totalColumns,
      );

      expect(match, isTrue);
    });

    test('Row target matches correct row only', () {
      const rule = CalibrationRule(
        target: CalibrationTarget.row(2),
        transformation: PrintStickerTransform.identity(),
      );

      expect(
        CalibrationRuleMatcher.matches(
          rule: rule,
          row: 2,
          column: 0,
          absoluteStickerIndex: 6,
          totalRows: totalRows,
          totalColumns: totalColumns,
        ),
        isTrue,
      );

      expect(
        CalibrationRuleMatcher.matches(
          rule: rule,
          row: 1,
          column: 0,
          absoluteStickerIndex: 3,
          totalRows: totalRows,
          totalColumns: totalColumns,
        ),
        isFalse,
      );
    });

    test('Column target matches correct column only', () {
      const rule = CalibrationRule(
        target: CalibrationTarget.column(1),
        transformation: PrintStickerTransform.identity(),
      );

      expect(
        CalibrationRuleMatcher.matches(
          rule: rule,
          row: 0,
          column: 1,
          absoluteStickerIndex: 1,
          totalRows: totalRows,
          totalColumns: totalColumns,
        ),
        isTrue,
      );

      expect(
        CalibrationRuleMatcher.matches(
          rule: rule,
          row: 0,
          column: 2,
          absoluteStickerIndex: 2,
          totalRows: totalRows,
          totalColumns: totalColumns,
        ),
        isFalse,
      );
    });

    test('Sticker target matches correct absolute index only', () {
      const rule = CalibrationRule(
        target: CalibrationTarget.sticker(7),
        transformation: PrintStickerTransform.identity(),
      );

      expect(
        CalibrationRuleMatcher.matches(
          rule: rule,
          row: 2,
          column: 1,
          absoluteStickerIndex: 7,
          totalRows: totalRows,
          totalColumns: totalColumns,
        ),
        isTrue,
      );

      expect(
        CalibrationRuleMatcher.matches(
          rule: rule,
          row: 2,
          column: 2,
          absoluteStickerIndex: 8,
          totalRows: totalRows,
          totalColumns: totalColumns,
        ),
        isFalse,
      );
    });

    group('Edge target matching', () {
      const leftEdgeRule = CalibrationRule(
        target: CalibrationTarget.edge(EdgeGroup.left),
        transformation: PrintStickerTransform.identity(),
      );
      const rightEdgeRule = CalibrationRule(
        target: CalibrationTarget.edge(EdgeGroup.right),
        transformation: PrintStickerTransform.identity(),
      );
      const topEdgeRule = CalibrationRule(
        target: CalibrationTarget.edge(EdgeGroup.top),
        transformation: PrintStickerTransform.identity(),
      );
      const bottomEdgeRule = CalibrationRule(
        target: CalibrationTarget.edge(EdgeGroup.bottom),
        transformation: PrintStickerTransform.identity(),
      );

      test('Left edge matches column == 0', () {
        expect(
          CalibrationRuleMatcher.matches(
            rule: leftEdgeRule,
            row: 1,
            column: 0,
            absoluteStickerIndex: 3,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: leftEdgeRule,
            row: 1,
            column: 1,
            absoluteStickerIndex: 4,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isFalse,
        );
      });

      test('Right edge matches column == totalColumns - 1', () {
        expect(
          CalibrationRuleMatcher.matches(
            rule: rightEdgeRule,
            row: 1,
            column: 2,
            absoluteStickerIndex: 5,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: rightEdgeRule,
            row: 1,
            column: 1,
            absoluteStickerIndex: 4,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isFalse,
        );
      });

      test('Top edge matches row == 0', () {
        expect(
          CalibrationRuleMatcher.matches(
            rule: topEdgeRule,
            row: 0,
            column: 1,
            absoluteStickerIndex: 1,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: topEdgeRule,
            row: 1,
            column: 1,
            absoluteStickerIndex: 4,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isFalse,
        );
      });

      test('Bottom edge matches row == totalRows - 1', () {
        expect(
          CalibrationRuleMatcher.matches(
            rule: bottomEdgeRule,
            row: 3,
            column: 1,
            absoluteStickerIndex: 10,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: bottomEdgeRule,
            row: 2,
            column: 1,
            absoluteStickerIndex: 7,
            totalRows: totalRows,
            totalColumns: totalColumns,
          ),
          isFalse,
        );
      });

      test('Single-row / single-column boundary edge cases match multiple edges simultaneously', () {
        // 1x1 sheet: slot at (0,0) is left, right, top, and bottom
        expect(
          CalibrationRuleMatcher.matches(
            rule: leftEdgeRule,
            row: 0,
            column: 0,
            absoluteStickerIndex: 0,
            totalRows: 1,
            totalColumns: 1,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: rightEdgeRule,
            row: 0,
            column: 0,
            absoluteStickerIndex: 0,
            totalRows: 1,
            totalColumns: 1,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: topEdgeRule,
            row: 0,
            column: 0,
            absoluteStickerIndex: 0,
            totalRows: 1,
            totalColumns: 1,
          ),
          isTrue,
        );
        expect(
          CalibrationRuleMatcher.matches(
            rule: bottomEdgeRule,
            row: 0,
            column: 0,
            absoluteStickerIndex: 0,
            totalRows: 1,
            totalColumns: 1,
          ),
          isTrue,
        );
      });
    });
  });

  group('CalibrationTransformComposer Tests', () {
    test('Empty rule list produces identity transform', () {
      final result = CalibrationTransformComposer.compose(const []);
      expect(result, equals(const PrintStickerTransform.identity()));
    });

    test('Translation offsets are additive', () {
      final rules = [
        const CalibrationRule(
          target: CalibrationTarget.sheet(),
          transformation: PrintStickerTransform(offsetX: 1.5, offsetY: -2),
        ),
        const CalibrationRule(
          target: CalibrationTarget.row(1),
          transformation: PrintStickerTransform(offsetX: -0.5, offsetY: 3.5),
        ),
      ];

      final result = CalibrationTransformComposer.compose(rules);
      expect(result.offsetX, equals(1.0));
      expect(result.offsetY, equals(1.5));
    });

    test('Translation-only transforms do not override/reset scaling transforms', () {
      final rules = [
        const CalibrationRule(
          target: CalibrationTarget.sheet(),
          transformation: PrintStickerTransform(scaleX: 0.95, scaleY: 0.95),
        ),
        const CalibrationRule(
          target: CalibrationTarget.sticker(1),
          transformation: PrintStickerTransform(offsetX: 2, offsetY: 3),
        ),
      ];

      final result = CalibrationTransformComposer.compose(rules);
      expect(result.offsetX, equals(2.0));
      expect(result.offsetY, equals(3.0));
      expect(result.scaleX, equals(0.95));
      expect(result.scaleY, equals(0.95));
    });

    test('Scenario A: Cross-axis edge composition', () {
      final rules = [
        const CalibrationRule(
          target: CalibrationTarget.sheet(),
          transformation: PrintStickerTransform(scaleX: 0.98, scaleY: 0.98),
        ),
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.left),
          transformation: PrintStickerTransform(scaleX: 0.95, anchorX: 0),
        ),
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.top),
          transformation: PrintStickerTransform(scaleY: 0.92, anchorY: 0),
        ),
      ];

      final result = CalibrationTransformComposer.compose(rules);
      expect(result.scaleX, equals(0.95));
      expect(result.scaleY, equals(0.92));
      expect(result.anchorX, equals(0.0));
      expect(result.anchorY, equals(0.0));
    });

    test('Scenario B: Same-axis equal specificity conflict chooses smallest scaleX', () {
      final rules = [
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.left),
          transformation: PrintStickerTransform(scaleX: 0.97),
        ),
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.right),
          transformation: PrintStickerTransform(scaleX: 0.95),
        ),
      ];

      final result = CalibrationTransformComposer.compose(rules);
      expect(result.scaleX, equals(0.95));
    });

    test('Scenario C: Translation overlap adds up correctly', () {
      final rules = [
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.left),
          transformation: PrintStickerTransform(offsetX: 1),
        ),
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.right),
          transformation: PrintStickerTransform(offsetX: -1),
        ),
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.top),
          transformation: PrintStickerTransform(offsetY: 2),
        ),
        const CalibrationRule(
          target: CalibrationTarget.edge(EdgeGroup.bottom),
          transformation: PrintStickerTransform(offsetY: -2),
        ),
      ];

      final result = CalibrationTransformComposer.compose(rules);
      expect(result.offsetX, equals(0.0));
      expect(result.offsetY, equals(0.0));
    });

    test('Anchors default to 0.5 when no non-identity scale rule applies', () {
      final rules = [
        const CalibrationRule(
          target: CalibrationTarget.sheet(),
          transformation: PrintStickerTransform(offsetX: 5),
        ),
      ];

      final result = CalibrationTransformComposer.compose(rules);
      expect(result.scaleX, equals(1.0));
      expect(result.scaleY, equals(1.0));
      expect(result.anchorX, equals(0.5));
      expect(result.anchorY, equals(0.5));
    });
  });

  group('PrinterCalibrationCoordinateResolver Tests', () {
    final tray = PrinterTrayProfile(
      trayIdentifier: 'tray_1',
      displayName: 'Tray 1',
      supportedPaperConfigurations: const [
        PaperConfigurationReference(id: 'paper_A4', displayName: 'A4 Paper'),
        PaperConfigurationReference(id: 'paper_Letter', displayName: 'Letter Paper'),
      ],
      calibration: PrinterCalibration(
        enabled: true,
        calibrationRules: const [
          CalibrationRule(
            target: CalibrationTarget.sheet(),
            transformation: PrintStickerTransform(offsetX: 1, scaleX: 0.98),
          ),
          CalibrationRule(
            target: CalibrationTarget.row(1),
            transformation: PrintStickerTransform(offsetY: 2, scaleY: 0.95),
          ),
        ],
      ),
    );

    const sheetConfig = SheetConfig(
      pageWidth: 210,
      pageHeight: 297,
      marginTop: 10,
      marginBottom: 10,
      marginLeft: 10,
      marginRight: 10,
      columns: 2,
      rows: 2,
      columnGap: 2,
      rowGap: 2,
    );

    test('Returns validation failure if paper configuration is not supported', () {
      final request = CalibrationRequest(
        tray: tray,
        paperConfigId: 'paper_Legal', // Unsupported
        sheetConfig: sheetConfig,
      );

      final result = PrinterCalibrationCoordinateResolver.resolve(request);

      expect(result, isA<Failure<PrintCoordinateContext, ValidationError>>());
      final error = (result as Failure<PrintCoordinateContext, ValidationError>).error;
      expect(error.message, contains('not supported by the tray'));
    });

    test('Returns identity context when tray calibration is disabled', () {
      final disabledTray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [
          PaperConfigurationReference(id: 'paper_A4', displayName: 'A4 Paper'),
        ],
        calibration: PrinterCalibration(
          enabled: false,
          calibrationRules: const [
            CalibrationRule(
              target: CalibrationTarget.sheet(),
              transformation: PrintStickerTransform(offsetX: 1),
            ),
          ],
        ),
      );

      final request = CalibrationRequest(
        tray: disabledTray,
        paperConfigId: 'paper_A4',
        sheetConfig: sheetConfig,
      );

      final result = PrinterCalibrationCoordinateResolver.resolve(request);

      expect(result, isA<Success<PrintCoordinateContext, ValidationError>>());
      final context = (result as Success<PrintCoordinateContext, ValidationError>).value;
      expect(context.isIdentity, isTrue);
    });

    test('Resolves overlapping rules correctly per slot and performs memory optimization', () {
      final request = CalibrationRequest(
        tray: tray,
        paperConfigId: 'paper_A4',
        sheetConfig: sheetConfig, // 2x2 = 4 slots
      );

      final result = PrinterCalibrationCoordinateResolver.resolve(request);

      expect(result, isA<Success<PrintCoordinateContext, ValidationError>>());
      final context = (result as Success<PrintCoordinateContext, ValidationError>).value;

      // Slots on row 0: indexes 0 and 1
      // Matches: sheet target (offsetX: 1.0, scaleX: 0.98)
      // Resulting: offsetX: 1.0, scaleX: 0.98, anchorX: 0.5, scaleY: 1.0, anchorY: 0.5
      final transform0 = context.stickerTransforms[0];
      expect(transform0, isNotNull);
      expect(transform0!.offsetX, equals(1.0));
      expect(transform0.offsetY, equals(0.0));
      expect(transform0.scaleX, equals(0.98));
      expect(transform0.scaleY, equals(1.0));

      // Slots on row 1: indexes 2 and 3
      // Matches: sheet target (offsetX: 1.0, scaleX: 0.98) AND row 1 target (offsetY: 2.0, scaleY: 0.95)
      // Resulting: offsetX: 1.0, offsetY: 2.0, scaleX: 0.98, scaleY: 0.95
      final transform2 = context.stickerTransforms[2];
      expect(transform2, isNotNull);
      expect(transform2!.offsetX, equals(1.0));
      expect(transform2.offsetY, equals(2.0));
      expect(transform2.scaleX, equals(0.98));
      expect(transform2.scaleY, equals(0.95));

      // Memory optimization check: globalTransform and others are identity.
      // stickerTransforms has exactly 4 items (since all 4 slots have non-identity transforms).
      expect(context.stickerTransforms.length, equals(4));
      expect(context.globalTransform, equals(const PrintStickerTransform.identity()));
      expect(context.rowTransforms, isEmpty);
      expect(context.columnTransforms, isEmpty);
    });

    test('Memory optimization omits identity transforms from map', () {
      // Create a tray rule that matches ONLY row 1 (index 2 and 3)
      final customTray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: const [
          PaperConfigurationReference(id: 'paper_A4', displayName: 'A4 Paper'),
        ],
        calibration: PrinterCalibration(
          enabled: true,
          calibrationRules: const [
            CalibrationRule(
              target: CalibrationTarget.row(1),
              transformation: PrintStickerTransform(offsetX: 1),
            ),
          ],
        ),
      );

      final request = CalibrationRequest(
        tray: customTray,
        paperConfigId: 'paper_A4',
        sheetConfig: sheetConfig, // 2x2 = 4 slots
      );

      final result = PrinterCalibrationCoordinateResolver.resolve(request);
      final context = (result as Success<PrintCoordinateContext, ValidationError>).value;

      // Row 0 (index 0 and 1) should be identity, thus omitted from the map.
      expect(context.stickerTransforms.containsKey(0), isFalse);
      expect(context.stickerTransforms.containsKey(1), isFalse);

      // Row 1 (index 2 and 3) should be non-identity, thus included in the map.
      expect(context.stickerTransforms.containsKey(2), isTrue);
      expect(context.stickerTransforms.containsKey(3), isTrue);
      expect(context.stickerTransforms[2]!.offsetX, equals(1.0));

      expect(context.stickerTransforms.length, equals(2));
    });
  });
}
