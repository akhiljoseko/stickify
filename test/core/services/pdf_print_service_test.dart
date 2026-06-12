import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/pdf_print_service.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfPrintService service;
  
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
    quantity: 1.0,
    unit: 'bottle',
    wholesale: 2.5,
    mrp: 3.5,
    sku: 'CB-100-BTL',
  );

  setUp(() {
    service = const PdfPrintService();

    const channel = MethodChannel('net.nfet.printing');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (message) async {
      if (message.method == 'printPdf') {
        final Map<dynamic, dynamic> args = message.arguments as Map<dynamic, dynamic>;
        final int jobId = args['job'] as int;
        
        const codec = StandardMethodCodec();
        final layoutBytes = codec.encodeMethodCall(
          MethodCall('onLayout', {
            'job': jobId,
            'width': args['width'] ?? 210.0,
            'height': args['height'] ?? 297.0,
            'marginLeft': args['marginLeft'] ?? 0.0,
            'marginTop': args['marginTop'] ?? 0.0,
            'marginRight': args['marginRight'] ?? 0.0,
            'marginBottom': args['marginBottom'] ?? 0.0,
          }),
        );
        
        Future.microtask(() async {
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
            'net.nfet.printing',
            layoutBytes,
            (ByteData? data) {},
          );

          final completedBytes = codec.encodeMethodCall(
            MethodCall('onCompleted', {
              'job': jobId,
              'completed': true,
            }),
          );
          await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.handlePlatformMessage(
            'net.nfet.printing',
            completedBytes,
            (ByteData? data) {},
          );
        });
      }
      return 1; // Success code
    });
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
}
