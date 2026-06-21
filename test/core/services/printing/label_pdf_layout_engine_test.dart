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
          product: testProduct,
          variant: testVariant,
          template: template,
          quantity: 1,
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
          product: testProduct,
          variant: testVariant,
          template: template,
          quantity: 1,
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
          product: testProduct,
          variant: testVariant,
          template: template,
          quantity: 1,
          disabledSlots: {},
        );

        // 2. With physical format margins (shift should be applied)
        final pdfBytesWithShift = await engine.buildPdfBytes(
          product: testProduct,
          variant: testVariant,
          template: template,
          quantity: 1,
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
      'buildPdfBytes compiles portrait page format and PageOrientation.landscape when spooled format is flipped portrait',
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
          product: testProduct,
          variant: testVariant,
          template: template,
          quantity: 1,
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
        // 2. The PDF compiles successfully and has bytes
        expect(pdfBytes.length, greaterThan(0));
      },
    );

    test(
      'buildPdfBytes applies printer margins shift horizontally and vertically',
      () async {
        const template = LabelTemplate(
          id: 'temp-margins-shift',
          name: 'Margins Shift Template',
          sheetConfig: SheetConfig(
            pageWidth: 200,
            pageHeight: 200,
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
            widthMm: 200,
            heightMm: 200,
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

        // 1. With margins: Left = 5mm, Top = 10mm
        final pdfBytes = await engine.buildPdfBytes(
          product: testProduct,
          variant: testVariant,
          template: template,
          quantity: 1,
          disabledSlots: {},
          margins: const PrinterMargins(
            left: 5,
            top: 10,
            right: 5,
            bottom: 5,
          ),
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);

        // Extract translation matrices from the generated shifted PDF stream.
        final cmRegex = RegExp(r'1\s+0\s+0\s+1\s+([0-9.-]+)\s+([0-9.-]+)\s+cm');
        final matches = cmRegex.allMatches(pdfString).toList();

        // Verify that the sticker slot translation (which corresponds to slot position on the sheet)
        // was shifted horizontally by +5mm (14.173 pt) and vertically by +10mm (which corresponds to -28.346 pt translation shift).
        final hasCorrectShifts = matches.any((m) {
          final tx = double.parse(m.group(1)!);
          final ty = double.parse(m.group(2)!);
          return (tx - 14.1732).abs() < 0.1 && (ty - -28.3464).abs() < 0.1;
        });

        expect(
          hasCorrectShifts,
          isTrue,
          reason: 'Sticker slot must be shifted by +5mm horizontally and +10mm vertically',
        );
      },
    );
  });
}
