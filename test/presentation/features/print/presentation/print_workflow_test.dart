import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/print/presentation/print_setup_entry.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';
import '../../../../helpers/pump_app.dart';

class MockProductRepository extends Mock implements ProductRepository {}
class MockTemplateRepository extends Mock implements TemplateRepository {}
class MockPrintJobRepository extends Mock implements PrintJobRepository {}
class MockPrintService extends Mock implements PrintService {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      PrintJob(
        id: 'fallback-job',
        productName: 'Fallback',
        sku: 'SKU',
        status: PrintJobStatus.completed,
        printerStation: 'Zebra',
        printedAt: DateTime.now(),
        labelCount: 1,
      ),
    );
    registerFallbackValue(
      Product(
        id: 'fallback-prod',
        name: 'Fallback',
        sku: 'SKU',
        totalPrints: 0,
        lastPrintedAt: DateTime(2026),
        assignedStation: '',
        stationStatus: StationStatus.offline,
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
  });

  late ProductRepository productRepository;
  late TemplateRepository templateRepository;
  late PrintJobRepository printJobRepository;
  late PrintService printService;

  final testProduct = Product(
    id: 'prod-test',
    name: 'Dynamic Product',
    sku: 'PROD-SKU',
    totalPrints: 10,
    lastPrintedAt: DateTime(2026),
    assignedStation: 'Station #01',
    stationStatus: StationStatus.online,
    variants: const [
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
      widthMm: 95,
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
      const input = 'Product: {{product.name}}, Variant SKU: {{variant.sku}}, MRP: ₹{{variant.mrp}}';
      final resolved = TextElementRenderer.resolveToken(
        input,
        testProduct,
        testProduct.variants.first,
      );
      expect(resolved, 'Product: Dynamic Product, Variant SKU: PROD-VAR-SKU, MRP: ₹200.00');
    });
  });

  group('PrintWorkflowCubit Tests', () {
    setUp(() {
      productRepository = MockProductRepository();
      templateRepository = MockTemplateRepository();
      printJobRepository = MockPrintJobRepository();
      printService = MockPrintService();

      when(() => productRepository.getProductById('prod-test'))
          .thenAnswer((_) async => Result.success(testProduct));
      when(() => templateRepository.fetchTemplates())
          .thenAnswer((_) async => Result.success([testTemplate]));
      when(() => printJobRepository.savePrintJob(any()))
          .thenAnswer((_) async => const Result.success(null));
      when(() => printService.printLabels(
            product: any(named: 'product'),
            variant: any(named: 'variant'),
            template: any(named: 'template'),
            quantity: any(named: 'quantity'),
            disabledSlots: any(named: 'disabledSlots'),
            printerName: any(named: 'printerName'),
          )).thenAnswer((_) async => const Result.success(null));
    });

    test('loads workflow successfully and sets initial state', () async {
      final cubit = PrintWorkflowCubit(
        productRepository: productRepository,
        templateRepository: templateRepository,
        printJobRepository: printJobRepository,
        printService: printService,
      );

      expect(cubit.state, const PrintWorkflowInitial());

      await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

      expect(cubit.state, isA<PrintWorkflowLoaded>());
      final s = cubit.state as PrintWorkflowLoaded;
      expect(s.product.id, 'prod-test');
      expect(s.variant.sku, 'PROD-VAR-SKU');
      expect(s.selectedTemplate?.id, 'temp-test');
      expect(s.quantity, 20);
      expect(s.disabledSlots, isEmpty);
    });

    test('updating quantity, printer and toggling slots works', () async {
      final cubit = PrintWorkflowCubit(
        productRepository: productRepository,
        templateRepository: templateRepository,
        printJobRepository: printJobRepository,
        printService: printService,
      );

      await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');

      cubit.updateQuantity(35);
      expect((cubit.state as PrintWorkflowLoaded).quantity, 35);

      cubit.updatePrinter('Industrial Master B3');
      expect((cubit.state as PrintWorkflowLoaded).selectedPrinter, 'Industrial Master B3');

      cubit.toggleSlot(3);
      expect((cubit.state as PrintWorkflowLoaded).disabledSlots, contains(3));

      cubit.toggleSlot(3);
      expect((cubit.state as PrintWorkflowLoaded).disabledSlots, isNot(contains(3)));
    });

    test('starting print job successfully dispatches and saves print job', () async {
      final cubit = PrintWorkflowCubit(
        productRepository: productRepository,
        templateRepository: templateRepository,
        printJobRepository: printJobRepository,
        printService: printService,
      );

      await cubit.loadWorkflow('prod-test', 'PROD-VAR-SKU', 'temp-test');
      await cubit.startPrintJob();

      expect(cubit.state, isA<PrintWorkflowSuccess>());
      verify(() => printJobRepository.savePrintJob(any())).called(1);
      verify(() => printService.printLabels(
            product: any(named: 'product'),
            variant: any(named: 'variant'),
            template: any(named: 'template'),
            quantity: any(named: 'quantity'),
            disabledSlots: any(named: 'disabledSlots'),
            printerName: any(named: 'printerName'),
          )).called(1);
    });
  });

  group('PrintSetupPage Widget Tests', () {
    setUp(() {
      productRepository = MockProductRepository();
      templateRepository = MockTemplateRepository();
      printJobRepository = MockPrintJobRepository();
      printService = MockPrintService();

      when(() => productRepository.getProductById('prod-test'))
          .thenAnswer((_) async => Result.success(testProduct));
      when(() => templateRepository.fetchTemplates())
          .thenAnswer((_) async => Result.success([testTemplate]));
      when(() => printService.printLabels(
            product: any(named: 'product'),
            variant: any(named: 'variant'),
            template: any(named: 'template'),
            quantity: any(named: 'quantity'),
            disabledSlots: any(named: 'disabledSlots'),
            printerName: any(named: 'printerName'),
          )).thenAnswer((_) async => const Result.success(null));
    });

    Widget buildTestableWidget() {
      return MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: productRepository),
          RepositoryProvider.value(value: templateRepository),
          RepositoryProvider.value(value: printJobRepository),
          RepositoryProvider.value(value: printService),
        ],
        child: const PrintSetupPage(
          productId: 'prod-test',
          variantSku: 'PROD-VAR-SKU',
          templateId: 'temp-test',
        ),
      );
    }

    testWidgets('renders configuration page elements with dynamic tokens resolved', (tester) async {
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 1000));
      await tester.pumpAndSettle();

      expect(find.text('Dynamic Product'), findsAtLeast(1));
      expect(find.textContaining('PROD-VAR-SKU'), findsAtLeast(1));
      expect(find.textContaining('A4 Shipping Label'), findsAtLeast(1));

      expect(find.text('Quantity to Print'), findsOneWidget);
      expect(find.text('Printer Selection'), findsOneWidget);

      expect(find.text('Sheets Required'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('toggling slot reflows downstream labels and updates required sheets', (tester) async {
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 1000));
      await tester.pumpAndSettle();

      final firstSlotInkWell = find.descendant(
        of: find.byType(GridView),
        matching: find.byType(InkWell),
      ).first;

      await tester.tap(firstSlotInkWell);
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });
  });
}
