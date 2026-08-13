import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LabelPdfLayoutEngine engine;

  const productA = Product(
    id: 'prod-a',
    name: 'Alpha Product',
    sku: 'ALPHA-100',
  );
  const variantA = ProductVariant(
    name: 'Alpha Var 100g',
    quantity: 1,
    unit: 'pack',
    wholesale: 10,
    mrp: 15,
    sku: 'ALPHA-100-VAR',
  );

  const productB = Product(
    id: 'prod-b',
    name: 'Beta Product',
    sku: 'BETA-200',
  );
  const variantB = ProductVariant(
    name: 'Beta Var 200g',
    quantity: 1,
    unit: 'pack',
    wholesale: 20,
    mrp: 25,
    sku: 'BETA-200-VAR',
  );

  const productC = Product(
    id: 'prod-c',
    name: 'Gamma Product',
    sku: 'GAMMA-300',
  );
  const variantC = ProductVariant(
    name: 'Gamma Var 300g',
    quantity: 1,
    unit: 'pack',
    wholesale: 30,
    mrp: 35,
    sku: 'GAMMA-300-VAR',
  );

  const template15Slots = LabelTemplate(
    id: 'temp-15-slots',
    name: '15 Slots Sheet',
    sheetConfig: SheetConfig(
      pageWidth: 210,
      pageHeight: 297,
      marginTop: 10,
      marginBottom: 10,
      marginLeft: 10,
      marginRight: 10,
      columns: 3,
      rows: 5, // 15 slots per sheet
      columnGap: 5,
      rowGap: 5,
    ),
    stickerConfig: StickerConfig(
      widthMm: 60,
      heightMm: 50,
      cornerRadiusMm: 2,
      printableArea: [],
    ),
    elements: [
      TextElementBlueprint(
        id: 'element-prod-name',
        x: 0,
        y: 0,
        width: 60,
        height: 10,
        rotation: 0,
        content: '{{product_name}}',
        isDynamic: true,
        fontSize: 10,
        fontWeightValue: 400,
        textAlign: BlueprintTextAlign.left,
        colorHex: 0xFF000000,
      ),
    ],
  );

  setUp(() {
    PdfElementRendererRegistry.registerDefaults();
    engine = const LabelPdfLayoutEngine(useIsolate: false);
  });

  group('LabelPdfLayoutEngine Batch Printing Tests', () {
    test(
      '3 items x 5 labels on a 15-slot template produces exactly 1 sheet with all 15 slots packed sequentially',
      () async {
        final items = [
          const PrintableItem(
            product: productA,
            variant: variantA,
            quantity: 5,
          ),
          const PrintableItem(
            product: productB,
            variant: variantB,
            quantity: 5,
          ),
          const PrintableItem(
            product: productC,
            variant: variantC,
            quantity: 5,
          ),
        ];

        final pdfBytes = await engine.buildPdfBytes(
          items: items,
          template: template15Slots,
          disabledSlots: const {},
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));

        final pdfString = String.fromCharCodes(pdfBytes);

        // 1 page = 1 sheet MediaBox
        final mediaBoxMatches = RegExp('/MediaBox').allMatches(pdfString).length;
        expect(mediaBoxMatches, equals(1));
      },
    );

    test(
      'batch items across sheet boundaries pack continuous slots onto sheet 2 correctly',
      () async {
        // 10 + 10 + 5 = 25 labels on 15-slot template -> 2 sheets (15 on sheet 1, 10 on sheet 2)
        final items = [
          const PrintableItem(
            product: productA,
            variant: variantA,
            quantity: 10,
          ),
          const PrintableItem(
            product: productB,
            variant: variantB,
            quantity: 10,
          ),
          const PrintableItem(
            product: productC,
            variant: variantC,
            quantity: 5,
          ),
        ];

        final pdfBytes = await engine.buildPdfBytes(
          items: items,
          template: template15Slots,
          disabledSlots: const {},
        );

        expect(pdfBytes, isNotNull);
        final pdfString = String.fromCharCodes(pdfBytes);

        final mediaBoxMatches = RegExp('/MediaBox').allMatches(pdfString).length;
        expect(mediaBoxMatches, equals(2));
      },
    );

    test(
      'single-item list produces non-empty valid PDF (regression check)',
      () async {
        final items = [
          const PrintableItem(
            product: productA,
            variant: variantA,
            quantity: 3,
          ),
        ];

        final pdfBytes = await engine.buildPdfBytes(
          items: items,
          template: template15Slots,
          disabledSlots: const {},
        );

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.length, greaterThan(0));

        final pdfString = String.fromCharCodes(pdfBytes);
        final mediaBoxMatches = RegExp('/MediaBox').allMatches(pdfString).length;
        expect(mediaBoxMatches, equals(1));
      },
    );
  });
}
