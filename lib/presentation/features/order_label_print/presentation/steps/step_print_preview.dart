import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/print/presentation/shared/print_setup_widgets.dart';
import 'package:stickify/presentation/features/print/presentation/shared/printer_loading_dialog.dart';

/// Step 3: Final Print Preview & Execution View
class StepPrintPreviewView extends StatelessWidget {
  /// Creates a [StepPrintPreviewView].
  const StepPrintPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final locator = context.read<AppServiceLocator>();
    final orderState = context.watch<OrderLabelPrintCubit>().state;

    return BlocProvider<PrintWorkflowCubit>(
      create: (context) => PrintWorkflowCubit(
        productRepository: locator.productRepository,
        templateRepository: locator.templateRepository,
        printService: locator.printService,
        printerDiscoveryService: locator.printerDiscoveryService,
        localDatabase: locator.database,
        printJobRepository: locator.printJobRepository,
        variantPrintStatsRepository: locator.variantPrintStatsRepository,
        printJobIdGenerator: locator.printJobIdGenerator,
        printerProfileRepository: locator.printerProfileRepository,
        calibrationResolver: locator.printerCalibrationCoordinateResolver,
        compatibilityAnalyzer: locator.templatePrinterCompatibilityAnalyzer,
        printPipelineOrchestrator: locator.printPipelineOrchestrator,
      )..initForBatch(
          items: orderState.items,
          template: orderState.selectedTemplate!,
          selectedPrinter: orderState.selectedPrinter,
        ),
      child: const _StepPrintPreviewContent(),
    );
  }
}

class _StepPrintPreviewContent extends StatefulWidget {
  const _StepPrintPreviewContent();

  @override
  State<_StepPrintPreviewContent> createState() => _StepPrintPreviewContentState();
}

class _StepPrintPreviewContentState extends State<_StepPrintPreviewContent> {
  bool _isDialogOpen = false;

  Set<int> _getActivePositions({
    required int qty,
    required int slotsPerSheet,
    required Set<int> disabledSlots,
    required bool printFromBottom,
  }) {
    if (qty <= 0 || slotsPerSheet <= 0) return {};

    var activePlaced = 0;
    var currentSlot = 0;
    while (activePlaced < qty) {
      if (!disabledSlots.contains(currentSlot)) {
        activePlaced++;
      }
      if (activePlaced < qty) {
        currentSlot++;
      }
    }
    final totalSheets = (currentSlot / slotsPerSheet).floor() + 1;

    final active = <int>{};
    var remainingQty = qty;

    for (var sheetIndex = 0; sheetIndex < totalSheets; sheetIndex++) {
      final sheetStart = sheetIndex * slotsPerSheet;
      final sheetEnd = (sheetIndex + 1) * slotsPerSheet;

      var availableOnSheet = 0;
      for (var slot = sheetStart; slot < sheetEnd; slot++) {
        if (!disabledSlots.contains(slot)) {
          availableOnSheet++;
        }
      }

      if (availableOnSheet == 0) {
        continue;
      }

      final toPlace = min(remainingQty, availableOnSheet);
      final isLastSheet = sheetIndex == totalSheets - 1;

      if (isLastSheet && printFromBottom) {
        var placed = 0;
        for (var slot = sheetEnd - 1; slot >= sheetStart; slot--) {
          if (!disabledSlots.contains(slot)) {
            active.add(slot);
            placed++;
            if (placed == toPlace) break;
          }
        }
      } else {
        var placed = 0;
        for (var slot = sheetStart; slot < sheetEnd; slot++) {
          if (!disabledSlots.contains(slot)) {
            active.add(slot);
            placed++;
            if (placed == toPlace) break;
          }
        }
      }

      remainingQty -= toPlace;
      if (remainingQty <= 0) break;
    }

    return active;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocConsumer<PrintWorkflowCubit, PrintWorkflowState>(
      listener: (context, state) {
        if (state is PrintWorkflowSubmitting) {
          if (!_isDialogOpen) {
            _isDialogOpen = true;
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => const PrinterLoadingDialog(),
            ).then((_) {
              _isDialogOpen = false;
            });
          }
        } else {
          if (_isDialogOpen) {
            Navigator.of(context).pop();
            _isDialogOpen = false;
          }
        }

        if (state is PrintWorkflowSuccess) {
          const message = 'Successfully sent order batch to printer!';
          try {
            context.read<NotificationService>().showSuccess(message);
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          }
          context.go('/dashboard');
        } else if (state is PrintWorkflowError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PrintWorkflowLoading || state is PrintWorkflowInitial) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final loadedState = switch (state) {
          PrintWorkflowLoaded s => s,
          PrintWorkflowSubmitting s => s.loadedState,
          _ => null,
        };

        if (loadedState == null || loadedState.selectedTemplate == null) {
          return const Center(child: Text('Invalid print preview configuration.'));
        }

        final cubit = context.read<PrintWorkflowCubit>();
        final template = loadedState.selectedTemplate!;

        final sheetConfig = template.sheetConfig ??
            const SheetConfig(
              pageWidth: 210,
              pageHeight: 297,
              columns: 2,
              rows: 5,
              columnGap: 5,
              rowGap: 5,
              marginTop: 10,
              marginBottom: 10,
              marginLeft: 10,
              marginRight: 10,
            );
        final sticker = template.stickerConfig ??
            const StickerConfig(
              widthMm: 100,
              heightMm: 60,
              cornerRadiusMm: 4,
              printableArea: [],
            );
        final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;

        var currentSlot = 0;
        var printedCount = 0;
        final totalQuantity = loadedState.totalQuantity;

        while (printedCount < totalQuantity) {
          if (!loadedState.disabledSlots.contains(currentSlot)) {
            printedCount++;
          }
          currentSlot++;
        }
        final totalSheets = (currentSlot / slotsPerSheet).ceil();

        final activePositions = _getActivePositions(
          qty: totalQuantity,
          slotsPerSheet: slotsPerSheet,
          disabledSlots: loadedState.disabledSlots,
          printFromBottom: loadedState.printFromBottom,
        );

        final parametersPanel = ParametersPanel(
          loadedState: loadedState,
          totalSheets: totalSheets,
          template: template,
          sheetConfig: sheetConfig,
          state: state,
          showQuantityField: false,
          showTemplateSelector: true,
          isSubmitting: state is PrintWorkflowSubmitting,
          onPrinterChanged: cubit.updatePrinter,
          onManufacturingDateChanged: cubit.updateManufacturingDate,
          onTemplateChanged: cubit.selectTemplate,
          onPrint: cubit.startPrintJob,
        );

        final sheetsPreview = SheetsPreview(
          loadedState: loadedState,
          totalSheets: totalSheets,
          slotsPerSheet: slotsPerSheet,
          activePositions: activePositions,
          sheetConfig: sheetConfig,
          sticker: sticker,
          template: template,
          items: loadedState.printableItems,
          onToggleSlot: cubit.toggleSlot,
          onToggleRowSlots: (sheetIndex, rowIndex, select) => cubit.toggleRowSlots(sheetIndex, rowIndex, select: select),
          onToggleAllFirstSheet: (select) => select ? cubit.selectAllFirstSheet() : cubit.deselectAllFirstSheet(),
          onTogglePrintFromBottom: (val) => cubit.togglePrintFromBottom(value: val),
          onToggleReverseSheetOrder: (val) => cubit.toggleReverseSheetOrder(value: val),
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Step 3: Print Preview & Dispatch',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch printing ${loadedState.printableItems.length} variant(s) across $totalQuantity total labels on "${template.name}".',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.read<OrderLabelPrintCubit>().goToPreviousStep(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Variants & Qty'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 360,
                          child: parametersPanel,
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: sheetsPreview,
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      parametersPanel,
                      const SizedBox(height: 24),
                      sheetsPreview,
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
