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
    required this.productRepository,
    required this.templateRepository,
    required this.printJobRepository,
    required this.printService,
  }) : super(const PrintWorkflowInitial());

  /// Repository providing product catalog records.
  final ProductRepository productRepository;

  /// Repository providing label templates.
  final TemplateRepository templateRepository;

  /// Repository tracking and saving print logs.
  final PrintJobRepository printJobRepository;

  /// Service dispatching compiled labels to physical printer hardware.
  final PrintService printService;

  /// Loads the initial metadata needed to configure the print job.
  ///
  /// Fetches [productId], locates the variant by [variantSku], and optionally
  /// sets the initial active layout template by [templateId].
  Future<void> loadWorkflow(String productId, String variantSku, [String? templateId]) async {
    emit(const PrintWorkflowLoading());
    try {
      final productResult = await productRepository.getProductById(productId);
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

          final templatesResult = await templateRepository.fetchTemplates();
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

              final printers = await printService.getAvailablePrinters();
              final defaultPrinter = printers.firstWhere(
                (p) => p.isDefault,
                orElse: () => printers.isNotEmpty ? printers.first : const PrinterDevice(name: 'No Printer Found', url: ''),
              );

              emit(PrintWorkflowLoaded(
                product: product,
                variant: variant,
                templates: templates,
                selectedTemplate: selected,
                availablePrinters: printers,
                selectedPrinter: defaultPrinter,
              ));
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
      emit(s.copyWith(
        selectedTemplate: () => template,
        disabledSlots: {}, // reset skipped slots when template changes
      ));
    }
  }

  /// Updates the target label print quantity.
  void updateQuantity(int qty) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(quantity: qty));
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
      final printResult = await printService.printLabels(
        product: s.product,
        variant: s.variant,
        template: template,
        quantity: s.quantity,
        disabledSlots: s.disabledSlots,
        printer: printer,
      );

      switch (printResult) {
        case Failure(error: final err):
          emit(PrintWorkflowError(message: err.message));
        case Success():
          final jobId = 'job-${DateTime.now().millisecondsSinceEpoch}';
          final job = PrintJob(
            id: jobId,
            productName: '${s.product.name} - ${s.variant.name}',
            sku: s.variant.sku,
            status: PrintJobStatus.completed,
            printerStation: printer.name,
            printedAt: DateTime.now(),
            labelCount: s.quantity,
          );

          final saveResult = await printJobRepository.savePrintJob(job);
          switch (saveResult) {
            case Failure(error: final saveErr):
              emit(PrintWorkflowError(message: saveErr.message));
            case Success():
              emit(PrintWorkflowSuccess(printJob: job));
          }
      }
    }
  }
}
