import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';

/// Drives the 4-step wizard for batch printing labels across multiple products/variants.
class OrderLabelPrintCubit extends Cubit<OrderLabelPrintState> {
  /// Creates an [OrderLabelPrintCubit].
  OrderLabelPrintCubit({
    required TemplateRepository templateRepository,
    required ProductRepository productRepository,
    required PrintService printService,
    required PrinterDiscoveryService printerDiscoveryService,
    required PrintJobRepository printJobRepository,
    required VariantPrintStatsRepository variantPrintStatsRepository,
    required PrintJobIdGenerator printJobIdGenerator,
    required PrinterProfileRepository printerProfileRepository,
    required PrinterCalibrationCoordinateResolver calibrationResolver,
    required TemplatePrinterCompatibilityAnalyzer compatibilityAnalyzer,
    required PrintPipelineOrchestrator printPipelineOrchestrator,
  })  : _templateRepository = templateRepository,
        _productRepository = productRepository,
        _printService = printService,
        _printerDiscoveryService = printerDiscoveryService,
        _printJobRepository = printJobRepository,
        _variantPrintStatsRepository = variantPrintStatsRepository,
        _printJobIdGenerator = printJobIdGenerator,
        _printerProfileRepository = printerProfileRepository,
        _calibrationResolver = calibrationResolver,
        _compatibilityAnalyzer = compatibilityAnalyzer,
        _printPipelineOrchestrator = printPipelineOrchestrator,
        super(const OrderLabelPrintState());

  final TemplateRepository _templateRepository;
  final ProductRepository _productRepository;
  final PrintService _printService;
  final PrinterDiscoveryService _printerDiscoveryService;
  final PrintJobRepository _printJobRepository;
  final VariantPrintStatsRepository _variantPrintStatsRepository;
  final PrintJobIdGenerator _printJobIdGenerator;
  final PrinterProfileRepository _printerProfileRepository;
  final PrinterCalibrationCoordinateResolver _calibrationResolver;
  final TemplatePrinterCompatibilityAnalyzer _compatibilityAnalyzer;
  final PrintPipelineOrchestrator _printPipelineOrchestrator;

  /// Initializes templates catalog, product catalog, and available printers.
  Future<void> init() async {
    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    final templatesResult = await _templateRepository.fetchTemplates();
    final productsResult = await _productRepository.getAllProducts();
    final printers = await _printerDiscoveryService.getAvailablePrinters();

    List<LabelTemplate> templates = [];
    if (templatesResult is Success<List<LabelTemplate>, AppError>) {
      templates = templatesResult.value;
    }

    List<Product> products = [];
    if (productsResult is Success<List<Product>, AppError>) {
      products = productsResult.value;
    }

    final defaultPrinter = printers.firstWhere(
      (p) => p.isDefault,
      orElse: () => printers.isNotEmpty ? printers.first : const PrinterDevice(name: 'No Printer Found', url: ''),
    );

    LabelTemplate? defaultTemplate;
    if (templates.isNotEmpty) {
      defaultTemplate = templates.first;
    }

    emit(
      state.copyWith(
        isLoading: false,
        templates: templates,
        selectedTemplate: () => defaultTemplate,
        products: products,
        filteredProducts: products,
        availablePrinters: printers,
        selectedPrinter: () => defaultPrinter,
      ),
    );

    await _updatePrinterCalibrationAndCompatibility(defaultTemplate, defaultPrinter);
  }

  /// Refreshes product catalog from repository (e.g. after a variant detail edit) and updates running batch items.
  Future<void> refreshProductCatalog([Product? updatedProduct, ProductVariant? oldVariant, ProductVariant? updatedVariant]) async {
    final productsResult = await _productRepository.getAllProducts();
    if (productsResult is Success<List<Product>, AppError>) {
      final products = productsResult.value;
      final filtered = _filterProductsList(products, state.searchQuery);

      List<PrintableItem> updatedItems = List<PrintableItem>.from(state.items);
      if (updatedProduct != null && updatedVariant != null) {
        final targetSku = oldVariant?.sku ?? updatedVariant.sku;
        final existingIndex = updatedItems.indexWhere(
          (item) => item.product.id == updatedProduct.id && item.variant.sku == targetSku,
        );

        if (existingIndex >= 0) {
          final currentQty = updatedItems[existingIndex].quantity;
          updatedItems[existingIndex] = PrintableItem(
            product: updatedProduct,
            variant: updatedVariant,
            quantity: currentQty,
          );
        }
      }

      emit(
        state.copyWith(
          products: products,
          filteredProducts: filtered,
          items: updatedItems,
        ),
      );
    }
  }

  /// Sets the active label template and updates printer calibration checks.
  Future<void> selectTemplate(LabelTemplate template) async {
    emit(state.copyWith(selectedTemplate: () => template));
    await _updatePrinterCalibrationAndCompatibility(template, state.selectedPrinter);
  }

  /// Updates active printer device and updates printer calibration checks.
  Future<void> updatePrinter(PrinterDevice printer) async {
    emit(state.copyWith(selectedPrinter: () => printer));
    await _updatePrinterCalibrationAndCompatibility(state.selectedTemplate, printer);
  }

  Future<void> _updatePrinterCalibrationAndCompatibility(
    LabelTemplate? template,
    PrinterDevice? printer,
  ) async {
    if (printer == null) return;

    final profilesResult = await _printerProfileRepository.getAllProfiles();
    PrinterProfile? matchedProfile;
    PrinterTrayProfile? matchedTray;
    CompatibilityAnalysisResult? compatibilityResult;

    if (profilesResult is Success<List<PrinterProfile>, AppError>) {
      final profiles = profilesResult.value;
      matchedProfile = profiles.firstWhereOrNull(
        (p) => p.printerIdentity.systemPrinterName == printer.name,
      );

      if (matchedProfile != null && template != null && template.sheetConfig != null) {
        matchedTray = matchedProfile.trays.firstWhereOrNull(
          (t) => t.supportedPaperConfigurations.any((ref) => ref.id == template.id),
        );

        if (matchedTray != null) {
          final calibrationResult = _calibrationResolver.resolve(
            CalibrationRequest(
              tray: matchedTray,
              paperConfigId: template.id,
              sheetConfig: template.sheetConfig!,
            ),
          );

          final calibrationContext = switch (calibrationResult) {
            Success(value: final context) => context,
            Failure() => const PrintCoordinateContext.identity(),
          };

          compatibilityResult = _compatibilityAnalyzer.analyze(
            template: template,
            printer: matchedProfile,
            tray: matchedTray,
            calibrationContext: calibrationContext,
          );
        }
      }
    }

    emit(
      state.copyWith(
        selectedPrinterProfile: () => matchedProfile,
        selectedTrayProfile: () => matchedTray,
        compatibilityResult: () => compatibilityResult,
      ),
    );
  }

  /// Sets active wizard step directly.
  void setStep(OrderLabelPrintStep step) {
    emit(state.copyWith(step: step, errorMessage: () => null));
  }

  /// Navigates to next step if validation passes.
  bool goToNextStep() {
    switch (state.step) {
      case OrderLabelPrintStep.templateSelection:
        if (state.selectedTemplate == null) {
          emit(state.copyWith(errorMessage: () => 'Please select a label template to continue.'));
          return false;
        }
        emit(state.copyWith(step: OrderLabelPrintStep.variantSelection, errorMessage: () => null));
        return true;

      case OrderLabelPrintStep.variantSelection:
        if (state.items.isEmpty) {
          emit(state.copyWith(errorMessage: () => 'Please add at least one product variant to your order batch.'));
          return false;
        }
        emit(state.copyWith(step: OrderLabelPrintStep.confirmation, errorMessage: () => null));
        return true;

      case OrderLabelPrintStep.confirmation:
        if (state.items.isEmpty) {
          emit(state.copyWith(errorMessage: () => 'Order batch cannot be empty.'));
          return false;
        }
        emit(state.copyWith(step: OrderLabelPrintStep.printPreview, errorMessage: () => null));
        return true;

      case OrderLabelPrintStep.printPreview:
        return true;
    }
  }

  /// Navigates to previous step.
  void goToPreviousStep() {
    switch (state.step) {
      case OrderLabelPrintStep.templateSelection:
        break;
      case OrderLabelPrintStep.variantSelection:
        emit(state.copyWith(step: OrderLabelPrintStep.templateSelection, errorMessage: () => null));
      case OrderLabelPrintStep.confirmation:
        emit(state.copyWith(step: OrderLabelPrintStep.variantSelection, errorMessage: () => null));
      case OrderLabelPrintStep.printPreview:
        emit(state.copyWith(step: OrderLabelPrintStep.confirmation, errorMessage: () => null));
    }
  }

  /// Filters product catalog by name, SKU, or keywords.
  void updateSearchQuery(String query) {
    final filtered = _filterProductsList(state.products, query);
    emit(state.copyWith(searchQuery: query, filteredProducts: filtered));
  }

  List<Product> _filterProductsList(List<Product> products, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return products;

    return products.where((p) {
      final nameMatch = p.name.toLowerCase().contains(trimmed);
      final skuMatch = p.sku.toLowerCase().contains(trimmed);
      final variantMatch = p.variants.any(
        (v) => v.name.toLowerCase().contains(trimmed) || v.sku.toLowerCase().contains(trimmed),
      );
      return nameMatch || skuMatch || variantMatch;
    }).toList();
  }

  /// Adds a variant to running batch or accumulates quantity if already added.
  void addOrUpdateItem(Product product, ProductVariant variant, int quantity) {
    if (quantity <= 0) return;

    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id && item.variant.sku == variant.sku,
    );

    final updatedItems = List<PrintableItem>.from(state.items);
    if (existingIndex >= 0) {
      final currentQty = updatedItems[existingIndex].quantity;
      updatedItems[existingIndex] = PrintableItem(
        product: product,
        variant: variant,
        quantity: currentQty + quantity,
      );
    } else {
      updatedItems.add(
        PrintableItem(
          product: product,
          variant: variant,
          quantity: quantity,
        ),
      );
    }

    emit(state.copyWith(items: updatedItems, disabledSlots: const {}, errorMessage: () => null));
  }

  /// Updates quantity of an item at [index]. If quantity <= 0, removes the item.
  void updateItemQuantity(int index, int quantity) {
    if (index < 0 || index >= state.items.length) return;

    final updatedItems = List<PrintableItem>.from(state.items);
    if (quantity <= 0) {
      updatedItems.removeAt(index);
    } else {
      final item = updatedItems[index];
      updatedItems[index] = PrintableItem(
        product: item.product,
        variant: item.variant,
        quantity: quantity,
      );
    }

    emit(state.copyWith(items: updatedItems, disabledSlots: const {}, errorMessage: () => null));
  }

  /// Removes an item at [index].
  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;

    final updatedItems = List<PrintableItem>.from(state.items);
    updatedItems.removeAt(index);

    emit(state.copyWith(items: updatedItems, disabledSlots: const {}, errorMessage: () => null));
  }

  /// Updates global manufacturing date.
  void updateManufacturingDate(DateTime date) {
    emit(state.copyWith(manufacturingDate: () => date));
  }

  /// Toggles slot state in disabledSlots set.
  void toggleSlot(int slotIndex) {
    final updated = Set<int>.from(state.disabledSlots);
    if (updated.contains(slotIndex)) {
      updated.remove(slotIndex);
    } else {
      updated.add(slotIndex);
    }
    emit(state.copyWith(disabledSlots: updated));
  }

  /// Toggles an entire row of slots on a given sheet.
  void toggleRowSlots(int sheetIndex, int rowIndex, {required bool select}) {
    final template = state.selectedTemplate;
    final sheetConfig = template?.sheetConfig;
    if (template == null || sheetConfig == null) return;

    final columns = sheetConfig.columns;
    final slotsPerSheet = columns * sheetConfig.rows;
    final rowSlots = List.generate(
      columns,
      (c) => sheetIndex * slotsPerSheet + rowIndex * columns + c,
    );

    final updated = Set<int>.from(state.disabledSlots);
    for (final slot in rowSlots) {
      if (select) {
        updated.remove(slot);
      } else {
        updated.add(slot);
      }
    }
    emit(state.copyWith(disabledSlots: updated));
  }

  /// Selects (enables) all slots on the first sheet.
  void selectAllFirstSheet() {
    final template = state.selectedTemplate;
    final sheetConfig = template?.sheetConfig;
    if (template == null || sheetConfig == null) return;

    final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
    final firstSheetSlots = List.generate(slotsPerSheet, (i) => i);

    final updated = Set<int>.from(state.disabledSlots)..removeAll(firstSheetSlots);
    emit(state.copyWith(disabledSlots: updated));
  }

  /// Deselects (disables) all slots on the first sheet.
  void deselectAllFirstSheet() {
    final template = state.selectedTemplate;
    final sheetConfig = template?.sheetConfig;
    if (template == null || sheetConfig == null) return;

    final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
    final firstSheetSlots = List.generate(slotsPerSheet, (i) => i);

    final updated = Set<int>.from(state.disabledSlots)..addAll(firstSheetSlots);
    emit(state.copyWith(disabledSlots: updated));
  }

  /// Toggles print from bottom parameter.
  void togglePrintFromBottom({bool? value}) {
    emit(state.copyWith(printFromBottom: value ?? !state.printFromBottom));
  }

  /// Compiles and dispatches the batch print job to the physical printer, applying tray calibration and execution config.
  Future<void> printOrderLabels() async {
    final template = state.selectedTemplate;
    final printer = state.selectedPrinter;

    if (template == null) {
      emit(state.copyWith(errorMessage: () => 'No template selected.'));
      return;
    }

    if (printer == null) {
      emit(state.copyWith(errorMessage: () => 'No printer selected.'));
      return;
    }

    if (state.items.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'No items in order batch.'));
      return;
    }

    emit(state.copyWith(isSubmitting: true, errorMessage: () => null));

    PrintExecutionConfiguration? executionConfiguration;
    if (state.selectedPrinterProfile != null && state.selectedTrayProfile != null) {
      final orchestratorResult = _printPipelineOrchestrator.resolve(
        template: template,
        printer: state.selectedPrinterProfile!,
        tray: state.selectedTrayProfile!,
        paperConfigurationId: template.id,
      );

      switch (orchestratorResult) {
        case Failure(error: final err):
          emit(state.copyWith(isSubmitting: false, errorMessage: () => err.message));
          return;
        case Success(value: final coordinateContext):
          executionConfiguration = PrintExecutionConfiguration(
            selectedTray: state.selectedTrayProfile,
            paperConfigurationId: template.id,
            coordinateContext: coordinateContext,
          );
      }
    }

    final result = await _printService.printLabels(
      items: state.items,
      template: template,
      printer: printer,
      disabledSlots: state.disabledSlots,
      printFromBottom: state.printFromBottom,
      reverseSheetOrder: state.reverseSheetOrder,
      executionConfiguration: executionConfiguration,
      manufacturingDate: state.manufacturingDate,
    );

    switch (result) {
      case Failure(error: final err):
        emit(state.copyWith(isSubmitting: false, errorMessage: () => err.message));

      case Success():
        // Log print history and increment stats for each variant in the batch
        final now = DateTime.now();
        for (final item in state.items) {
          final job = PrintJob(
            id: _printJobIdGenerator.generateId(),
            productId: item.product.id,
            productName: item.product.name,
            variantId: item.variant.sku,
            variantName: item.variant.name,
            variantSku: item.variant.sku,
            templateId: template.id,
            templateName: template.name,
            printerStation: printer.name,
            printedAt: now,
            labelCount: item.quantity,
            imageUrl: item.product.imageUrl,
          );
          await _printJobRepository.savePrintJob(job);
          await _variantPrintStatsRepository.incrementCount(
            variantSku: item.variant.sku,
            productId: item.product.id,
            productName: item.product.name,
            variantName: item.variant.name,
            labelCount: item.quantity,
            printedAt: now,
            imageUrl: item.product.imageUrl,
          );
        }

        emit(
          state.copyWith(
            isSubmitting: false,
            isPrintSuccess: true,
            successMessage: () => 'Successfully sent order batch (${state.totalQuantity} labels) to printer ${printer.name}!',
          ),
        );
    }
  }
}
