import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/pdf_print_service.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfPrintService service;
  late FakePrintingPlatform mockPrintingPlatform;
  final testProduct = Product(
    id: 'prod-1',
    name: 'Cold Brew Coffee',
    sku: 'CB-100',
    totalPrints: 5,
    lastPrintedAt: DateTime(2026),
    assignedStation: 'Station 1',
    stationStatus: StationStatus.online,
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
    service = const PdfPrintService();
    mockPrintingPlatform = FakePrintingPlatform();
    PrintingPlatform.instance = mockPrintingPlatform;
  });

  group('PdfPrintService Validation Tests', () {
    test('Fails when sheetConfig is missing', () async {
      const template = LabelTemplate(
        id: 'temp-1',
        name: 'Test Template',
        stickerConfig: StickerConfig(
          widthMm: 50,
          heightMm: 30,
          cornerRadiusMm: 2,
          printableArea: [],
        ),
      );

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Failure<void, AppError>>());
      expect((result as Failure).error.message, contains('Sheet configuration is required'));
    });

    test('Fails when stickerConfig is missing', () async {
      const template = LabelTemplate(
        id: 'temp-1',
        name: 'Test Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 2,
          rows: 5,
          columnGap: 5,
          rowGap: 5,
        ),
      );

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Failure<void, AppError>>());
      expect((result as Failure).error.message, contains('Sticker configuration is required'));
    });

    test('Fails when grid layout size exceeds the sheet boundaries', () async {
      // Columns: 3, Width: 80mm each, margins: 10mm each, gap: 5mm.
      // Required width = 10 + (3 * 80) + (2 * 5) + 10 = 270mm.
      // Page width = 210mm. Exceeds!
      const template = LabelTemplate(
        id: 'temp-1',
        name: 'Test Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 3,
          rows: 5,
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

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Failure<void, AppError>>());
      expect((result as Failure).error.message, contains('exceeds the physical sheet bounds'));
    });

    test('Fails when barcode is outside the printable area polygon', () async {
      // Polygon: triangle (0,0), (50,0), (25, 10).
      // Barcode element: x:10, y:20, w:30, h:10 (goes up to y:30, which is outside y:10 limit of polygon).
      const template = LabelTemplate(
        id: 'temp-1',
        name: 'Test Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 2,
          rows: 5,
          columnGap: 5,
          rowGap: 5,
        ),
        stickerConfig: StickerConfig(
          widthMm: 50,
          heightMm: 50,
          cornerRadiusMm: 2,
          printableArea: [
            StickerPoint(0, 0),
            StickerPoint(50, 0),
            StickerPoint(25, 10),
          ],
        ),
        elements: [
          BarcodeElementBlueprint(
            id: 'barcode-1',
            x: 10,
            y: 20,
            width: 30,
            height: 10,
            rotation: 0,
            data: '1234',
            isDynamic: false,
            barcodeType: BlueprintBarcodeType.code128,
            showLabel: true,
          ),
        ],
      );

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Failure<void, AppError>>());
      expect((result as Failure).error.message, contains('falls outside the printable area polygon'));
    });

    test('Passes validation when barcode is fully inside the printable area polygon', () async {
      const template = LabelTemplate(
        id: 'temp-1',
        name: 'Test Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 2,
          rows: 5,
          columnGap: 5,
          rowGap: 5,
        ),
        stickerConfig: StickerConfig(
          widthMm: 50,
          heightMm: 50,
          cornerRadiusMm: 2,
          printableArea: [
            StickerPoint(0, 0),
            StickerPoint(50, 0),
            StickerPoint(50, 50),
            StickerPoint(0, 50),
          ],
        ),
        elements: [
          BarcodeElementBlueprint(
            id: 'barcode-1',
            x: 5,
            y: 5,
            width: 40,
            height: 10,
            rotation: 0,
            data: '1234',
            isDynamic: false,
            barcodeType: BlueprintBarcodeType.code128,
            showLabel: true,
          ),
        ],
      );

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Success<void, AppError>>());
    });
  });

  group('PdfPrintService Output Inspection Tests', () {
    test('Generates PDF with exact custom sheet dimensions in MediaBox', () async {
      const template = LabelTemplate(
        id: 'temp-custom-size',
        name: 'Custom Size Template',
        sheetConfig: SheetConfig(
          pageWidth: 180,
          pageHeight: 120,
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

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Success<void, AppError>>());
      expect(mockPrintingPlatform.capturedPdfBytes, isNotNull);

      // Inspect uncompressed raw PDF string for MediaBox dimensions
      final pdfString = String.fromCharCodes(mockPrintingPlatform.capturedPdfBytes!);
      
      // Expected width in points = 180mm * 2.834645669291339 = 510.236 points
      // Expected height in points = 120mm * 2.834645669291339 = 340.157 points
      final mediaBoxRegex = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([0-9.]+)\s+([0-9.]+)\s*\]');
      final match = mediaBoxRegex.firstMatch(pdfString);
      expect(match, isNotNull, reason: 'MediaBox must be defined in the PDF');
      
      final parsedWidth = double.parse(match!.group(1)!);
      final parsedHeight = double.parse(match.group(2)!);
      expect(parsedWidth, closeTo(510.236, 0.1));
      expect(parsedHeight, closeTo(340.157, 0.1));
    });

    test('Clips sticker layout using custom printable polygon path', () async {
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

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: template,
        quantity: 1,
        disabledSlots: {},
        printerName: 'Zebra',
      );

      expect(result, isA<Success<void, AppError>>());
      expect(mockPrintingPlatform.capturedPdfBytes, isNotNull);

      final pdfString = String.fromCharCodes(mockPrintingPlatform.capturedPdfBytes!);
      
      // Verify that the path operators for clipping are compiled into the PDF
      // Triangle vertices in PDF:
      // Point 1: 0, 50 -> Y = (50 - 0) * 2.8346 = 141.73
      // Point 2: 80, 50 -> Y = (50 - 0) * 2.8346 = 141.73
      // Point 3: 40, 0 -> Y = (50 - 50) * 2.8346 = 0
      // We expect the path to be closed and clipped: e.g. contains ' W ' (Clip path operator)
      expect(pdfString, contains(' W'), reason: 'PDF must contain a clipping operator (W)');
      expect(pdfString, contains(' h'), reason: 'PDF must contain a path close operator (h)');
    });
  });
}

class FakePrintingPlatform extends PrintingPlatform {
  FakePrintingPlatform();

  Uint8List? capturedPdfBytes;

  @override
  Future<PrintingInfo> info() async {
    return const PrintingInfo(canPrint: true, canShare: true, canRaster: true);
  }

  @override
  Future<bool> layoutPdf(
    Printer? printer,
    LayoutCallback onLayout,
    String name,
    PdfPageFormat format,
    bool dynamicLayout,
    bool usePrinterSettings,
    OutputType outputType,
    bool forceCustomPrintPaper,
  ) async {
    capturedPdfBytes = await onLayout(format);
    return true;
  }

  @override
  Future<List<Printer>> listPrinters() async => [];

  @override
  Future<Printer?> pickPrinter(Rect bounds) async => null;

  @override
  Future<bool> sharePdf(
    Uint8List bytes,
    String filename,
    Rect bounds,
    String? subject,
    String? body,
    List<String>? emails,
  ) async => true;

  @override
  Future<Uint8List> convertHtml(
    String html,
    String? baseUrl,
    PdfPageFormat format,
  ) async => Uint8List(0);

  @override
  Stream<PdfRaster> raster(Uint8List document, List<int>? pages, double dpi) async* {}
}
