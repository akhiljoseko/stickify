import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';

class MockProductRepository extends Mock implements ProductRepository {}
class MockTemplateRepository extends Mock implements TemplateRepository {}
class MockPrintJobRepository extends Mock implements PrintJobRepository {}
class MockVariantPrintStatsRepository extends Mock implements VariantPrintStatsRepository {}
class MockPrintService extends Mock implements PrintService {}
class MockPrinterDiscoveryService extends Mock implements PrinterDiscoveryService {}
class MockPrintJobIdGenerator extends Mock implements PrintJobIdGenerator {}
class MockLocalDatabase extends Mock implements LocalDatabase {}
class MockPrinterProfileRepository extends Mock implements PrinterProfileRepository {}
class MockPrinterCalibrationCoordinateResolver extends Mock implements PrinterCalibrationCoordinateResolver {}
class MockTemplatePrinterCompatibilityAnalyzer extends Mock implements TemplatePrinterCompatibilityAnalyzer {}
class MockPrintPipelineOrchestrator extends Mock implements PrintPipelineOrchestrator {}

class FakeCalibrationRequest extends Fake implements CalibrationRequest {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProductRepository mockProductRepo;
  late MockTemplateRepository mockTemplateRepo;
  late MockPrintJobRepository mockPrintJobRepo;
  late MockVariantPrintStatsRepository mockVariantStatsRepo;
  late MockPrintService mockPrintService;
  late MockPrinterDiscoveryService mockPrinterDiscoveryService;
  late MockPrintJobIdGenerator mockJobIdGen;
  late MockLocalDatabase mockLocalDb;
  late MockPrinterProfileRepository mockProfileRepo;
  late MockPrinterCalibrationCoordinateResolver mockCalibrationResolver;
  late MockTemplatePrinterCompatibilityAnalyzer mockCompatibilityAnalyzer;
  late MockPrintPipelineOrchestrator mockOrchestrator;
  late PrintWorkflowCubit cubit;

  const testProduct = Product(
    id: 'prod-1',
    name: 'Test Product 1',
    sku: 'SKU-1',
    variants: [
      ProductVariant(
        name: 'Variant 1',
        quantity: 1,
        unit: 'pack',
        wholesale: 10,
        mrp: 20,
        sku: 'V-SKU-1',
      ),
    ],
  );

  const testVariant = ProductVariant(
    name: 'Variant 1',
    quantity: 1,
    unit: 'pack',
    wholesale: 10,
    mrp: 20,
    sku: 'V-SKU-1',
  );

  const testTemplate = LabelTemplate(
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

  const testPrinter = PrinterDevice(name: 'Test Printer', url: 'url-1', isDefault: true);

  final testProfile = PrinterProfile(
    id: 'prof-1',
    displayName: 'Test Printer Profile',
    printerIdentity: const PrinterIdentity(
      systemPrinterName: 'Test Printer',
      driverName: 'Generic',
    ),
    capabilities: const PrinterCapabilities(
      supportsCustomPaperSize: true,
      supportsPortraitCustomPaper: true,
      supportsLandscapeCustomPaper: true,
      supportsManualFeed: false,
      supportsBorderlessPrinting: false,
      supportsTraySelection: true,
      reverseSheetOrder: true,
    ),
    trays: [
      PrinterTrayProfile(
        displayName: 'Tray 1',
        trayIdentifier: 'T1',
        supportedPaperConfigurations: const [PaperConfigurationReference(id: 'temp-1', displayName: 'T1')],
        calibration: PrinterCalibration(enabled: false, calibrationRules: const []),
      ),
    ],
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    status: PrinterProfileStatus.active,
    optimizationPreferences: const OptimizationPreferences(
      allowScaling: true,
      allowTranslation: true,
      allowStickerSpecificAdjustment: true,
    ),
  );

  setUpAll(() {
    registerFallbackValue(FakeCalibrationRequest());
    registerFallbackValue(testProduct);
    registerFallbackValue(testVariant);
    registerFallbackValue(testTemplate);
    registerFallbackValue(testPrinter);
    registerFallbackValue(const PrintableItem(product: testProduct, variant: testVariant, quantity: 5));
    registerFallbackValue(
      PrintJob(
        id: 'job-1',
        productId: 'prod-1',
        productName: 'P',
        variantId: 'V-1',
        variantName: 'V',
        variantSku: 'V-1',
        templateId: 'T-1',
        templateName: 'T',
        printerStation: 'P-1',
        printedAt: DateTime.now(),
        labelCount: 1,
      ),
    );
    registerFallbackValue(testProfile);
    registerFallbackValue(testProfile.trays.first);
    registerFallbackValue(const PrintCoordinateContext.identity());
  });

  setUp(() {
    mockProductRepo = MockProductRepository();
    mockTemplateRepo = MockTemplateRepository();
    mockPrintJobRepo = MockPrintJobRepository();
    mockVariantStatsRepo = MockVariantPrintStatsRepository();
    mockPrintService = MockPrintService();
    mockPrinterDiscoveryService = MockPrinterDiscoveryService();
    mockJobIdGen = MockPrintJobIdGenerator();
    mockLocalDb = MockLocalDatabase();
    mockProfileRepo = MockPrinterProfileRepository();
    mockCalibrationResolver = MockPrinterCalibrationCoordinateResolver();
    mockCompatibilityAnalyzer = MockTemplatePrinterCompatibilityAnalyzer();
    mockOrchestrator = MockPrintPipelineOrchestrator();

    when(() => mockTemplateRepo.fetchTemplates()).thenAnswer((_) async => const Success([testTemplate]));
    when(() => mockPrinterDiscoveryService.getAvailablePrinters()).thenAnswer((_) async => [testPrinter]);
    when(() => mockProfileRepo.getAllProfiles()).thenAnswer((_) async => Success([testProfile]));
    when(() => mockCalibrationResolver.resolve(any())).thenReturn(const Success(PrintCoordinateContext.identity()));
    when(
      () => mockCompatibilityAnalyzer.analyze(
        template: any(named: 'template'),
        printer: any(named: 'printer'),
        tray: any(named: 'tray'),
        calibrationContext: any(named: 'calibrationContext'),
      ),
    ).thenReturn(
      CompatibilityAnalysisResult(
        conflicts: const [],
        recommendedOptimizationLevel: OptimizationLevel.noModification,
      ),
    );
    when(() => mockLocalDb.get<bool>('settings', 'print_from_bottom')).thenAnswer((_) async => true);
    when(() => mockJobIdGen.generateId()).thenReturn('job-123');
    when(() => mockPrintJobRepo.savePrintJob(any())).thenAnswer((_) async => const Success(null));
    when(
      () => mockVariantStatsRepo.incrementCount(
        variantSku: any(named: 'variantSku'),
        productId: any(named: 'productId'),
        productName: any(named: 'productName'),
        variantName: any(named: 'variantName'),
        labelCount: any(named: 'labelCount'),
        printedAt: any(named: 'printedAt'),
        imageUrl: any(named: 'imageUrl'),
      ),
    ).thenAnswer((_) async => const Success(null));

    cubit = PrintWorkflowCubit(
      productRepository: mockProductRepo,
      templateRepository: mockTemplateRepo,
      printJobRepository: mockPrintJobRepo,
      variantPrintStatsRepository: mockVariantStatsRepo,
      printService: mockPrintService,
      printerDiscoveryService: mockPrinterDiscoveryService,
      printJobIdGenerator: mockJobIdGen,
      localDatabase: mockLocalDb,
      printerProfileRepository: mockProfileRepo,
      calibrationResolver: mockCalibrationResolver,
      compatibilityAnalyzer: mockCompatibilityAnalyzer,
      printPipelineOrchestrator: mockOrchestrator,
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('PrintWorkflowCubit Batch Mode Tests', () {
    blocTest<PrintWorkflowCubit, PrintWorkflowState>(
      'initForBatch initializes state with items, reverseSheetOrder capability, and printFromBottom preference',
      build: () => cubit,
      act: (c) => c.initForBatch(
        items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 10)],
        template: testTemplate,
        selectedPrinter: testPrinter,
      ),
      expect: () => [
        isA<PrintWorkflowLoading>(),
        isA<PrintWorkflowLoaded>()
            .having((s) => s.items.length, 'items.length', 1)
            .having((s) => s.totalQuantity, 'totalQuantity', 10)
            .having((s) => s.reverseSheetOrder, 'reverseSheetOrder', isTrue)
            .having((s) => s.printFromBottom, 'printFromBottom', isTrue)
            .having((s) => s.selectedPrinterProfile, 'selectedPrinterProfile', testProfile),
      ],
    );

    blocTest<PrintWorkflowCubit, PrintWorkflowState>(
      'startPrintJob dispatches batch items with reverseSheetOrder and records job logs',
      build: () => cubit,
      setUp: () {
        when(
          () => mockPrintService.printLabels(
            items: any(named: 'items'),
            template: any(named: 'template'),
            printer: any(named: 'printer'),
            disabledSlots: any(named: 'disabledSlots'),
            printFromBottom: any(named: 'printFromBottom'),
            reverseSheetOrder: any(named: 'reverseSheetOrder'),
          ),
        ).thenAnswer((_) async => const Success(null));
      },
      seed: () => PrintWorkflowLoaded(
        items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 10)],
        templates: const [testTemplate],
        selectedTemplate: testTemplate,
        availablePrinters: const [testPrinter],
        selectedPrinter: testPrinter,
        selectedPrinterProfile: testProfile,
        reverseSheetOrder: true,
        printFromBottom: true,
      ),
      act: (c) => c.startPrintJob(),
      expect: () => [
        isA<PrintWorkflowSubmitting>(),
        isA<PrintWorkflowSuccess>(),
      ],
      verify: (_) {
        verify(
          () => mockPrintService.printLabels(
            items: const [PrintableItem(product: testProduct, variant: testVariant, quantity: 10)],
            template: testTemplate,
            printer: testPrinter,
            disabledSlots: any(named: 'disabledSlots'),
            printFromBottom: true,
            reverseSheetOrder: true,
          ),
        ).called(1);
        verify(() => mockPrintJobRepo.savePrintJob(any())).called(1);
      },
    );
  });
}
