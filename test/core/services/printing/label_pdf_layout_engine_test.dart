import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LabelPdfLayoutEngine engine;

  final testProduct = Product(
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
  });
}
