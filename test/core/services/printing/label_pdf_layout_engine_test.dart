import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LabelPdfLayoutEngine engine;

  const testProduct = Product(
    id: 'prod-1',
    name: 'Cold Brew Coffee',
    sku: 'CB-100',
  );

  const testVariant = ProductVariant(
    name: 'Single Bottle',
    quantity: 1,
    unit: 'bottle',
    wholesale: 2.5,
    mrp: 3.5,
    sku: 'CB-100-BTL',
  );

  setUp(() {
    PdfElementRendererRegistry.registerDefaults();
    engine = const LabelPdfLayoutEngine(useIsolate: false);
  });

  group('LabelPdfLayoutEngine Output Inspection Tests', () {
    test(
      'buildPdfBytes compiles custom page format correctly to MediaBox',
      () async {
        const template = LabelTemplate(
          id: 'temp-custom-size',
          name: 'Custom Size Template',
          sheetConfig: SheetConfig(
            pageWidth: 180,
            pageHeight: 300,
            marginTop: 5,
            marginBottom: 5,
            marginLeft: 5,
            marginRight: 5,
            columns: 2,
            rows: 2,
            columnGap: 5,
            rowGap: 5,
          ),
          stickerConfig: StickerConfig(
            widthMm: 80,
            heightMm: 50,
            cornerRadiusMm: 2,
            printableArea: [],
          ),
        );

        final pdfBytes = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
        );

        expect(pdfBytes, isNotNull);

        // Inspect uncompressed PDF string for MediaBox dimensions
        final pdfString = String.fromCharCodes(pdfBytes);

        // Expected width in points = 180mm * 2.834645669291339 = 510.236 points
        // Expected height in points = 300mm * 2.834645669291339 = 850.394 points
        final mediaBoxRegex = RegExp(
          r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)\s*\]',
        );
        final match = mediaBoxRegex.firstMatch(pdfString);
        expect(match, isNotNull, reason: 'MediaBox must be defined in the PDF');

        final parsedWidth = double.parse(match!.group(1)!);
        final parsedHeight = double.parse(match.group(2)!);
        expect(parsedWidth, closeTo(510.236, 0.1));
        expect(parsedHeight, closeTo(850.394, 0.1));
      },
    );

    test(
      'adds polygon clipping operators when custom shape configured',
      () async {
        const template = LabelTemplate(
          id: 'temp-polygon-clip',
          name: 'Polygon Clip Template',
          sheetConfig: SheetConfig(
            pageWidth: 210,
            pageHeight: 297,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 2,
            rows: 4,
            columnGap: 5,
            rowGap: 5,
          ),
          stickerConfig: StickerConfig(
            widthMm: 80,
            heightMm: 50,
            cornerRadiusMm: 2,
            printableArea: [
              StickerPoint(0, 0),
              StickerPoint(80, 0),
              StickerPoint(40, 50),
            ],
          ),
        );

        final pdfBytes = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);

        // Verify clipping operators (W) and path close operators (h) are present
        expect(
          pdfString,
          contains(' W'),
          reason: 'PDF must contain a clipping operator (W)',
        );
        expect(
          pdfString,
          contains(' h'),
          reason: 'PDF must contain a path close operator (h)',
        );
      },
    );

    test(
      'applies correct Y-flip scaling order for polygon printableArea when scaleY != 1.0',
      () async {
        const template = LabelTemplate(
          id: 'temp-polygon-scaled',
          name: 'Polygon Scaled Template',
          sheetConfig: SheetConfig(
            pageWidth: 210,
            pageHeight: 297,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 1,
            rows: 1,
            columnGap: 0,
            rowGap: 0,
          ),
          stickerConfig: StickerConfig(
            widthMm: 80,
            heightMm: 50,
            cornerRadiusMm: 0,
            printableArea: [
              StickerPoint(10, 10),
              StickerPoint(70, 10),
              StickerPoint(70, 40),
              StickerPoint(10, 40),
            ],
          ),
        );

        const coordinateContext = PrintCoordinateContext(
          globalTransform: PrintStickerTransform(
            scaleX: 0.95,
            scaleY: 0.9,
          ),
        );

        final pdfBytes = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
          coordinateContext: coordinateContext,
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);

        // Expected Y coordinate for point (10, 10) with height 50mm, scaleY 0.9:
        // Correct top-aligned formula: 50 - (10 * 0.9) = 41.0 mm -> 41.0 * 2.834645669291339 = 116.220 pt
        // Expected X coordinate for point (10, 10) with scaleX 0.95:
        // 10 * 0.95 = 9.5 mm -> 9.5 * 2.834645669291339 = 26.929 pt
        final moveToRegex = RegExp(r'([0-9.]+)\s+([0-9.]+)\s+m');
        final matches = moveToRegex.allMatches(pdfString).toList();
        expect(matches, isNotEmpty, reason: 'PDF must contain moveTo (m) path operators');

        final polygonMoveTo = matches.firstWhere(
          (m) {
            final x = double.parse(m.group(1)!);
            final y = double.parse(m.group(2)!);
            return (x - 26.929).abs() < 0.1 && (y - 116.220).abs() < 0.1;
          },
          orElse: () => throw StateError(
            'Could not find moveTo matching corrected formula (26.929 pt, 116.220 pt). PDF stream:\n$pdfString',
          ),
        );
        expect(polygonMoveTo, isNotNull);
      },
    );

    test(
      'produces identical polygon Y-flip coordinates for identity scale (scaleX=1.0, scaleY=1.0)',
      () async {
        const template = LabelTemplate(
          id: 'temp-polygon-identity',
          name: 'Polygon Identity Template',
          sheetConfig: SheetConfig(
            pageWidth: 210,
            pageHeight: 297,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 1,
            rows: 1,
            columnGap: 0,
            rowGap: 0,
          ),
          stickerConfig: StickerConfig(
            widthMm: 80,
            heightMm: 50,
            cornerRadiusMm: 0,
            printableArea: [
              StickerPoint(10, 10),
              StickerPoint(70, 10),
              StickerPoint(70, 40),
              StickerPoint(10, 40),
            ],
          ),
        );

        final pdfBytesIdentity = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
          coordinateContext: const PrintCoordinateContext.identity(),
        );

        final pdfString = String.fromCharCodes(pdfBytesIdentity);

        // Expected Y coordinate for point (10, 10) with height 50mm, scaleY 1.0:
        // (50 - 10) * 1.0 = 40.0 mm -> 40.0 * 2.834645669291339 = 113.385 pt
        // Expected X coordinate for point (10, 10) with scaleX 1.0:
        // 10 * 1.0 = 10.0 mm -> 10.0 * 2.834645669291339 = 28.346 pt
        final moveToRegex = RegExp(r'([0-9.]+)\s+([0-9.]+)\s+m');
        final matches = moveToRegex.allMatches(pdfString).toList();

        final match = matches.firstWhere(
          (m) {
            final x = double.parse(m.group(1)!);
            final y = double.parse(m.group(2)!);
            return (x - 28.346).abs() < 0.1 && (y - 113.385).abs() < 0.1;
          },
          orElse: () => throw StateError('Could not find identity moveTo'),
        );
        expect(match, isNotNull);
      },
    );

    test(
      'buildPdfBytes applies physical margin shifts to landscape custom sheets on Windows',
      () async {
        const template = LabelTemplate(
          id: 'temp-landscape-shift',
          name: 'Landscape Shift Template',
          sheetConfig: SheetConfig(
            pageWidth: 208,
            pageHeight: 180,
            marginTop: 0,
            marginBottom: 0,
            marginLeft: 0,
            marginRight: 0,
            columns: 1,
            rows: 1,
            columnGap: 0,
            rowGap: 0,
          ),
          stickerConfig: StickerConfig(
            widthMm: 208,
            heightMm: 180,
            cornerRadiusMm: 0,
            printableArea: [],
          ),
          elements: [
            TextElementBlueprint(
              id: 'text-test',
              x: 10,
              y: 10,
              width: 100,
              height: 20,
              rotation: 0,
              content: 'Shift Test',
              isDynamic: false,
              fontSize: 12,
              fontWeightValue: 400,
              textAlign: BlueprintTextAlign.left,
              colorHex: 0xFF000000,
            ),
          ],
        );

        // 1. Without physical format margins (no shift)
        final pdfBytesNoShift = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
        );

        // 2. With physical format margins (shift should be applied)
        final pdfBytesWithShift = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
          physicalFormat: const PdfPageFormat(
            208 * PdfPageFormat.mm,
            180 * PdfPageFormat.mm,
            marginLeft: 15 * PdfPageFormat.mm, // 15mm left shift
            marginTop: 10 * PdfPageFormat.mm,  // 10mm top shift
          ),
        );

        final pdfNoShiftString = String.fromCharCodes(pdfBytesNoShift);
        final pdfWithShiftString = String.fromCharCodes(pdfBytesWithShift);

        expect(pdfBytesNoShift, isNotNull);
        expect(pdfBytesWithShift, isNotNull);
        expect(pdfNoShiftString != pdfWithShiftString, isTrue, 
            reason: 'Generated PDF with shift must differ from no-shift PDF');

        // Extract translation matrices from the generated shifted PDF stream.
        final cmRegex = RegExp(r'1\s+0\s+0\s+1\s+([0-9.-]+)\s+([0-9.-]+)\s+cm');
        final matches = cmRegex.allMatches(pdfWithShiftString).toList();

        // Verify that the sticker slot translation (which corresponds to slot position on the sheet)
        // was shifted vertically by -10mm (-28.346 pt) but remains unshifted horizontally (tx = 0).
        final hasVerticalShiftOnly = matches.any((m) {
          final tx = double.parse(m.group(1)!);
          final ty = double.parse(m.group(2)!);
          return tx == 0.0 && (ty - -28.34646).abs() < 0.01;
        });

        expect(
          hasVerticalShiftOnly,
          isTrue,
          reason: 'Sticker slot must be shifted vertically by -10mm (-28.346 pt) and not horizontally',
        );
      },
    );

    test(
      'buildPdfBytes compiles portrait page format and applies rotation when spooled format is flipped portrait',
      () async {
        const template = LabelTemplate(
          id: 'temp-landscape-flipped',
          name: 'Landscape Flipped Template',
          sheetConfig: SheetConfig(
            pageWidth: 208,
            pageHeight: 180,
            marginTop: 0,
            marginBottom: 0,
            marginLeft: 0,
            marginRight: 0,
            columns: 1,
            rows: 1,
            columnGap: 0,
            rowGap: 0,
          ),
          stickerConfig: StickerConfig(
            widthMm: 208,
            heightMm: 180,
            cornerRadiusMm: 0,
            printableArea: [],
          ),
          elements: [
            TextElementBlueprint(
              id: 'text-test',
              x: 10,
              y: 10,
              width: 100,
              height: 20,
              rotation: 0,
              content: 'Flipped Test',
              isDynamic: false,
              fontSize: 12,
              fontWeightValue: 400,
              textAlign: BlueprintTextAlign.left,
              colorHex: 0xFF000000,
            ),
          ],
        );

        // Physical spooled format is flipped portrait (180 x 208 mm)
        final pdfBytes = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: template,
          disabledSlots: {},
          physicalFormat: const PdfPageFormat(
            180 * PdfPageFormat.mm,
            208 * PdfPageFormat.mm,
          ),
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);

        // 1. MediaBox must match the Portrait format dimensions: 180 x 208 mm
        // 180mm = 510.236 pt
        // 208mm = 589.606 pt
        final mediaBoxRegex = RegExp(
          r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)\s*\]',
        );
        final match = mediaBoxRegex.firstMatch(pdfString);
        expect(match, isNotNull, reason: 'MediaBox must be defined in the PDF');
        final parsedWidth = double.parse(match!.group(1)!);
        final parsedHeight = double.parse(match.group(2)!);
        expect(parsedWidth, closeTo(510.236, 0.1));
        expect(parsedHeight, closeTo(589.606, 0.1));

        // 2. Verify rotation matrix exists in the generated PDF stream.
        // Rotation of -pi/2 maps [0, -1, 1, 0, tx, ty]
        final rotateMatrixRegex = RegExp(r'0\s+-1\s+1\s+0\s+-?([0-9.]+)\s+([0-9.]+)\s+cm');
        final matrixMatch = rotateMatrixRegex.firstMatch(pdfString);
        expect(matrixMatch, isNotNull, reason: 'PDF must contain a -90 degrees rotation matrix');
        final tx = double.parse(matrixMatch!.group(1)!);
        final ty = double.parse(matrixMatch.group(2)!);
        expect(tx, closeTo(79.370, 0.1));
        expect(ty, closeTo(589.606, 0.1));
        
        expect(pdfBytes.length, greaterThan(0));
      },
    );

    test(
      'buildPdfBytes applies scaling correctly around different anchor points',
      () async {
        const template = LabelTemplate(
          id: 'temp-anchor-scaling',
          name: 'Anchor Scaling Template',
          sheetConfig: SheetConfig(
            pageWidth: 100,
            pageHeight: 100,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 1,
            rows: 1,
            columnGap: 0,
            rowGap: 0,
          ),
          stickerConfig: StickerConfig(
            widthMm: 50,
            heightMm: 50,
            cornerRadiusMm: 0,
            printableArea: [],
          ),
          elements: [
            TextElementBlueprint(
              id: 'text-test',
              x: 0,
              y: 0,
              width: 10,
              height: 10,
              rotation: 0,
              content: 'Scaling Test',
              isDynamic: false,
              fontSize: 10,
              fontWeightValue: 400,
              textAlign: BlueprintTextAlign.left,
              colorHex: 0xFF000000,
            ),
          ],
        );

        // Helper to extract tx/ty translations of the positioned slot from PDF bytes
        Future<List<double>> getSlotTranslation(PrintCoordinateContext context) async {
          final pdfBytes = await engine.buildPdfBytes(
            items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
            template: template,
            disabledSlots: {},
            coordinateContext: context,
          );
          final pdfString = String.fromCharCodes(pdfBytes);
          final cmRegex = RegExp(r'1\s+0\s+0\s+1\s+([0-9.-]+)\s+([0-9.-]+)\s+cm');
          final matches = cmRegex.allMatches(pdfString).toList();
          expect(matches.length, greaterThan(1));
          final m = matches[1];
          final tx = double.parse(m.group(1)!);
          final ty = double.parse(m.group(2)!);
          return [tx, ty];
        }

        // Case A: Identity transform (or equivalent neutral scale transform with non-default anchors)
        final translationIdentity = await getSlotTranslation(
          const PrintCoordinateContext.identity(),
        );
        // expected tx = 10mm = 28.346 pt, ty = 100 - 10 - 50 = 40mm = 113.385 pt
        expect(translationIdentity[0], closeTo(28.346, 0.01));
        expect(translationIdentity[1], closeTo(113.385, 0.01));

        final translationNeutralCustomAnchor = await getSlotTranslation(
          const PrintCoordinateContext(
            globalTransform: PrintStickerTransform(
              anchorX: 0,
              anchorY: 1,
            ),
          ),
        );
        expect(translationNeutralCustomAnchor[0], closeTo(28.346, 0.01));
        expect(translationNeutralCustomAnchor[1], closeTo(113.385, 0.01));

        // Case B: Scaling around top-left anchor (0, 0) with scale 0.8
        // The Sized Box stays at original 50×50mm; scale is applied inside.
        // slotX = 10 + 0 = 10, slotY = 10 + 0 = 10
        // expected tx = 10mm = 28.346 pt, ty = 100 - 10 - 50 = 40mm = 113.385 pt
        final translationTopLeft = await getSlotTranslation(
          const PrintCoordinateContext(
            globalTransform: PrintStickerTransform(
              scaleX: 0.8,
              scaleY: 0.8,
              anchorX: 0,
              anchorY: 0,
            ),
          ),
        );
        expect(translationTopLeft[0], closeTo(28.346, 0.01));
        expect(translationTopLeft[1], closeTo(113.385, 0.01));

        // Case C: Scaling around center anchor (0.5, 0.5) with scale 0.8
        // Sized Box stays at original 50×50mm; scale applied inside.
        // slotX = 10 + 0.5 * 50 * 0.2 = 15
        // slotY = 10 + 0.5 * 50 * 0.2 = 15
        // expected tx = 15mm = 42.519 pt, ty = 100 - 15 - 50 = 35mm = 99.208 pt
        final translationCenter = await getSlotTranslation(
          const PrintCoordinateContext(
            globalTransform: PrintStickerTransform(
              scaleX: 0.8,
              scaleY: 0.8,
            ),
          ),
        );
        expect(translationCenter[0], closeTo(42.519, 0.01));
        expect(translationCenter[1], closeTo(99.208, 0.01));

        // Case D: Scaling around bottom-right anchor (1, 1) with scale 0.8
        // Sized Box stays at original 50×50mm; scale applied inside.
        // slotX = 10 + 1.0 * 50 * 0.2 = 20
        // slotY = 10 + 1.0 * 50 * 0.2 = 20
        // expected tx = 20mm = 56.692 pt, ty = 100 - 20 - 50 = 30mm = 85.039 pt
        final translationBottomRight = await getSlotTranslation(
          const PrintCoordinateContext(
            globalTransform: PrintStickerTransform(
              scaleX: 0.8,
              scaleY: 0.8,
              anchorX: 1,
              anchorY: 1,
            ),
          ),
        );
        expect(translationBottomRight[0], closeTo(56.692, 0.01));
        expect(translationBottomRight[1], closeTo(85.039, 0.01));
      },
    );
  });

  group('PrintStickerTransform Validation & Identity Tests', () {
    test('enforces anchorX bounds [0.0, 1.0] in constructor via assertions', () {
      // Valid cases
      expect(const PrintStickerTransform(anchorX: 0), isA<PrintStickerTransform>());
      expect(const PrintStickerTransform(anchorX: 1), isA<PrintStickerTransform>());

      // Invalid cases (assertion errors)
      expect(() => PrintStickerTransform(anchorX: -0.01), throwsA(isA<AssertionError>()));
      expect(() => PrintStickerTransform(anchorX: 1.01), throwsA(isA<AssertionError>()));
    });

    test('enforces anchorY bounds [0.0, 1.0] in constructor via assertions', () {
      // Valid cases
      expect(const PrintStickerTransform(anchorY: 0), isA<PrintStickerTransform>());
      expect(const PrintStickerTransform(anchorY: 1), isA<PrintStickerTransform>());

      // Invalid cases (assertion errors)
      expect(() => PrintStickerTransform(anchorY: -0.01), throwsA(isA<AssertionError>()));
      expect(() => PrintStickerTransform(anchorY: 1.01), throwsA(isA<AssertionError>()));
    });

    test('isIdentity is true when scale is neutral and offset is zero, regardless of anchors', () {
      expect(
        const PrintStickerTransform(
          anchorX: 0,
          anchorY: 0,
        ).isIdentity,
        isTrue,
      );

      expect(
        const PrintStickerTransform(
          anchorX: 1,
          anchorY: 1,
        ).isIdentity,
        isTrue,
      );

      expect(
        const PrintStickerTransform(
          offsetX: 0.001,
        ).isIdentity,
        isFalse,
      );

      expect(
        const PrintStickerTransform(
          scaleX: 0.999,
        ).isIdentity,
        isFalse,
      );
    });
  });

  group('Multi-Sheet Bulk Printing Calibration Tests', () {
    test(
      'applies sticker slot calibration transforms across all sheets in multi-sheet job (50 stickers across 3 sheets)',
      () async {
        const template = LabelTemplate(
          id: 'temp-multi-sheet',
          name: 'Multi Sheet Template',
          sheetConfig: SheetConfig(
            pageWidth: 200,
            pageHeight: 300,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 2,
            rows: 2, // 4 slots per sheet
            columnGap: 10,
            rowGap: 10,
          ),
          stickerConfig: StickerConfig(
            widthMm: 85,
            heightMm: 130,
            cornerRadiusMm: 0,
            printableArea: [],
          ),
          elements: [
            TextElementBlueprint(
              id: 'text-1',
              x: 0,
              y: 0,
              width: 50,
              height: 10,
              rotation: 0,
              content: 'Test Sticker',
              isDynamic: false,
              fontSize: 10,
              fontWeightValue: 400,
              textAlign: BlueprintTextAlign.left,
              colorHex: 0xFF000000,
            ),
          ],
        );

        // Calibration transform for slot 0 (r=0, c=0): shift X by +5mm (14.173 pt)
        const coordinateContext = PrintCoordinateContext(
          stickerTransforms: {
            0: PrintStickerTransform(offsetX: 5),
          },
        );

        // Quantity 10 stickers on 4 slots/sheet template -> 3 sheets (4 + 4 + 2 stickers)
        final pdfBytes = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 10)],
          template: template,
          disabledSlots: {1}, // Slot 1 on Sheet 0 is disabled (partially used sheet)
          coordinateContext: coordinateContext,
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);

        // Count total pages (should contain 3 pages /MediaBox)
        final mediaBoxMatches = RegExp('/MediaBox').allMatches(pdfString).length;
        expect(mediaBoxMatches, equals(3));

        // Slot 0 (r=0, c=0) on Sheet 0, Sheet 1, Sheet 2 should all have shifted X position:
        // Default slotX = 10mm = 28.346 pt. With +5mm offset = 15mm = 42.5196 pt.
        final cmRegex = RegExp(r'1\s+0\s+0\s+1\s+([0-9.-]+)\s+([0-9.-]+)\s+cm');
        final matches = cmRegex.allMatches(pdfString).where((m) {
          final tx = double.parse(m.group(1)!);
          return (tx - 42.5196).abs() < 0.1;
        }).toList();

        // Slot 0 appears on Sheet 0, Sheet 1, Sheet 2 -> 3 occurrences in total PDF stream
        expect(matches.length, equals(3), reason: 'Calibrated slot 0 offset (+5mm -> 42.52pt) must be applied across all 3 sheets');
      },
    );

    test(
      'supports multiple partially used sheets with disabled slots across Sheet 1 and Sheet 2',
      () async {
        const template = LabelTemplate(
          id: 'temp-multi-partial',
          name: 'Multi Partial Template',
          sheetConfig: SheetConfig(
            pageWidth: 200,
            pageHeight: 300,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 2,
            rows: 2, // 4 slots per sheet
            columnGap: 10,
            rowGap: 10,
          ),
          stickerConfig: StickerConfig(
            widthMm: 85,
            heightMm: 130,
            cornerRadiusMm: 0,
            printableArea: [],
          ),
          elements: [
            TextElementBlueprint(
              id: 'text-1',
              x: 0,
              y: 0,
              width: 50,
              height: 10,
              rotation: 0,
              content: 'Test Sticker',
              isDynamic: false,
              fontSize: 10,
              fontWeightValue: 400,
              textAlign: BlueprintTextAlign.left,
              colorHex: 0xFF000000,
            ),
          ],
        );

        // Sheet 0 has slots 2,3 disabled (2 available). Sheet 1 has slot 4 disabled (3 available).
        // Quantity 5 stickers -> Sheet 0 (2 stickers), Sheet 1 (3 stickers) -> total 2 sheets.
        final pdfBytes = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 5)],
          template: template,
          disabledSlots: {2, 3, 4},
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);
        final mediaBoxMatches = RegExp('/MediaBox').allMatches(pdfString).length;
        expect(mediaBoxMatches, equals(2));
      },
    );

    test(
      'reverses PDF page sequence when reverseSheetOrder is true',
      () async {
        const template = LabelTemplate(
          id: 'temp-reverse-order',
          name: 'Reverse Order Template',
          sheetConfig: SheetConfig(
            pageWidth: 200,
            pageHeight: 300,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 1,
            rows: 2, // 2 slots per sheet
            columnGap: 0,
            rowGap: 10,
          ),
          stickerConfig: StickerConfig(
            widthMm: 180,
            heightMm: 130,
            cornerRadiusMm: 0,
            printableArea: [],
          ),
        );

        final pdfBytesNormal = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 3)],
          template: template,
          disabledSlots: const {},
        );

        final pdfBytesReversed = await engine.buildPdfBytes(
          items: [const PrintableItem(product: testProduct, variant: testVariant, quantity: 3)],
          template: template,
          disabledSlots: {},
          reverseSheetOrder: true,
        );

        expect(pdfBytesNormal, isNotNull);
        expect(pdfBytesReversed, isNotNull);
        expect(pdfBytesReversed, isNot(equals(pdfBytesNormal)));
      },
    );
  });
}
