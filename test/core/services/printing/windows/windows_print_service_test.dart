import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/windows/windows_devmode_manager.dart';
import 'package:stickify/core/services/printing/windows/windows_print_service.dart';
import 'package:stickify/domain/domain.dart';

class MockLabelLayoutEngine extends Mock implements LabelLayoutEngine {}

class MockPaperValidationEngine extends Mock implements PaperValidationEngine {}

class MockWindowsDevModeManager extends Mock implements WindowsDevModeManager {}

class FakePrintingPlatform extends PrintingPlatform {
  FakePrintingPlatform();

  Uint8List? capturedPdfBytes;
  List<Printer> printersList = [];
  bool directPrintSuccess = true;

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
    return directPrintSuccess;
  }

  @override
  Future<List<Printer>> listPrinters() async => printersList;

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLabelLayoutEngine mockLayoutEngine;
  late MockPaperValidationEngine mockPaperValidator;
  late MockWindowsDevModeManager mockDevModeManager;
  late FakePrintingPlatform fakePrintingPlatform;
  late WindowsPrintService service;

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

  const testSheet = SheetConfig(
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
  );

  const testSticker = StickerConfig(
    widthMm: 50,
    heightMm: 50,
    cornerRadiusMm: 2,
    printableArea: [],
  );

  const testTemplate = LabelTemplate(
    id: 'temp-1',
    name: 'Test Template',
    sheetConfig: testSheet,
    stickerConfig: testSticker,
  );

  setUpAll(() {
    registerFallbackValue(const PrinterDevice(name: '', url: ''));
    registerFallbackValue(const SheetConfig(
      pageWidth: 0,
      pageHeight: 0,
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
      columns: 0,
      rows: 0,
      columnGap: 0,
      rowGap: 0,
    ));
    registerFallbackValue(const Product(
      id: '',
      name: '',
      sku: '',
    ));
    registerFallbackValue(const ProductVariant(
      name: '',
      quantity: 0,
      unit: '',
      wholesale: 0,
      mrp: 0,
      sku: '',
    ));
    registerFallbackValue(const LabelTemplate(
      id: '',
      name: '',
    ));
    registerFallbackValue(PdfPageFormat.standard);
    registerFallbackValue(const PrintCoordinateContext.identity());
  });

  setUp(() {
    mockLayoutEngine = MockLabelLayoutEngine();
    mockPaperValidator = MockPaperValidationEngine();
    mockDevModeManager = MockWindowsDevModeManager();
    fakePrintingPlatform = FakePrintingPlatform();

    PrintingPlatform.instance = fakePrintingPlatform;

    when(() => mockDevModeManager.healOnStartup()).thenAnswer((_) async {});
    when(() => mockDevModeManager.applySettings(any(), any()))
        .thenAnswer((_) async => 'backup-token-xyz');
    when(() => mockDevModeManager.restoreSettings(any(), any()))
        .thenAnswer((_) async {});

    service = WindowsPrintService(
      layoutEngine: mockLayoutEngine,
      paperValidator: mockPaperValidator,
      devModeManager: mockDevModeManager,
    );
  });

  group('WindowsPrintService Tests', () {
    test('Constructor triggers healOnStartup', () {
      verify(() => mockDevModeManager.healOnStartup()).called(1);
    });

    test('getAvailablePrinters retrieves list of printers', () async {
      fakePrintingPlatform.printersList = [
        const Printer(name: 'Zebra ZT411-A', url: 'zebra-url', isDefault: true),
      ];

      final printers = await service.getAvailablePrinters();
      expect(printers.length, 1);
      expect(printers.first.name, 'Zebra ZT411-A');
      expect(printers.first.url, 'zebra-url');
      expect(printers.first.isDefault, isTrue);
    });

    test('Fails validation if paper size is not supported', () async {
      when(() => mockPaperValidator.isPaperSizeSupported(any(), any()))
          .thenAnswer((_) async => false);

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: testTemplate,
        quantity: 1,
        disabledSlots: {},
        printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'url'),
      );

      expect(result, isA<Failure<void, AppError>>());
      expect(
        (result as Failure).error.message,
        contains('does not support the required paper form size'),
      );
    });

    test('Fails if printer is not found in Printing list', () async {
      when(() => mockPaperValidator.isPaperSizeSupported(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockLayoutEngine.buildPdfBytes(
            product: any(named: 'product'),
            variant: any(named: 'variant'),
            template: any(named: 'template'),
            quantity: any(named: 'quantity'),
            disabledSlots: any(named: 'disabledSlots'),
            physicalFormat: any(named: 'physicalFormat'),
          )).thenAnswer((_) async => Uint8List(0));
      fakePrintingPlatform.printersList = [];

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: testTemplate,
        quantity: 1,
        disabledSlots: {},
        printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'url'),
      );

      expect(result, isA<Failure<void, AppError>>());
      expect(
        (result as Failure).error.message,
        contains('was not found in available system printers'),
      );
      verify(() => mockDevModeManager.restoreSettings(any(), any())).called(1);
    });

    test('Prints successfully when validation passes and printer exists', () async {
      when(() => mockPaperValidator.isPaperSizeSupported(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockLayoutEngine.buildPdfBytes(
            product: any(named: 'product'),
            variant: any(named: 'variant'),
            template: any(named: 'template'),
            quantity: any(named: 'quantity'),
            disabledSlots: any(named: 'disabledSlots'),
            physicalFormat: any(named: 'physicalFormat'),
            coordinateContext: any(named: 'coordinateContext'),
          )).thenAnswer((_) async => Uint8List(0));
      fakePrintingPlatform.printersList = [
        const Printer(name: 'Zebra ZT411-A', url: 'zebra-url', isDefault: true),
      ];

      final result = await service.printLabels(
        product: testProduct,
        variant: testVariant,
        template: testTemplate,
        quantity: 1,
        disabledSlots: {},
        printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
      );

      expect(result, isA<Success<void, AppError>>());

      verify(() => mockLayoutEngine.buildPdfBytes(
            product: any(named: 'product'),
            variant: any(named: 'variant'),
            template: any(named: 'template'),
            quantity: any(named: 'quantity'),
            disabledSlots: any(named: 'disabledSlots'),
            physicalFormat: any(named: 'physicalFormat'),
            coordinateContext: any(named: 'coordinateContext'),
          )).called(1);
      verify(() => mockDevModeManager.applySettings(any(), any())).called(1);
      verify(() => mockDevModeManager.restoreSettings(any(), 'backup-token-xyz')).called(1);
    });
  });
}
