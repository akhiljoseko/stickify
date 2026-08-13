import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}
class MockProductRepository extends Mock implements ProductRepository {}
class MockPrinterDiscoveryService extends Mock implements PrinterDiscoveryService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTemplateRepository mockTemplateRepo;
  late MockProductRepository mockProductRepo;
  late MockPrinterDiscoveryService mockPrinterDiscoveryService;
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
  });

  setUp(() {
    mockTemplateRepo = MockTemplateRepository();
    mockProductRepo = MockProductRepository();
    mockPrinterDiscoveryService = MockPrinterDiscoveryService();

    when(() => mockTemplateRepo.fetchTemplates()).thenAnswer((_) async => const Success([testTemplate]));
    when(() => mockProductRepo.getAllProducts()).thenAnswer((_) async => const Success([testProduct]));
    when(() => mockPrinterDiscoveryService.getAvailablePrinters()).thenAnswer((_) async => [testPrinter]);

    cubit = OrderLabelPrintCubit(
      templateRepository: mockTemplateRepo,
      productRepository: mockProductRepo,
      printerDiscoveryService: mockPrinterDiscoveryService,
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
      'addOrUpdateItem adds new item or accumulates existing variant quantity',
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
        // Step 2 without items fails
        c.goToNextStep();
        // Add item -> advances directly to print preview (Step 3)
        c.addOrUpdateItem(testProduct, testVariant, 5);
        c.goToNextStep();
      },
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.errorMessage, 'errorMessage', contains('select a label template')),
        isA<OrderLabelPrintState>().having((s) => s.selectedTemplate, 'selectedTemplate', testTemplate),
        isA<OrderLabelPrintState>().having((s) => s.step, 'step', OrderLabelPrintStep.variantSelection),
        isA<OrderLabelPrintState>().having((s) => s.errorMessage, 'errorMessage', contains('add at least one product variant')),
        isA<OrderLabelPrintState>().having((s) => s.items.length, 'items.length', 1),
        isA<OrderLabelPrintState>().having((s) => s.step, 'step', OrderLabelPrintStep.printPreview),
      ],
    );

    blocTest<OrderLabelPrintCubit, OrderLabelPrintState>(
      'goToPreviousStep steps backward from printPreview directly to variantSelection',
      build: () => cubit,
      seed: () => const OrderLabelPrintState(step: OrderLabelPrintStep.printPreview),
      act: (c) => c.goToPreviousStep(),
      expect: () => [
        isA<OrderLabelPrintState>().having((s) => s.step, 'step', OrderLabelPrintStep.variantSelection),
      ],
    );
  });
}
