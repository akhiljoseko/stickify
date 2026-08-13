// Testing redundant arguments is necessary to verify default parameters and fallback behaviors.
// ignore_for_file: avoid_redundant_argument_values
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:printing/src/interface.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/print_calibration_context_resolver.dart';
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
    bool windowsModernDialog,
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
  Stream<PdfRaster> raster(
    Uint8List document,
    List<int>? pages,
    double dpi,
  ) async* {}
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
    registerFallbackValue(
      const SheetConfig(
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
      ),
    );
    registerFallbackValue(testProduct);
    registerFallbackValue(testVariant);
    registerFallbackValue(testTemplate);
    registerFallbackValue(const PrintableItem(product: testProduct, variant: testVariant, quantity: 1));
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
    when(
      () => mockDevModeManager.applySettings(any(), any()),
    ).thenAnswer((_) async => 'backup-token-xyz');
    when(
      () => mockDevModeManager.restoreSettings(any(), any()),
    ).thenAnswer((_) async {});

    const resolver = PrinterCalibrationCoordinateResolver(
      ruleMatcher: CalibrationRuleMatcher(),
      transformComposer: CalibrationTransformComposer(),
    );
    const calibrationResolver = PrintCalibrationContextResolver(resolver);

    service = WindowsPrintService(
      layoutEngine: mockLayoutEngine,
      paperValidator: mockPaperValidator,
      devModeManager: mockDevModeManager,
      calibrationResolver: calibrationResolver,
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

    test(
      'getDiscoveredPrinters falls back to printing package when PowerShell fails',
      () async {
        fakePrintingPlatform.printersList = [
          const Printer(
            name: 'Zebra ZT411-A',
            url: 'zebra-url',
            isDefault: true,
            isAvailable: true,
          ),
        ];

        final failingService = WindowsPrintService(
          layoutEngine: mockLayoutEngine,
          paperValidator: mockPaperValidator,
          devModeManager: mockDevModeManager,
          calibrationResolver: const PrintCalibrationContextResolver(
            PrinterCalibrationCoordinateResolver(
              ruleMatcher: CalibrationRuleMatcher(),
              transformComposer: CalibrationTransformComposer(),
            ),
          ),
          processRunner: (executable, arguments) async {
            return ProcessResult(0, 1, '', 'PowerShell simulation error');
          },
        );

        final printers = await failingService.getDiscoveredPrinters();
        expect(printers.length, 1);
        expect(printers.first.systemPrinterName, 'Zebra ZT411-A');
        expect(printers.first.status, DiscoveredPrinterStatus.online);
      },
    );

    test(
      'getDiscoveredPrinters on Windows executes PowerShell script and returns printers',
      () async {
        final printers = await service.getDiscoveredPrinters();
        expect(printers, isNotNull);
        // If running on Windows, we should have retrieved at least one printer.
        // If not on Windows, the fallback will still retrieve the mocked printers.
        expect(printers, isNotEmpty);
        for (final p in printers) {
          expect(p.systemPrinterName, isNotEmpty);
          expect(p.status, isA<DiscoveredPrinterStatus>());
        }
      },
    );

    test('Fails validation if paper size is not supported', () async {
      when(
        () => mockPaperValidator.isPaperSizeSupported(any(), any()),
      ).thenAnswer((_) async => false);

      final result = await service.printLabels(
        items: [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
        template: testTemplate,
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
      when(
        () => mockPaperValidator.isPaperSizeSupported(any(), any()),
      ).thenAnswer((_) async => true);
      when(
        () => mockLayoutEngine.buildPdfBytes(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          physicalFormat: any(named: 'physicalFormat'),
        ),
      ).thenAnswer((_) async => Uint8List(0));
      fakePrintingPlatform.printersList = [];

      final result = await service.printLabels(
        items: [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
        template: testTemplate,
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

    test(
      'Prints successfully when validation passes and printer exists',
      () async {
        when(
          () => mockPaperValidator.isPaperSizeSupported(any(), any()),
        ).thenAnswer((_) async => true);
        when(
          () => mockLayoutEngine.buildPdfBytes(
            items: any(named: 'items'),
            template: any(named: 'template'),
            disabledSlots: any(named: 'disabledSlots'),
            physicalFormat: any(named: 'physicalFormat'),
            coordinateContext: any(named: 'coordinateContext'),
          ),
        ).thenAnswer((_) async => Uint8List(0));
        fakePrintingPlatform.printersList = [
          const Printer(
            name: 'Zebra ZT411-A',
            url: 'zebra-url',
            isDefault: true,
          ),
        ];

        final result = await service.printLabels(
          items: [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: testTemplate,
          disabledSlots: {},
          printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
        );

        expect(result, isA<Success<void, AppError>>());

        verify(
          () => mockLayoutEngine.buildPdfBytes(
            items: any(named: 'items'),
            template: any(named: 'template'),
            disabledSlots: any(named: 'disabledSlots'),
            physicalFormat: any(named: 'physicalFormat'),
            coordinateContext: any(named: 'coordinateContext'),
          ),
        ).called(1);
        verify(() => mockDevModeManager.applySettings(any(), any())).called(1);
        verify(
          () => mockDevModeManager.restoreSettings(any(), 'backup-token-xyz'),
        ).called(1);
      },
    );
  });

  group('WindowsPrintService Calibration Integration Tests', () {
    late WindowsPrintService calibrationService;
    late MockLabelLayoutEngine mockLayout;
    late MockPaperValidationEngine mockValidator;
    late MockWindowsDevModeManager mockDevMode;
    late PrinterCalibrationCoordinateResolver realResolver;
    late PrintCalibrationContextResolver realCalibrationResolver;

    final testTray = PrinterTrayProfile(
      trayIdentifier: 'tray_1',
      displayName: 'Tray 1',
      supportedPaperConfigurations: const [
        PaperConfigurationReference(id: 'temp-1', displayName: 'Template 1'),
      ],
      calibration: PrinterCalibration(
        enabled: true,
        calibrationRules: const [
          CalibrationRule(
            target: CalibrationTarget.edge(EdgeGroup.left),
            transformation: PrintStickerTransform(scaleX: 0.95, anchorX: 0),
          ),
        ],
      ),
    );

    final disabledTray = PrinterTrayProfile(
      trayIdentifier: 'tray_1',
      displayName: 'Tray 1',
      supportedPaperConfigurations: const [
        PaperConfigurationReference(id: 'temp-1', displayName: 'Template 1'),
      ],
      calibration: PrinterCalibration(
        enabled: false,
        calibrationRules: const [
          CalibrationRule(
            target: CalibrationTarget.edge(EdgeGroup.left),
            transformation: PrintStickerTransform(scaleX: 0.95, anchorX: 0),
          ),
        ],
      ),
    );

    setUp(() {
      mockLayout = MockLabelLayoutEngine();
      mockValidator = MockPaperValidationEngine();
      mockDevMode = MockWindowsDevModeManager();
      realResolver = const PrinterCalibrationCoordinateResolver(
        ruleMatcher: CalibrationRuleMatcher(),
        transformComposer: CalibrationTransformComposer(),
      );
      realCalibrationResolver = PrintCalibrationContextResolver(realResolver);

      when(() => mockDevMode.healOnStartup()).thenAnswer((_) async {});
      when(
        () => mockDevMode.applySettings(any(), any()),
      ).thenAnswer((_) async => 'backup-token-xyz');
      when(
        () => mockDevMode.restoreSettings(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockValidator.isPaperSizeSupported(any(), any()),
      ).thenAnswer((_) async => true);

      calibrationService = WindowsPrintService(
        layoutEngine: mockLayout,
        paperValidator: mockValidator,
        devModeManager: mockDevMode,
        calibrationResolver: realCalibrationResolver,
      );
    });

    test(
      'No printer configuration (null configuration) -> identity context',
      () async {
        fakePrintingPlatform.printersList = [
          const Printer(name: 'Zebra ZT411-A', url: 'zebra-url'),
        ];

        when(
          () => mockLayout.buildPdfBytes(
            items: any(named: 'items'),
            template: any(named: 'template'),
            disabledSlots: any(named: 'disabledSlots'),
            printFromBottom: any(named: 'printFromBottom'),
            physicalFormat: any(named: 'physicalFormat'),
            coordinateContext: any(named: 'coordinateContext'),
          ),
        ).thenAnswer((_) async => Uint8List(0));

        final result = await calibrationService.printLabels(
          items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: testTemplate,
          disabledSlots: {},
          printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
          executionConfiguration: null,
        );

        expect(result, isA<Success<void, AppError>>());
        final capturedContext =
            verify(
                  () => mockLayout.buildPdfBytes(
                    items: any(named: 'items'),
                    template: any(named: 'template'),
                    disabledSlots: any(named: 'disabledSlots'),
                    printFromBottom: any(named: 'printFromBottom'),
                    physicalFormat: any(named: 'physicalFormat'),
                    coordinateContext: captureAny(named: 'coordinateContext'),
                  ),
                ).captured.first
                as PrintCoordinateContext;

        expect(capturedContext.isIdentity, isTrue);
      },
    );

    test(
      'No selected tray (PrintExecutionConfiguration with null selectedTray) -> identity context',
      () async {
        fakePrintingPlatform.printersList = [
          const Printer(name: 'Zebra ZT411-A', url: 'zebra-url'),
        ];

        when(
          () => mockLayout.buildPdfBytes(
            items: any(named: 'items'),
            template: any(named: 'template'),
            disabledSlots: any(named: 'disabledSlots'),
            printFromBottom: any(named: 'printFromBottom'),
            physicalFormat: any(named: 'physicalFormat'),
            coordinateContext: any(named: 'coordinateContext'),
          ),
        ).thenAnswer((_) async => Uint8List(0));

        final result = await calibrationService.printLabels(
          items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
          template: testTemplate,
          disabledSlots: {},
          printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
          executionConfiguration: const PrintExecutionConfiguration(
            selectedTray: null,
          ),
        );

        expect(result, isA<Success<void, AppError>>());
        final capturedContext =
            verify(
                  () => mockLayout.buildPdfBytes(
                    items: any(named: 'items'),
                    template: any(named: 'template'),
                    disabledSlots: any(named: 'disabledSlots'),
                    printFromBottom: any(named: 'printFromBottom'),
                    physicalFormat: any(named: 'physicalFormat'),
                    coordinateContext: captureAny(named: 'coordinateContext'),
                  ),
                ).captured.first
                as PrintCoordinateContext;

        expect(capturedContext.isIdentity, isTrue);
      },
    );

    test('Calibration disabled -> identity context', () async {
      fakePrintingPlatform.printersList = [
        const Printer(name: 'Zebra ZT411-A', url: 'zebra-url'),
      ];

      when(
        () => mockLayout.buildPdfBytes(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          printFromBottom: any(named: 'printFromBottom'),
          physicalFormat: any(named: 'physicalFormat'),
          coordinateContext: any(named: 'coordinateContext'),
        ),
      ).thenAnswer((_) async => Uint8List(0));

      final result = await calibrationService.printLabels(
        items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
        template: testTemplate,
        disabledSlots: {},
        printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
        executionConfiguration: PrintExecutionConfiguration(
          selectedTray: disabledTray,
          paperConfigurationId: 'temp-1',
        ),
      );

      expect(result, isA<Success<void, AppError>>());
      final capturedContext =
          verify(
                () => mockLayout.buildPdfBytes(
                  items: any(named: 'items'),
                  template: any(named: 'template'),
                  disabledSlots: any(named: 'disabledSlots'),
                  printFromBottom: any(named: 'printFromBottom'),
                  physicalFormat: any(named: 'physicalFormat'),
                  coordinateContext: captureAny(named: 'coordinateContext'),
                ),
              ).captured.first
              as PrintCoordinateContext;

      expect(capturedContext.isIdentity, isTrue);
    });

    test('Valid calibration -> applies rules and matches parameters', () async {
      fakePrintingPlatform.printersList = [
        const Printer(name: 'Zebra ZT411-A', url: 'zebra-url'),
      ];

      when(
        () => mockLayout.buildPdfBytes(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          printFromBottom: any(named: 'printFromBottom'),
          physicalFormat: any(named: 'physicalFormat'),
          coordinateContext: any(named: 'coordinateContext'),
        ),
      ).thenAnswer((_) async => Uint8List(0));

      final result = await calibrationService.printLabels(
        items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
        template: testTemplate,
        disabledSlots: {},
        printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
        executionConfiguration: PrintExecutionConfiguration(
          selectedTray: testTray,
          paperConfigurationId: 'temp-1',
        ),
      );

      expect(result, isA<Success<void, AppError>>());
      final capturedContext =
          verify(
                () => mockLayout.buildPdfBytes(
                  items: any(named: 'items'),
                  template: any(named: 'template'),
                  disabledSlots: any(named: 'disabledSlots'),
                  printFromBottom: any(named: 'printFromBottom'),
                  physicalFormat: any(named: 'physicalFormat'),
                  coordinateContext: captureAny(named: 'coordinateContext'),
                ),
              ).captured.first
              as PrintCoordinateContext;

      expect(capturedContext.isIdentity, isFalse);
      final transform0 = capturedContext.stickerTransforms[0];
      expect(transform0, isNotNull);
      expect(transform0!.scaleX, equals(0.95));
      expect(transform0.anchorX, equals(0.0));
    });

    test('Unsupported paper configuration -> returns failure', () async {
      fakePrintingPlatform.printersList = [
        const Printer(name: 'Zebra ZT411-A', url: 'zebra-url'),
      ];

      final result = await calibrationService.printLabels(
        items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 1)],
        template: testTemplate,
        disabledSlots: {},
        printer: const PrinterDevice(name: 'Zebra ZT411-A', url: 'zebra-url'),
        executionConfiguration: PrintExecutionConfiguration(
          selectedTray: testTray,
          paperConfigurationId: 'unsupported-temp-id',
        ),
      );

      expect(result, isA<Failure<void, AppError>>());
      final error = (result as Failure<void, AppError>).error;
      expect(error, isA<ValidationError>());
      expect(error.message, contains('not supported by the tray'));
    });
  });
}
