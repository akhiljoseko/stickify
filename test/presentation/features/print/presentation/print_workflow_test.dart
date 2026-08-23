import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/print/presentation/print_setup_entry.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';
import '../../../../helpers/pump_app.dart';

class MockSyncableProductRepository extends Mock
    implements SyncableProductRepository {}

class MockSyncableTemplateRepository extends Mock
    implements SyncableTemplateRepository {}

class MockPrintJobRepository extends Mock implements PrintJobRepository {}

class MockPrintService extends Mock implements PrintService {}

class MockPrinterDiscoveryService extends Mock
    implements PrinterDiscoveryService {}

class MockPrintJobIdGenerator extends Mock implements PrintJobIdGenerator {}

class MockVariantPrintStatsRepository extends Mock
    implements VariantPrintStatsRepository {}

class MockLocalDatabase extends Mock implements LocalDatabase {}

class MockSyncablePrinterProfileRepository extends Mock
    implements SyncablePrinterProfileRepository {}

class MockPrinterCalibrationCoordinateResolver extends Mock
    implements PrinterCalibrationCoordinateResolver {}

class MockTemplatePrinterCompatibilityAnalyzer extends Mock
    implements TemplatePrinterCompatibilityAnalyzer {}

class MockPrintPipelineOrchestrator extends Mock
    implements PrintPipelineOrchestrator {}

class MockBatchPrintSummaryRepository extends Mock
    implements BatchPrintSummaryRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockAppServiceLocator extends Mock implements AppServiceLocator {}

class MockGoRouter extends Mock implements GoRouter {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      PrintJob(
        id: 'fallback-job',
        productId: 'fallback-prod',
        productName: 'Fallback',
        variantId: 'SKU',
        variantName: 'Standard',
        variantSku: 'SKU',
        templateId: 'temp',
        templateName: 'Standard Template',
        printerStation: 'Zebra',
        printedAt: DateTime.now(),
        labelCount: 1,
      ),
    );
    registerFallbackValue(
      const Product(
        id: 'fallback-prod',
        name: 'Fallback',
        sku: 'SKU',
      ),
    );
    registerFallbackValue(
      const ProductVariant(
        name: 'Fallback',
        quantity: 0,
        unit: '',
        wholesale: 0,
        mrp: 0,
        sku: 'SKU',
      ),
    );
    registerFallbackValue(
      const LabelTemplate(
        id: 'fallback-temp',
        name: 'Fallback',
      ),
    );
    registerFallbackValue(
      BatchPrintSummary(
        id: 'fallback-summary',
        printedAt: DateTime.now(),
        templateId: 'tpl-id',
        templateName: 'Tpl Name',
        printerName: 'Printer',
        totalQuantity: 1,
        totalSheets: 1,
        items: const [],
      ),
    );
    registerFallbackValue(
      const PrinterDevice(
        name: 'fallback-printer',
        url: 'fallback-url',
      ),
    );
  });

  late SyncableProductRepository productRepository;
  late SyncableTemplateRepository templateRepository;
  late PrintJobRepository printJobRepository;
  late PrintService printService;
  late PrinterDiscoveryService printerDiscoveryService;
  late PrintJobIdGenerator printJobIdGenerator;
  late VariantPrintStatsRepository variantPrintStatsRepository;
  late LocalDatabase localDatabase;
  late SyncablePrinterProfileRepository printerProfileRepository;
  late PrinterCalibrationCoordinateResolver calibrationResolver;
  late TemplatePrinterCompatibilityAnalyzer compatibilityAnalyzer;
  late PrintPipelineOrchestrator printPipelineOrchestrator;
  late BatchPrintSummaryRepository batchPrintSummaryRepository;
  late SettingsRepository settingsRepository;
  late AppServiceLocator serviceLocator;

  const testProduct = Product(
    id: 'prod-test',
    name: 'Dynamic Product',
    sku: 'PROD-SKU',
    variants: [
      ProductVariant(
        name: 'Pack of 10',
        quantity: 10,
        unit: 'pcs',
        wholesale: 150,
        mrp: 200,
        sku: 'PROD-VAR-SKU',
      ),
    ],
  );

  const testTemplate = LabelTemplate(
    id: 'temp-test',
    name: 'A4 Shipping Label',
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
      widthMm: 90,
      heightMm: 50,
      cornerRadiusMm: 2,
      printableArea: [],
    ),
    elements: [
      TextElementBlueprint(
        id: 'txt-1',
        x: 10,
        y: 10,
        width: 150,
        height: 20,
        rotation: 0,
        content: 'Name: {{product.name}}',
        isDynamic: true,
        fontSize: 12,
        fontWeightValue: 400,
        textAlign: BlueprintTextAlign.left,
        colorHex: 0xFF000000,
      ),
      TextElementBlueprint(
        id: 'txt-2',
        x: 10,
        y: 30,
        width: 150,
        height: 20,
        rotation: 0,
        content: 'SKU: {{variant.sku}}',
        isDynamic: true,
        fontSize: 12,
        fontWeightValue: 400,
        textAlign: BlueprintTextAlign.left,
        colorHex: 0xFF000000,
      ),
      TextElementBlueprint(
        id: 'txt-3',
        x: 10,
        y: 50,
        width: 150,
        height: 20,
        rotation: 0,
        content: 'MRP: {{variant.mrp}}',
        isDynamic: true,
        fontSize: 12,
        fontWeightValue: 400,
        textAlign: BlueprintTextAlign.left,
        colorHex: 0xFF000000,
      ),
    ],
    isFinalized: true,
  );

  group('Token Resolution Tests', () {
    test('resolves product and variant tokens correctly', () {
      const input =
          'Product: {{product.name}}, Variant SKU: {{variant.sku}}, MRP: ₹{{variant.mrp}}';
      final resolved = TextElementRenderer.resolveToken(
        input,
        testProduct,
        testProduct.variants.first,
      );
      expect(
        resolved,
        'Product: Dynamic Product, Variant SKU: PROD-VAR-SKU, MRP: ₹200.00',
      );
    });
  });

  group('PrintWorkflowCubit Tests', () {
    setUp(() {
      productRepository = MockSyncableProductRepository();
      templateRepository = MockSyncableTemplateRepository();
      printJobRepository = MockPrintJobRepository();
      printService = MockPrintService();
      printerDiscoveryService = MockPrinterDiscoveryService();
      printJobIdGenerator = MockPrintJobIdGenerator();
      variantPrintStatsRepository = MockVariantPrintStatsRepository();
      localDatabase = MockLocalDatabase();
      printerProfileRepository = MockSyncablePrinterProfileRepository();
      calibrationResolver = MockPrinterCalibrationCoordinateResolver();
      compatibilityAnalyzer = MockTemplatePrinterCompatibilityAnalyzer();
      printPipelineOrchestrator = MockPrintPipelineOrchestrator();
      batchPrintSummaryRepository = MockBatchPrintSummaryRepository();
      settingsRepository = MockSettingsRepository();
      serviceLocator = MockAppServiceLocator();

      when(
        () => settingsRepository.getSettings(),
      ).thenAnswer((_) async => AppSettings.defaults);

      when(
        () => batchPrintSummaryRepository.saveSummary(any()),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => batchPrintSummaryRepository.onSummariesChanged,
      ).thenAnswer((_) => const Stream.empty());

      when(
        () => localDatabase.get<bool>(any(), any()),
      ).thenAnswer((_) async => false);
      when(
        () => localDatabase.get<List<dynamic>>(any(), any()),
      ).thenAnswer((_) async => null);
      when(
        () => localDatabase.save<bool>(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => localDatabase.save<List<int>>(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => localDatabase.delete(any(), any()),
      ).thenAnswer((_) async {});
      when(() => printJobIdGenerator.generateId()).thenReturn('job-12345');
      when(
        () => productRepository.getProductById('prod-test'),
      ).thenAnswer((_) async => const Result.success(testProduct));
      when(
        () => templateRepository.fetchTemplates(),
      ).thenAnswer((_) async => const Result.success([testTemplate]));
      when(
        () => printJobRepository.savePrintJob(any()),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => variantPrintStatsRepository.incrementCount(
          variantSku: any(named: 'variantSku'),
          productId: any(named: 'productId'),
          productName: any(named: 'productName'),
          variantName: any(named: 'variantName'),
          labelCount: any(named: 'labelCount'),
          printedAt: any(named: 'printedAt'),
        ),
      ).thenAnswer((_) async => const Result.success(null));
      when(() => printJobRepository.onPrintJobCreated).thenAnswer(
        (_) => const Stream.empty(),
      );
      when(() => printerDiscoveryService.getAvailablePrinters()).thenAnswer(
        (_) async => const [
          PrinterDevice(
            name: 'Zebra ZT411-A',
            url: 'zebra-url',
            isDefault: true,
          ),
        ],
      );
      when(
        () => printService.printLabels(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          printer: any(named: 'printer'),
          printFromBottom: any(named: 'printFromBottom'),
          executionConfiguration: any(named: 'executionConfiguration'),
        ),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => printerProfileRepository.getAllProfiles(),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => serviceLocator.productRepository,
      ).thenReturn(productRepository);
      when(
        () => serviceLocator.templateRepository,
      ).thenReturn(templateRepository);
      when(
        () => serviceLocator.printJobRepository,
      ).thenReturn(printJobRepository);
      when(
        () => serviceLocator.variantPrintStatsRepository,
      ).thenReturn(variantPrintStatsRepository);
      when(() => serviceLocator.printService).thenReturn(printService);
      when(
        () => serviceLocator.printerDiscoveryService,
      ).thenReturn(printerDiscoveryService);
      when(
        () => serviceLocator.printJobIdGenerator,
      ).thenReturn(printJobIdGenerator);
      when(() => serviceLocator.database).thenReturn(localDatabase);
      when(
        () => serviceLocator.printerProfileRepository,
      ).thenReturn(printerProfileRepository);
      when(
        () => serviceLocator.printerCalibrationCoordinateResolver,
      ).thenReturn(calibrationResolver);
      when(
        () => serviceLocator.templatePrinterCompatibilityAnalyzer,
      ).thenReturn(compatibilityAnalyzer);
      when(
        () => serviceLocator.printPipelineOrchestrator,
      ).thenReturn(printPipelineOrchestrator);
      when(
        () => serviceLocator.batchPrintSummaryRepository,
      ).thenReturn(batchPrintSummaryRepository);
      when(
        () => serviceLocator.settingsRepository,
      ).thenReturn(settingsRepository);
    });

    test('loads workflow successfully and sets initial state', () async {
      final cubit = PrintWorkflowCubit(
        productRepository: productRepository,
        templateRepository: templateRepository,
        printJobRepository: printJobRepository,
        variantPrintStatsRepository: variantPrintStatsRepository,
        printService: printService,
        printerDiscoveryService: printerDiscoveryService,
        printJobIdGenerator: printJobIdGenerator,
        localDatabase: localDatabase,
        printerProfileRepository: printerProfileRepository,
        calibrationResolver: calibrationResolver,
        compatibilityAnalyzer: compatibilityAnalyzer,
        printPipelineOrchestrator: printPipelineOrchestrator,
        batchPrintSummaryRepository: batchPrintSummaryRepository,
      );

      expect(cubit.state, const PrintWorkflowInitial());

      await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

      expect(cubit.state, isA<PrintWorkflowLoaded>());
      final s = cubit.state as PrintWorkflowLoaded;
      expect(s.product!.id, 'prod-test');
      expect(s.variant!.sku, 'PROD-VAR-SKU');
      expect(s.selectedTemplate?.id, 'temp-test');
      expect(s.quantity, 10);
      expect(s.disabledSlots, isEmpty);
    });

    test('updating quantity, printer and toggling slots works', () async {
      final cubit = PrintWorkflowCubit(
        productRepository: productRepository,
        templateRepository: templateRepository,
        printJobRepository: printJobRepository,
        variantPrintStatsRepository: variantPrintStatsRepository,
        printService: printService,
        printerDiscoveryService: printerDiscoveryService,
        printJobIdGenerator: printJobIdGenerator,
        localDatabase: localDatabase,
        printerProfileRepository: printerProfileRepository,
        calibrationResolver: calibrationResolver,
        compatibilityAnalyzer: compatibilityAnalyzer,
        printPipelineOrchestrator: printPipelineOrchestrator,
        batchPrintSummaryRepository: batchPrintSummaryRepository,
      );

      await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

      cubit.updateQuantity(35);
      expect((cubit.state as PrintWorkflowLoaded).quantity, 35);

      await cubit.updatePrinter(
        const PrinterDevice(
          name: 'Industrial Master B3',
          url: 'industrial-url',
        ),
      );
      await pumpEventQueue();
      expect(
        (cubit.state as PrintWorkflowLoaded).selectedPrinter?.name,
        'Industrial Master B3',
      );

      cubit.toggleSlot(3);
      expect((cubit.state as PrintWorkflowLoaded).disabledSlots, contains(3));

      cubit.toggleSlot(3);
      expect(
        (cubit.state as PrintWorkflowLoaded).disabledSlots,
        isNot(contains(3)),
      );
    });

    test(
      'selectAllFirstSheet, deselectAllFirstSheet and togglePrintFromBottom work',
      () async {
        final cubit = PrintWorkflowCubit(
          productRepository: productRepository,
          templateRepository: templateRepository,
          printJobRepository: printJobRepository,
          variantPrintStatsRepository: variantPrintStatsRepository,
          printService: printService,
          printerDiscoveryService: printerDiscoveryService,
          printJobIdGenerator: printJobIdGenerator,
          localDatabase: localDatabase,
          printerProfileRepository: printerProfileRepository,
          calibrationResolver: calibrationResolver,
          compatibilityAnalyzer: compatibilityAnalyzer,
          printPipelineOrchestrator: printPipelineOrchestrator,
          batchPrintSummaryRepository: batchPrintSummaryRepository,
        );

        await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

        // Originally, disabledSlots is empty
        expect((cubit.state as PrintWorkflowLoaded).disabledSlots, isEmpty);

        // Deselect all on first sheet (10 slots)
        cubit.deselectAllFirstSheet();
        expect(
          (cubit.state as PrintWorkflowLoaded).disabledSlots,
          hasLength(10),
        );
        expect(
          (cubit.state as PrintWorkflowLoaded).disabledSlots,
          containsAll(Iterable<int>.generate(10)),
        );

        // Select all on first sheet
        cubit.selectAllFirstSheet();
        expect((cubit.state as PrintWorkflowLoaded).disabledSlots, isEmpty);

        // Toggle print from bottom
        await cubit.togglePrintFromBottom(value: true);
        expect((cubit.state as PrintWorkflowLoaded).printFromBottom, isTrue);
        verify(
          () => localDatabase.save<bool>('settings', 'print_from_bottom', true),
        ).called(1);
      },
    );

    test('toggleRowSlots selects and deselects entire row correctly', () async {
      final cubit = PrintWorkflowCubit(
        productRepository: productRepository,
        templateRepository: templateRepository,
        printJobRepository: printJobRepository,
        variantPrintStatsRepository: variantPrintStatsRepository,
        printService: printService,
        printerDiscoveryService: printerDiscoveryService,
        printJobIdGenerator: printJobIdGenerator,
        localDatabase: localDatabase,
        printerProfileRepository: printerProfileRepository,
        calibrationResolver: calibrationResolver,
        compatibilityAnalyzer: compatibilityAnalyzer,
        printPipelineOrchestrator: printPipelineOrchestrator,
        batchPrintSummaryRepository: batchPrintSummaryRepository,
      );

      await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

      // Originally, disabledSlots is empty
      expect((cubit.state as PrintWorkflowLoaded).disabledSlots, isEmpty);

      // Deselect row 1 of sheet 0 (columns = 2, so slots 2 and 3 are row 1)
      cubit.toggleRowSlots(0, 1, select: false);
      expect(
        (cubit.state as PrintWorkflowLoaded).disabledSlots,
        containsAll([2, 3]),
      );
      expect((cubit.state as PrintWorkflowLoaded).disabledSlots.length, 2);

      // Select row 1 back
      cubit.toggleRowSlots(0, 1, select: true);
      expect((cubit.state as PrintWorkflowLoaded).disabledSlots, isEmpty);
    });

    test(
      'starting print job successfully dispatches and saves print job',
      () async {
        final cubit = PrintWorkflowCubit(
          productRepository: productRepository,
          templateRepository: templateRepository,
          printJobRepository: printJobRepository,
          variantPrintStatsRepository: variantPrintStatsRepository,
          printService: printService,
          printerDiscoveryService: printerDiscoveryService,
          printJobIdGenerator: printJobIdGenerator,
          localDatabase: localDatabase,
          printerProfileRepository: printerProfileRepository,
          calibrationResolver: calibrationResolver,
          compatibilityAnalyzer: compatibilityAnalyzer,
          printPipelineOrchestrator: printPipelineOrchestrator,
          batchPrintSummaryRepository: batchPrintSummaryRepository,
        );

        await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');
        await cubit.startPrintJob();

        expect(cubit.state, isA<PrintWorkflowSuccess>());
        verify(() => printJobRepository.savePrintJob(any())).called(1);
        verify(
          () => variantPrintStatsRepository.incrementCount(
            variantSku: any(named: 'variantSku'),
            productId: any(named: 'productId'),
            productName: any(named: 'productName'),
            variantName: any(named: 'variantName'),
            labelCount: any(named: 'labelCount'),
            printedAt: any(named: 'printedAt'),
          ),
        ).called(1);
        verify(
          () => printService.printLabels(
            items: any(named: 'items'),
            template: any(named: 'template'),
            disabledSlots: any(named: 'disabledSlots'),
            printer: any(named: 'printer'),
            printFromBottom: any(named: 'printFromBottom'),
          ),
        ).called(1);
        verifyNever(() => batchPrintSummaryRepository.saveSummary(any()));
      },
    );

    test(
      'ignores saved partial sheet slots when enableResumePartialSheet is false',
      () async {
        when(() => settingsRepository.getSettings()).thenAnswer(
          (_) async => const AppSettings(enableResumePartialSheet: false),
        );
        when(() => localDatabase.get<List<dynamic>>('partial_sheets', 'temp-test'))
            .thenAnswer((_) async => [0, 1, 2]);

        final cubit = PrintWorkflowCubit(
          productRepository: productRepository,
          templateRepository: templateRepository,
          printJobRepository: printJobRepository,
          variantPrintStatsRepository: variantPrintStatsRepository,
          printService: printService,
          printerDiscoveryService: printerDiscoveryService,
          printJobIdGenerator: printJobIdGenerator,
          localDatabase: localDatabase,
          printerProfileRepository: printerProfileRepository,
          calibrationResolver: calibrationResolver,
          compatibilityAnalyzer: compatibilityAnalyzer,
          printPipelineOrchestrator: printPipelineOrchestrator,
          batchPrintSummaryRepository: batchPrintSummaryRepository,
          settingsRepository: settingsRepository,
        );

        await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

        final state = cubit.state as PrintWorkflowLoaded;
        expect(state.disabledSlots, isEmpty);
        expect(state.isResumingPartialSheet, isFalse);
      },
    );

    test(
      'initForBatch groups identical variant items when groupBatchVariants is true',
      () async {
        when(() => settingsRepository.getSettings()).thenAnswer(
          (_) async => AppSettings.defaults,
        );

        final cubit = PrintWorkflowCubit(
          productRepository: productRepository,
          templateRepository: templateRepository,
          printJobRepository: printJobRepository,
          variantPrintStatsRepository: variantPrintStatsRepository,
          printService: printService,
          printerDiscoveryService: printerDiscoveryService,
          printJobIdGenerator: printJobIdGenerator,
          localDatabase: localDatabase,
          printerProfileRepository: printerProfileRepository,
          calibrationResolver: calibrationResolver,
          compatibilityAnalyzer: compatibilityAnalyzer,
          printPipelineOrchestrator: printPipelineOrchestrator,
          batchPrintSummaryRepository: batchPrintSummaryRepository,
          settingsRepository: settingsRepository,
        );

        const prodB = Product(
          id: 'prod-b',
          name: 'Product B',
          sku: 'PROD-B-SKU',
          variants: [
            ProductVariant(
              name: 'V1',
              quantity: 5,
              unit: 'pcs',
              wholesale: 10,
              mrp: 20,
              sku: 'VAR-B1',
            ),
          ],
        );

        final rawItems = [
          PrintableItem(
            product: testProduct,
            variant: testProduct.variants.first,
            quantity: 5,
          ),
          PrintableItem(
            product: prodB,
            variant: prodB.variants.first,
            quantity: 5,
          ),
          PrintableItem(
            product: testProduct,
            variant: testProduct.variants.first,
            quantity: 3,
          ),
        ];

        await cubit.initForBatch(items: rawItems, template: testTemplate);

        final state = cubit.state as PrintWorkflowLoaded;
        expect(state.items.length, 2);
        expect(state.items[0].product.id, 'prod-test');
        expect(state.items[0].quantity, 8);
        expect(state.items[1].product.id, 'prod-b');
        expect(state.items[1].quantity, 5);
      },
    );

    test(
      'initForBatch preserves raw item order when groupBatchVariants is false',
      () async {
        when(() => settingsRepository.getSettings()).thenAnswer(
          (_) async => const AppSettings(groupBatchVariants: false),
        );

        final cubit = PrintWorkflowCubit(
          productRepository: productRepository,
          templateRepository: templateRepository,
          printJobRepository: printJobRepository,
          variantPrintStatsRepository: variantPrintStatsRepository,
          printService: printService,
          printerDiscoveryService: printerDiscoveryService,
          printJobIdGenerator: printJobIdGenerator,
          localDatabase: localDatabase,
          printerProfileRepository: printerProfileRepository,
          calibrationResolver: calibrationResolver,
          compatibilityAnalyzer: compatibilityAnalyzer,
          printPipelineOrchestrator: printPipelineOrchestrator,
          batchPrintSummaryRepository: batchPrintSummaryRepository,
          settingsRepository: settingsRepository,
        );

        const prodB = Product(
          id: 'prod-b',
          name: 'Product B',
          sku: 'PROD-B-SKU',
          variants: [
            ProductVariant(
              name: 'V1',
              quantity: 5,
              unit: 'pcs',
              wholesale: 10,
              mrp: 20,
              sku: 'VAR-B1',
            ),
          ],
        );

        final rawItems = [
          PrintableItem(
            product: testProduct,
            variant: testProduct.variants.first,
            quantity: 5,
          ),
          PrintableItem(
            product: prodB,
            variant: prodB.variants.first,
            quantity: 5,
          ),
          PrintableItem(
            product: testProduct,
            variant: testProduct.variants.first,
            quantity: 3,
          ),
        ];

        await cubit.initForBatch(items: rawItems, template: testTemplate);

        final state = cubit.state as PrintWorkflowLoaded;
        expect(state.items.length, 3);
        expect(state.items[0].quantity, 5);
        expect(state.items[1].quantity, 5);
        expect(state.items[2].quantity, 3);
      },
    );
  });

  group('PrintSetupPage Widget Tests', () {
    late GoRouter goRouter;

    setUp(() {
      goRouter = MockGoRouter();
      productRepository = MockSyncableProductRepository();
      templateRepository = MockSyncableTemplateRepository();
      printJobRepository = MockPrintJobRepository();
      printService = MockPrintService();
      printerDiscoveryService = MockPrinterDiscoveryService();
      printJobIdGenerator = MockPrintJobIdGenerator();
      variantPrintStatsRepository = MockVariantPrintStatsRepository();
      localDatabase = MockLocalDatabase();
      printerProfileRepository = MockSyncablePrinterProfileRepository();
      calibrationResolver = MockPrinterCalibrationCoordinateResolver();
      compatibilityAnalyzer = MockTemplatePrinterCompatibilityAnalyzer();
      printPipelineOrchestrator = MockPrintPipelineOrchestrator();
      batchPrintSummaryRepository = MockBatchPrintSummaryRepository();
      settingsRepository = MockSettingsRepository();
      serviceLocator = MockAppServiceLocator();

      when(
        () => settingsRepository.getSettings(),
      ).thenAnswer((_) async => AppSettings.defaults);
      when(
        () => settingsRepository.watchSettings,
      ).thenAnswer((_) => Stream.value(AppSettings.defaults));

      when(
        () => localDatabase.get<bool>(any(), any()),
      ).thenAnswer((_) async => false);
      when(
        () => localDatabase.get<List<dynamic>>(any(), any()),
      ).thenAnswer((_) async => null);
      when(
        () => localDatabase.save<bool>(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => localDatabase.save<List<int>>(any(), any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => localDatabase.delete(any(), any()),
      ).thenAnswer((_) async {});

      when(() => printJobIdGenerator.generateId()).thenReturn('job-12345');
      when(
        () => productRepository.getProductById('prod-test'),
      ).thenAnswer((_) async => const Result.success(testProduct));
      when(
        () => templateRepository.fetchTemplates(),
      ).thenAnswer((_) async => const Result.success([testTemplate]));
      when(() => printJobRepository.onPrintJobCreated).thenAnswer(
        (_) => const Stream.empty(),
      );
      when(() => batchPrintSummaryRepository.onSummariesChanged).thenAnswer(
        (_) => const Stream.empty(),
      );
      when(
        () => printJobRepository.savePrintJob(any()),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => variantPrintStatsRepository.incrementCount(
          variantSku: any(named: 'variantSku'),
          productId: any(named: 'productId'),
          productName: any(named: 'productName'),
          variantName: any(named: 'variantName'),
          labelCount: any(named: 'labelCount'),
          printedAt: any(named: 'printedAt'),
        ),
      ).thenAnswer((_) async => const Result.success(null));
      when(() => printerDiscoveryService.getAvailablePrinters()).thenAnswer(
        (_) async => const [
          PrinterDevice(
            name: 'Zebra ZT411-A (Default)',
            url: 'zebra-url',
            isDefault: true,
          ),
          PrinterDevice(name: 'Brother QL-820NWB', url: 'brother-url'),
          PrinterDevice(name: 'Industrial Master B3', url: 'industrial-url'),
        ],
      );
      when(
        () => printService.printLabels(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          printer: any(named: 'printer'),
          printFromBottom: any(named: 'printFromBottom'),
          executionConfiguration: any(named: 'executionConfiguration'),
        ),
      ).thenAnswer((_) async => const Result.success(null));
      when(
        () => printerProfileRepository.getAllProfiles(),
      ).thenAnswer((_) async => const Result.success([]));
      when(
        () => serviceLocator.productRepository,
      ).thenReturn(productRepository);
      when(
        () => serviceLocator.templateRepository,
      ).thenReturn(templateRepository);
      when(
        () => serviceLocator.printJobRepository,
      ).thenReturn(printJobRepository);
      when(
        () => serviceLocator.variantPrintStatsRepository,
      ).thenReturn(variantPrintStatsRepository);
      when(() => serviceLocator.printService).thenReturn(printService);
      when(
        () => serviceLocator.printerDiscoveryService,
      ).thenReturn(printerDiscoveryService);
      when(
        () => serviceLocator.printJobIdGenerator,
      ).thenReturn(printJobIdGenerator);
      when(() => serviceLocator.database).thenReturn(localDatabase);
      when(
        () => serviceLocator.printerProfileRepository,
      ).thenReturn(printerProfileRepository);
      when(
        () => serviceLocator.printerCalibrationCoordinateResolver,
      ).thenReturn(calibrationResolver);
      when(
        () => serviceLocator.templatePrinterCompatibilityAnalyzer,
      ).thenReturn(compatibilityAnalyzer);
      when(
        () => serviceLocator.printPipelineOrchestrator,
      ).thenReturn(printPipelineOrchestrator);
      when(
        () => serviceLocator.batchPrintSummaryRepository,
      ).thenReturn(batchPrintSummaryRepository);
      when(
        () => serviceLocator.settingsRepository,
      ).thenReturn(settingsRepository);
    });

    Widget buildTestableWidget({int? quantity}) {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: serviceLocator),
          RepositoryProvider.value(value: productRepository),
          RepositoryProvider.value(value: templateRepository),
          RepositoryProvider.value(value: printJobRepository),
          RepositoryProvider.value(value: variantPrintStatsRepository),
          RepositoryProvider.value(value: printService),
          RepositoryProvider.value(value: printerDiscoveryService),
          RepositoryProvider.value(value: printJobIdGenerator),
          RepositoryProvider.value(value: localDatabase),
        ],
        child: InheritedGoRouter(
          goRouter: goRouter,
          child: PrintSetupPage(
            productId: 'prod-test',
            variantSku: 'PROD-VAR-SKU',
            templateId: 'temp-test',
            quantity: quantity,
          ),
        ),
      );
    }

    testWidgets(
      'renders configuration page elements with dynamic tokens resolved',
      (tester) async {
        await tester.pumpApp(
          buildTestableWidget(quantity: 20),
          size: const Size(1200, 1000),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dynamic Product'), findsAtLeast(1));
        expect(find.textContaining('PROD-VAR-SKU'), findsAtLeast(1));
        expect(find.textContaining('A4 Shipping Label'), findsAtLeast(1));

        expect(find.text('Quantity to Print'), findsOneWidget);
        expect(find.text('Printer Selection'), findsOneWidget);

        expect(find.text('20 Labels'), findsOneWidget);
        expect(find.text('2 Sheets'), findsOneWidget);
      },
    );

    testWidgets(
      'toggling slot reflows downstream labels and updates required sheets',
      (tester) async {
        await tester.pumpApp(
          buildTestableWidget(quantity: 20),
          size: const Size(1200, 1000),
        );
        await tester.pumpAndSettle();

        final firstSlotInkWell = find
            .descendant(
              of: find.byType(GridView),
              matching: find.byType(InkWell),
            )
            .first;

        await tester.tap(firstSlotInkWell);
        await tester.pumpAndSettle();

        expect(find.text('3 Sheets'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping template selector opens dialog and allows template change',
      (tester) async {
        await tester.pumpApp(
          buildTestableWidget(quantity: 20),
          size: const Size(1200, 1000),
        );
        await tester.pumpAndSettle();

        // Find the template selector field
        final templateSelector = find.text('A4 Shipping Label (10 labels)');
        expect(templateSelector, findsOneWidget);

        // Tap on it to open the selection dialog
        await tester.tap(templateSelector);
        await tester.pumpAndSettle();

        // Check that the dialog is open
        expect(find.text('Select Label Template'), findsOneWidget);
        expect(find.text('2 × 5 Grid'), findsOneWidget);
        expect(find.text('10 Stickers / Sheet'), findsOneWidget);

        // Tap cancel to close dialog
        final cancelButton = find.text('Cancel');
        expect(cancelButton, findsOneWidget);
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();

        expect(find.text('Select Label Template'), findsNothing);
      },
    );

    testWidgets('toggling row checkbox toggles all slots in that row', (
      tester,
    ) async {
      await tester.pumpApp(
        buildTestableWidget(quantity: 20),
        size: const Size(1200, 1000),
      );
      await tester.pumpAndSettle();

      // Verify checkboxes are rendered.
      // With 20 labels and 10 labels/sheet, there are 2 sheets.
      // Each sheet has 5 rows. So 10 checkboxes total.
      final checkboxes = find.byType(Checkbox);
      expect(checkboxes, findsNWidgets(10));

      // Tap on the first checkbox (row 0 of sheet 0, contains slots 0 and 1).
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Disabling 2 slots on sheet 0 pushes the remaining printed labels to a 3rd sheet.
      expect(find.text('3 Sheets'), findsOneWidget);
    });

    testWidgets('pressing Ctrl + P triggers printing', (tester) async {
      await tester.pumpApp(
        buildTestableWidget(quantity: 20),
        size: const Size(1200, 1000),
      );
      await tester.pumpAndSettle();

      // Verify print service was not called initially
      verifyNever(
        () => printService.printLabels(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          printer: any(named: 'printer'),
          printFromBottom: any(named: 'printFromBottom'),
          executionConfiguration: any(named: 'executionConfiguration'),
        ),
      );

      // Simulate Ctrl + P
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify printing was triggered
      verify(
        () => printService.printLabels(
          items: any(named: 'items'),
          template: any(named: 'template'),
          disabledSlots: any(named: 'disabledSlots'),
          printer: any(named: 'printer'),
          printFromBottom: any(named: 'printFromBottom'),
          executionConfiguration: any(named: 'executionConfiguration'),
        ),
      ).called(1);
    });
  });
}
