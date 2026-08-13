import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';

/// Cubit managing the multi-step printing workflow state.
///
/// Handles template selection, quantity updates, slot toggling (for reuse),
/// and print job submission for both single and batch printing modes.
class PrintWorkflowCubit extends Cubit<PrintWorkflowState> {
  /// Creates a [PrintWorkflowCubit] with the necessary repositories and services.
  PrintWorkflowCubit({
    required this._productRepository,
    required this._templateRepository,
    required this._printJobRepository,
    required this._variantPrintStatsRepository,
    required this._printService,
    required this._printerDiscoveryService,
    required this._printJobIdGenerator,
    required this._localDatabase,
    required this._printerProfileRepository,
    required this._calibrationResolver,
    required this._compatibilityAnalyzer,
    required this._printPipelineOrchestrator,
  })  : super(const PrintWorkflowInitial());

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

  /// Repository providing printer profiles.
  final PrinterProfileRepository _printerProfileRepository;

  /// Resolver for printer tray calibration rules.
  final PrinterCalibrationCoordinateResolver _calibrationResolver;

  /// Analyzer for printer capabilities and template compatibility.
  final TemplatePrinterCompatibilityAnalyzer _compatibilityAnalyzer;

  /// Orchestration service for composed calibration + optimization pipelines.
  final PrintPipelineOrchestrator _printPipelineOrchestrator;

  /// Loads the initial metadata needed to configure a single product print job.
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

              final profilesResult = await _printerProfileRepository.getAllProfiles();
              PrinterProfile? matchedProfile;
              PrinterTrayProfile? matchedTray;
              CompatibilityAnalysisResult? compatibilityResult;

              if (profilesResult is Success<List<PrinterProfile>, AppError>) {
                final profiles = profilesResult.value;
                matchedProfile = profiles.firstWhereOrNull(
                  (p) => p.printerIdentity.systemPrinterName == defaultPrinter.name,
                );

                if (matchedProfile != null && selected != null && selected.sheetConfig != null) {
                  matchedTray = matchedProfile.trays.firstWhereOrNull(
                    (t) => t.supportedPaperConfigurations.any((ref) => ref.id == selected!.id),
                  );

                  if (matchedTray != null) {
                    final calibrationResult = _calibrationResolver.resolve(
                      CalibrationRequest(
                        tray: matchedTray,
                        paperConfigId: selected.id,
                        sheetConfig: selected.sheetConfig!,
                      ),
                    );

                    final calibrationContext = switch (calibrationResult) {
                      Success(value: final context) => context,
                      Failure() => const PrintCoordinateContext.identity(),
                    };

                    compatibilityResult = _compatibilityAnalyzer.analyze(
                      template: selected,
                      printer: matchedProfile,
                      tray: matchedTray,
                      calibrationContext: calibrationContext,
                    );
                  }
                }
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
                reverseSheetOrder: matchedProfile?.capabilities.reverseSheetOrder ?? false,
                isQuantityManuallyEdited: initialQuantity != null && initialQuantity > 0,
                selectedPrinterProfile: matchedProfile,
                selectedTrayProfile: matchedTray,
                compatibilityResult: compatibilityResult,
              );
              emit(loaded);
          }
      }
    } on Object catch (e) {
      emit(PrintWorkflowError(message: e.toString()));
    }
  }

  /// Loads initial metadata and printer configuration for batch multi-product printing.
  Future<void> initForBatch({
    required List<PrintableItem> items,
    required LabelTemplate template,
    PrinterDevice? selectedPrinter,
  }) async {
    emit(const PrintWorkflowLoading());
    try {
      final templatesResult = await _templateRepository.fetchTemplates();
      List<LabelTemplate> templates = [];
      if (templatesResult is Success<List<LabelTemplate>, AppError>) {
        templates = templatesResult.value;
      }

      final printers = await _printerDiscoveryService.getAvailablePrinters();
      final targetPrinter = selectedPrinter ??
          printers.firstWhere(
            (p) => p.isDefault,
            orElse: () => printers.isNotEmpty ? printers.first : const PrinterDevice(name: 'No Printer Found', url: ''),
          );

      final cachedBottom = await _localDatabase.get<bool>('settings', 'print_from_bottom') ?? false;

      final profilesResult = await _printerProfileRepository.getAllProfiles();
      PrinterProfile? matchedProfile;
      PrinterTrayProfile? matchedTray;
      CompatibilityAnalysisResult? compatibilityResult;

      if (profilesResult is Success<List<PrinterProfile>, AppError>) {
        final profiles = profilesResult.value;
        matchedProfile = profiles.firstWhereOrNull(
          (p) => p.printerIdentity.systemPrinterName == targetPrinter.name,
        );

        if (matchedProfile != null && template.sheetConfig != null) {
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

      final loaded = PrintWorkflowLoaded(
        items: items,
        templates: templates.isNotEmpty ? templates : [template],
        selectedTemplate: template,
        availablePrinters: printers,
        selectedPrinter: targetPrinter,
        quantity: items.fold<int>(0, (sum, i) => sum + i.quantity),
        printFromBottom: cachedBottom,
        reverseSheetOrder: matchedProfile?.capabilities.reverseSheetOrder ?? false,
        selectedPrinterProfile: matchedProfile,
        selectedTrayProfile: matchedTray,
        compatibilityResult: compatibilityResult,
      );
      emit(loaded);
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

      PrinterTrayProfile? matchedTray;
      CompatibilityAnalysisResult? compatibilityResult;

      if (s.selectedPrinterProfile != null && template.sheetConfig != null) {
        matchedTray = s.selectedPrinterProfile!.trays.firstWhereOrNull(
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
            printer: s.selectedPrinterProfile!,
            tray: matchedTray,
            calibrationContext: calibrationContext,
          );
        }
      }

      emit(
        s.copyWith(
          selectedTemplate: () => template,
          quantity: qty,
          selectedTrayProfile: () => matchedTray,
          compatibilityResult: () => compatibilityResult,
        ),
      );
    }
  }

  /// Updates quantity to print.
  void updateQuantity(int newQuantity) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final validQuantity = newQuantity < 1 ? 1 : newQuantity;
      emit(
        s.copyWith(
          quantity: validQuantity,
          isQuantityManuallyEdited: true,
        ),
      );
    }
  }

  /// Updates active printer device and resolves capabilities and tray calibration context.
  Future<void> updatePrinter(PrinterDevice printer) async {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final profilesResult = await _printerProfileRepository.getAllProfiles();
      PrinterProfile? matchedProfile;
      PrinterTrayProfile? matchedTray;
      CompatibilityAnalysisResult? compatibilityResult;

      if (profilesResult is Success<List<PrinterProfile>, AppError>) {
        final profiles = profilesResult.value;
        matchedProfile = profiles.firstWhereOrNull(
          (p) => p.printerIdentity.systemPrinterName == printer.name,
        );

        final template = s.selectedTemplate;
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
        s.copyWith(
          selectedPrinter: () => printer,
          selectedPrinterProfile: () => matchedProfile,
          selectedTrayProfile: () => matchedTray,
          compatibilityResult: () => compatibilityResult,
          reverseSheetOrder: matchedProfile?.capabilities.reverseSheetOrder ?? s.reverseSheetOrder,
        ),
      );
    }
  }

  /// Toggles a specific slot index on the printing grid sheet.
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

  /// Toggles whether to reverse PDF sheet page compilation order.
  void toggleReverseSheetOrder({required bool value}) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(reverseSheetOrder: value));
    }
  }

  /// Updates the manufacturing date for token resolution.
  void updateManufacturingDate(DateTime date) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      emit(s.copyWith(manufacturingDate: date));
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

  /// Toggles an entire row of slots on a given sheet.
  void toggleRowSlots(int sheetIndex, int rowIndex, {required bool select}) {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final template = s.selectedTemplate;
      if (template?.sheetConfig == null) return;

      final columns = template!.sheetConfig!.columns;
      final slotsPerSheet = columns * template.sheetConfig!.rows;
      final rowSlots = List.generate(
        columns,
        (c) => sheetIndex * slotsPerSheet + rowIndex * columns + c,
      );

      final updated = Set<int>.from(s.disabledSlots);
      for (final slot in rowSlots) {
        if (select) {
          updated.remove(slot);
        } else {
          updated.add(slot);
        }
      }
      emit(s.copyWith(disabledSlots: updated));
    }
  }

  /// Compiles the PDF and sends the layout job to the print service.
  Future<void> startPrintJob() async {
    final s = state;
    if (s is PrintWorkflowLoaded) {
      final template = s.selectedTemplate;
      final printer = s.selectedPrinter;

      if (template == null || printer == null) {
        emit(const PrintWorkflowError(message: 'Invalid print configuration.'));
        return;
      }

      emit(PrintWorkflowSubmitting(loadedState: s));

      PrintExecutionConfiguration? executionConfiguration;
      if (s.selectedPrinterProfile != null && s.selectedTrayProfile != null) {
        final orchestratorResult = _printPipelineOrchestrator.resolve(
          template: template,
          printer: s.selectedPrinterProfile!,
          tray: s.selectedTrayProfile!,
          paperConfigurationId: template.id,
        );

        switch (orchestratorResult) {
          case Failure(error: final err):
            emit(PrintWorkflowError(message: err.message));
            return;
          case Success(value: final coordinateContext):
            executionConfiguration = PrintExecutionConfiguration(
              selectedTray: s.selectedTrayProfile,
              paperConfigurationId: template.id,
              coordinateContext: coordinateContext,
            );
        }
      }

      final itemsToPrint = s.printableItems;

      final printResult = await _printService.printLabels(
        items: itemsToPrint,
        template: template,
        disabledSlots: s.disabledSlots,
        printer: printer,
        printFromBottom: s.printFromBottom,
        reverseSheetOrder: s.reverseSheetOrder,
        executionConfiguration: executionConfiguration,
        manufacturingDate: s.manufacturingDate,
      );

      switch (printResult) {
        case Failure(error: final err):
          emit(PrintWorkflowError(message: err.message));
        case Success():
          final now = DateTime.now();
          PrintJob? lastJob;
          for (final item in itemsToPrint) {
            final jobId = _printJobIdGenerator.generateId();
            final job = PrintJob(
              id: jobId,
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
            lastJob = job;
          }

          emit(PrintWorkflowSuccess(printJob: lastJob!));
      }
    }
  }
}
