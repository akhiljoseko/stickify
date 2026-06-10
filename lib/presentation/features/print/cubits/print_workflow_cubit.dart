import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';

class PrintWorkflowCubit extends Cubit<PrintWorkflowState> {
  PrintWorkflowCubit({
    required ProductRepository productRepository,
    required TemplateRepository templateRepository,
    required PrintJobRepository printJobRepository,
    required PrintService printService,
  })  : _productRepo = productRepository,
        _templateRepo = templateRepository,
        _printJobRepo = printJobRepository,
        _printService = printService,
        super(const PrintWorkflowInitial());

  final ProductRepository _productRepo;
  final TemplateRepository _templateRepo;
  final PrintJobRepository _printJobRepo;
  final PrintService _printService;

  Future<void> loadWorkflow(String productId, String variantSku, [String? templateId]) async {
    emit(const PrintWorkflowLoading());
    try {
      final product = await _productRepo.getProductById(productId);
      if (product == null) {
        emit(const PrintWorkflowError(message: 'Product not found.'));
        return;
      }

      final variant = product.variants.firstWhere(
        (v) => v.sku == variantSku,
        orElse: () => throw Exception('Variant SKU $variantSku not found in product $productId.'),
      );

      final templates = await _templateRepo.fetchTemplates();

      LabelTemplate? selected;
      if (templateId != null && templateId.isNotEmpty) {
        selected = templates.firstWhere(
          (t) => t.id == templateId,
          orElse: () => templates.isNotEmpty ? templates.first : throw Exception('Template not found.'),
        );
      } else if (templates.isNotEmpty) {
        selected = templates.first;
      }

      emit(PrintWorkflowLoaded(
        product: product,
        variant: variant,
        templates: templates,
        selectedTemplate: selected,
      ));
    } on Object catch (e) {
      emit(PrintWorkflowError(message: e.toString()));
    }
  }

  void selectTemplate(LabelTemplate template) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(
        selectedTemplate: () => template,
        disabledSlots: {}, // reset skipped slots when template changes
      ));
    }
  }

  void updateQuantity(int qty) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(quantity: qty));
    }
  }

  void updatePrinter(String printer) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(selectedPrinter: printer));
    }
  }

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

  Future<void> startPrintJob() async {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final template = s.selectedTemplate;
      if (template == null) {
        emit(const PrintWorkflowError(message: 'No label template selected.'));
        return;
      }

      emit(const PrintWorkflowSubmitting());
      try {
        await _printService.printLabels(
          product: s.product,
          variant: s.variant,
          template: template,
          quantity: s.quantity,
          disabledSlots: s.disabledSlots,
          printerName: s.selectedPrinter,
        );

        final jobId = 'job-${DateTime.now().millisecondsSinceEpoch}';
        final job = PrintJob(
          id: jobId,
          productName: '${s.product.name} - ${s.variant.name}',
          sku: s.variant.sku,
          status: PrintJobStatus.completed, // complete immediately in mock
          printerStation: s.selectedPrinter.split(' ').first, // station name prefix
          printedAt: DateTime.now(),
          labelCount: s.quantity,
          isVerified: false,
        );

        await _printJobRepo.savePrintJob(job);
        emit(PrintWorkflowSuccess(printJob: job));
      } on Object catch (e) {
        emit(PrintWorkflowError(message: e.toString()));
      }
    }
  }
}
