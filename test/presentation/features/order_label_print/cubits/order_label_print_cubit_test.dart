import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}
class MockProductRepository extends Mock implements ProductRepository {}
class MockPrintService extends Mock implements PrintService {}
class MockPrinterDiscoveryService extends Mock implements PrinterDiscoveryService {}
class MockPrintJobRepository extends Mock implements PrintJobRepository {}
class MockVariantPrintStatsRepository extends Mock implements VariantPrintStatsRepository {}
class MockPrintJobIdGenerator extends Mock implements PrintJobIdGenerator {}
class MockPrinterProfileRepository extends Mock implements PrinterProfileRepository {}
class MockPrinterCalibrationCoordinateResolver extends Mock implements PrinterCalibrationCoordinateResolver {}
class MockTemplatePrinterCompatibilityAnalyzer extends Mock implements TemplatePrinterCompatibilityAnalyzer {}
class MockPrintPipelineOrchestrator extends Mock implements PrintPipelineOrchestrator {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTemplateRepository mockTemplateRepo;
  late MockProductRepository mockProductRepo;
  late MockPrintService mockPrintService;
  late MockPrinterDiscoveryService mockPrinterDiscoveryService;
  late MockPrintJobRepository mockPrintJobRepo;
  late MockVariantPrintStatsRepository mockVariantPrintStatsRepo;
  late MockPrintJobIdGenerator mockJobIdGen;
  late MockPrinterProfileRepository mockPrinterProfileRepo;
  late MockPrinterCalibrationCoordinateResolver mockCalibrationResolver;
  late MockTemplatePrinterCompatibilityAnalyzer mockCompatibilityAnalyzer;
  late MockPrintPipelineOrchestrator mockOrchestrator;
  late OrderLabelPrintCubit cubit;

  const testProduct = Product(
    id: 'prod-1',
    name: 'Test Product',
    sku: 'PROD-1',
    variants: [
      ProductVariant(
        name: 'Variant 1',
        quantity: 1,
        unit: 'pack',
        wholesale: 10,
        mrp: 15,
        sku: 'VAR-1',
      ),
    ],
  );

  const testVariant = ProductVariant(
    name: 'Variant 1',
    quantity: 1,
    unit: 'pack',
    wholesale: 10,
    mrp: 15,
    sku: 'VAR-1',
  );

  const testTemplate = LabelTemplate(
    id: 'temp-1',
    name: 'Template 1',
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

  const testPrinter = PrinterDevice(name: 'Test Printer', url: 'test-url', isDefault: true);

  setUpAll(() {
    registerFallbackValue(testProduct);
    registerFallbackValue(testVariant);
    registerFallbackValue(testTemplate);
    registerFallbackValue(testPrinter);
    registerFallbackValue(const PrintableItem(product: testProduct, variant: testVariant, quantity: 1));
    registerFallbackValue(
      PrintJob(
        id: 'job-1',
        productId: 'prod-1',
        productName: 'P',
        variantId: 'VAR-1',
        variantName: 'V',
        variantSku: 'VAR-1',
        templateId: 'temp-1',
        templateName: 'T',
        printerStation: 'Pr',
        printedAt: DateTime.now(),
        labelCount: 1,
      ),
    );
  });

  setUp(() {
    mockTemplateRepo = MockTemplateRepository();
    mockProductRepo = MockProductRepository();
    mockPrintService = MockPrintService();
    mockPrinterDiscoveryService = MockPrinterDiscoveryService();
    mockPrintJobRepo = MockPrintJobRepository();
    mockVariantPrintStatsRepo = MockVariantPrintStatsRepository();
    mockJobIdGen = MockPrintJobIdGenerator();
    mockPrinterProfileRepo = MockPrinterProfileRepository();
    mockCalibrationResolver = MockPrinterCalibrationCoordinateResolver();
    mockCompatibilityAnalyzer = MockTemplatePrinterCompatibilityAnalyzer();
    mockOrchestrator = MockPrintPipelineOrchestrator();

    when(() => mockTemplateRepo.fetchTemplates()).thenAnswer((_) async => const Success([testTemplate]));
    when(() => mockProductRepo.getAllProducts()).thenAnswer((_) async => const Success([testProduct]));
    when(() => mockPrinterDiscoveryService.getAvailablePrinters()).thenAnswer((_) async => [testPrinter]);
    when(() => mockPrinterProfileRepo.getAllProfiles()).thenAnswer((_) async => const Success([]));
    when(() => mockJobIdGen.generateId()).thenReturn('job-100');
    when(() => mockPrintJobRepo.savePrintJob(any())).thenAnswer((_) async => const Success(null));
    when(
      () => mockVariantPrintStatsRepo.incrementCount(
        variantSku: any(named: 'variantSku'),
        productId: any(named: 'productId'),
        productName: any(named: 'productName'),
        variantName: any(named: 'variantName'),
        labelCount: any(named: 'labelCount'),
        printedAt: any(named: 'printedAt'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => const Success(null));

    cubit = OrderLabelPrintCubit(
      templateRepository: mockTemplateRepo,
      productRepository: mockProductRepo,
      printService: mockPrintService,
      printerDiscoveryService: mockPrinterDiscoveryService,
      printJobRepository: mockPrintJobRepo,
      variantPrintStatsRepository: mockVariantPrintStatsRepo,
      printJobIdGenerator: mockJobIdGen,
      printerProfileRepository: mockPrinterProfileRepo,
      calibrationResolver: mockCalibrationResolver,
      compatibilityAnalyzer: mockCompatibilityAnalyzer,
      printPipelineOrchestrator: mockOrchestrator,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('OrderLabelPrintCubit Unit Tests', () {
    test('initial state is correct', () {
      expect(cubit.state, const OrderLabelPrintState());
    });

    blocTest<OrderLabelPrintCubit, OrderLabelPrintState>(
      'init loads templates, products, and default printer',
      build: () => cubit,
      act: (c) => c.init(),
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.isLoading, 'isLoading', isTrue),
        isA<OrderLabelPrintState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.templates.length, 'templates.length', 1)
            .having((s) => s.selectedTemplate, 'selectedTemplate', testTemplate)
            .having((s) => s.products.length, 'products.length', 1)
            .having((s) => s.availablePrinters.length, 'printers.length', 1),
      ],
    );

    blocTest<OrderLabelPrintCubit, OrderLabelPrintState>(
      'addOrUpdateItem adds new item or updates existing variant quantity',
      build: () => cubit,
      act: (c) {
        c
          ..addOrUpdateItem(testProduct, testVariant, 5)
          ..addOrUpdateItem(testProduct, testVariant, 10);
      },
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.items.length, 'items.length', 1).having((s) => s.items.first.quantity, 'quantity', 5),
        isA<OrderLabelPrintState>().having((s) => s.items.length, 'items.length', 1).having((s) => s.items.first.quantity, 'quantity', 15),
      ],
    );

    blocTest<OrderLabelPrintCubit, OrderLabelPrintState>(
      'updateItemQuantity updates item quantity or removes if qty <= 0',
      build: () => cubit,
      seed: () => const OrderLabelPrintState(
        items: [PrintableItem(product: testProduct, variant: testVariant, quantity: 5)],
      ),
      act: (c) {
        c
          ..updateItemQuantity(0, 8)
          ..updateItemQuantity(0, 0);
      },
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.items.first.quantity, 'quantity', 8),
        isA<OrderLabelPrintState>().having((s) => s.items.isEmpty, 'items.isEmpty', isTrue),
      ],
    );

    blocTest<OrderLabelPrintCubit, OrderLabelPrintState>(
      'goToNextStep validates step requirements before advancing',
      build: () => cubit,
      act: (c) {
        // Step 1 without template fails
        c.goToNextStep();
        // Select template -> advances to step 2
        c.selectTemplate(testTemplate);
        c.goToNextStep();
      },
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.errorMessage, 'errorMessage', contains('select a label template')),
        isA<OrderLabelPrintState>().having((s) => s.selectedTemplate, 'selectedTemplate', testTemplate),
        isA<OrderLabelPrintState>().having((s) => s.step, 'step', OrderLabelPrintStep.variantSelection),
      ],
    );

    blocTest<OrderLabelPrintCubit, OrderLabelPrintState>(
      'printOrderLabels executes print service and sets isPrintSuccess to true on completion',
      build: () => cubit,
      setUp: () {
        when(
          () => mockPrintService.printLabels(
            items: any(named: 'items'),
            template: any(named: 'template'),
            printer: any(named: 'printer'),
            disabledSlots: any(named: 'disabledSlots'),
            printFromBottom: any(named: 'printFromBottom'),
          ),
        ).thenAnswer((_) async => const Success(null));
      },
      seed: () => const OrderLabelPrintState(
        step: OrderLabelPrintStep.printPreview,
        selectedTemplate: testTemplate,
        selectedPrinter: testPrinter,
        items: [PrintableItem(product: testProduct, variant: testVariant, quantity: 5)],
      ),
      act: (c) => c.printOrderLabels(),
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.isSubmitting, 'isSubmitting', isTrue),
        isA<OrderLabelPrintState>()
            .having((s) => s.isSubmitting, 'isSubmitting', isFalse)
            .having((s) => s.isPrintSuccess, 'isPrintSuccess', isTrue)
            .having((s) => s.successMessage, 'successMessage', contains('Successfully sent order batch')),
      ],
      verify: (_) {
        verify(
          () => mockPrintService.printLabels(
            items: any(named: 'items'),
            template: testTemplate,
            printer: testPrinter,
            disabledSlots: any(named: 'disabledSlots'),
            printFromBottom: any(named: 'printFromBottom'),
          ),
        ).called(1);
        verify(() => mockPrintJobRepo.savePrintJob(any())).called(1);
        verify(
          () => mockVariantPrintStatsRepo.incrementCount(
            variantSku: testVariant.sku,
            productId: testProduct.id,
            productName: testProduct.name,
            variantName: testVariant.name,
            labelCount: 5,
            printedAt: any(named: 'printedAt'),
            imageUrl: testProduct.imageUrl,
          ),
        ).called(1);
      },
    );
  });
}
