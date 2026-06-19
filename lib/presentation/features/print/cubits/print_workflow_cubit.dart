// The initializer list pattern `_field = param` is intentional: constructor
// parameter names must stay public (e.g. `productRepository`) to provide a
// clean named-parameter API for call sites, while field names are private
// (`_productRepository`) to enforce encapsulation. Using `this._field`
// initializing formals would expose underscore-prefixed names in the public
// constructor API.
// ignore_for_file: prefer_initializing_formals
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';

/// Cubit managing the multi-step printing workflow state.
///
/// Handles template selection, quantity updates, slot toggling (for reuse),
/// and print job submission.
class PrintWorkflowCubit extends Cubit<PrintWorkflowState> {
  /// Creates a [PrintWorkflowCubit] with the necessary repositories and services.
  PrintWorkflowCubit({
    required ProductRepository productRepository,
    required TemplateRepository templateRepository,
    required PrintJobRepository printJobRepository,
    required VariantPrintStatsRepository variantPrintStatsRepository,
    required PrintService printService,
    required PrinterDiscoveryService printerDiscoveryService,
    required PrintJobIdGenerator printJobIdGenerator,
    required LocalDatabase localDatabase,
  })  : _productRepository = productRepository,
        _templateRepository = templateRepository,
        _printJobRepository = printJobRepository,
        _variantPrintStatsRepository = variantPrintStatsRepository,
        _printService = printService,
        _printerDiscoveryService = printerDiscoveryService,
        _printJobIdGenerator = printJobIdGenerator,
        _localDatabase = localDatabase,
        super(const PrintWorkflowInitial());

  /// Repository providing product catalog records.
  final ProductRepository _productRepository;

  /// Repository providing label templates.
  final TemplateRepository _templateRepository;

  /// Repository tracking and saving print logs.
  final PrintJobRepository _printJobRepository;

  /// Repository for variant-level print counters.
  final VariantPrintStatsRepository _variantPrintStatsRepository;

  /// Service dispatching compiled labels to physical printer hardware.
  final PrintService _printService;

  /// Service discovering physical/system printers.
  final PrinterDiscoveryService _printerDiscoveryService;

  /// Generator for print job IDs.
  final PrintJobIdGenerator _printJobIdGenerator;

  /// Local database instance for settings caching.
  final LocalDatabase _localDatabase;

  /// Loads the initial metadata needed to configure the print job.
  ///
  /// Fetches [productId], locates the variant by [variantSku], and optionally
  /// sets the initial active layout template by [templateId].
  Future<void> loadWorkflow(String productId, String variantSku, [String? templateId, int? initialQuantity]) async {
    emit(const PrintWorkflowLoading());
    try {
      final productResult = await _productRepository.getProductById(productId);
      switch (productResult) {
        case Failure(error: final err):
          emit(PrintWorkflowError(message: err.message));
          return;
        case Success(value: final product):
          if (product == null) {
            emit(const PrintWorkflowError(message: 'Product not found.'));
            return;
          }

          final variant = product.variants.firstWhere(
            (v) => v.sku == variantSku,
            orElse: () => throw Exception('Variant SKU $variantSku not found in product $productId.'),
          );

          final templatesResult = await _templateRepository.fetchTemplates();
          switch (templatesResult) {
            case Failure(error: final templateErr):
              emit(PrintWorkflowError(message: templateErr.message));
              return;
            case Success(value: final templates):
              LabelTemplate? selected;
              if (templateId != null && templateId.isNotEmpty) {
                selected = templates.firstWhere(
                  (t) => t.id == templateId,
                  orElse: () => templates.isNotEmpty ? templates.first : throw Exception('Template not found.'),
                );
              } else if (templates.isNotEmpty) {
                selected = templates.first;
              }

              final printers = await _printerDiscoveryService.getAvailablePrinters();
              final defaultPrinter = printers.firstWhere(
                (p) => p.isDefault,
                orElse: () => printers.isNotEmpty ? printers.first : const PrinterDevice(name: 'No Printer Found', url: ''),
              );

              final cachedBottom = await _localDatabase.get<bool>('settings', 'print_from_bottom') ?? false;

              final int defaultQty;
              if (initialQuantity != null && initialQuantity > 0) {
                defaultQty = initialQuantity;
              } else if (selected?.sheetConfig != null) {
                defaultQty = selected!.sheetConfig!.columns * selected.sheetConfig!.rows;
              } else {
                defaultQty = 20;
              }

              final loaded = PrintWorkflowLoaded(
                product: product,
                variant: variant,
                templates: templates,
                selectedTemplate: selected,
                availablePrinters: printers,
                selectedPrinter: defaultPrinter,
                quantity: defaultQty,
                printFromBottom: cachedBottom,
                isQuantityManuallyEdited: initialQuantity != null && initialQuantity > 0,
              );
              emit(loaded);
          }
      }
    } on Object catch (e) {
      emit(PrintWorkflowError(message: e.toString()));
    }
  }

  /// Updates the active label template layout.
  void selectTemplate(LabelTemplate template) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final int qty;
      if (!s.isQuantityManuallyEdited && template.sheetConfig != null) {
        qty = template.sheetConfig!.columns * template.sheetConfig!.rows;
      } else {
        qty = s.quantity;
      }

      emit(s.copyWith(
        selectedTemplate: () => template,
        quantity: qty,
        disabledSlots: {}, // reset skipped slots when template changes
      ));
    }
  }

  /// Updates the target label print quantity.
  void updateQuantity(int qty) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(
        quantity: qty,
        isQuantityManuallyEdited: true,
      ));
    }
  }

  /// Updates the selected destination printer.
  void updatePrinter(PrinterDevice printer) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(selectedPrinter: () => printer));
    }
  }

  /// Toggles a specific slot index on the printing grid sheet.
  ///
  /// Toggled slots will be skipped/ignored during PDF page layout compilation.
  void toggleSlot(int absoluteSlotIndex) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final updated = Set<int>.from(s.disabledSlots);
      if (updated.contains(absoluteSlotIndex)) {
        updated.remove(absoluteSlotIndex);
      } else {
        updated.add(absoluteSlotIndex);
      }
      emit(s.copyWith(disabledSlots: updated));
    }
  }

  /// Toggles whether to print from the bottom slots of the last sheet.
  Future<void> togglePrintFromBottom({required bool value}) async {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(printFromBottom: value));
      await _localDatabase.save<bool>('settings', 'print_from_bottom', value);
    }
  }

  /// Selects all slots in the first sheet.
  void selectAllFirstSheet() {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final template = s.selectedTemplate;
      if (template?.sheetConfig == null) return;
      final slotsPerSheet = template!.sheetConfig!.columns * template.sheetConfig!.rows;
      
      final updated = Set<int>.from(s.disabledSlots);
      for (var i = 0; i < slotsPerSheet; i++) {
        updated.remove(i);
      }
      emit(s.copyWith(disabledSlots: updated));
    }
  }

  /// Deselects all slots in the first sheet.
  void deselectAllFirstSheet() {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final template = s.selectedTemplate;
      if (template?.sheetConfig == null) return;
      final slotsPerSheet = template!.sheetConfig!.columns * template.sheetConfig!.rows;

      final updated = Set<int>.from(s.disabledSlots);
      for (var i = 0; i < slotsPerSheet; i++) {
        updated.add(i);
      }
      emit(s.copyWith(disabledSlots: updated));
    }
  }

  /// Compiles the dynamic layout and dispatches the print job.
  ///
  /// Generates the PDF, calls the system printer, and appends a record
  /// to the printed job history repository.
  Future<void> startPrintJob() async {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final template = s.selectedTemplate;
      if (template == null) {
        emit(const PrintWorkflowError(message: 'No label template selected.'));
        return;
      }
      final printer = s.selectedPrinter;
      if (printer == null) {
        emit(const PrintWorkflowError(message: 'No printer selected.'));
        return;
      }

      emit(PrintWorkflowSubmitting(loadedState: s));
      final printResult = await _printService.printLabels(
        product: s.product,
        variant: s.variant,
        template: template,
        quantity: s.quantity,
        disabledSlots: s.disabledSlots,
        printer: printer,
        printFromBottom: s.printFromBottom,
      );

      switch (printResult) {
        case Failure(error: final err):
          emit(PrintWorkflowError(message: err.message));
        case Success():
          final jobId = _printJobIdGenerator.generateId();
          final job = PrintJob(
            id: jobId,
            productId: s.product.id,
            productName: s.product.name,
            variantId: s.variant.sku,
            variantName: s.variant.name,
            variantSku: s.variant.sku,
            templateId: template.id,
            templateName: template.name,
            printerStation: printer.name,
            printedAt: DateTime.now(),
            labelCount: s.quantity,
            imageUrl: s.product.imageUrl,
          );

          final saveResult = await _printJobRepository.savePrintJob(job);
          switch (saveResult) {
            case Failure(error: final saveErr):
              emit(PrintWorkflowError(message: saveErr.message));
            case Success():
              await _variantPrintStatsRepository.incrementCount(
                variantSku: s.variant.sku,
                productId: s.product.id,
                productName: s.product.name,
                variantName: s.variant.name,
                labelCount: s.quantity,
                printedAt: DateTime.now(),
                imageUrl: s.product.imageUrl,
              );
              emit(PrintWorkflowSuccess(printJob: job));
          }
      }
    }
  }
}
