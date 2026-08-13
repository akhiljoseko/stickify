import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/print/presentation/shared/print_setup_widgets.dart';

/// Step 4: Final Print Preview & Execution View
class StepPrintPreviewView extends StatelessWidget {
  /// Creates a [StepPrintPreviewView].
  const StepPrintPreviewView({super.key});

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

    return BlocConsumer<OrderLabelPrintCubit, OrderLabelPrintState>(
      listener: (context, state) {
        if (state.isPrintSuccess) {
          final message = state.successMessage ?? 'Order label batch sent to printer successfully!';
          try {
            context.read<NotificationService>().showSuccess(message);
          } catch (_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.green,
              ),
            );
          }
          context.go('/dashboard');
        } else if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final cubit = context.read<OrderLabelPrintCubit>();
        final template = state.selectedTemplate!;
        final firstItem = state.items.first;

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
        final totalSheets = state.totalSheets;
        final activePositions = _getActivePositions(
          qty: state.totalQuantity,
          slotsPerSheet: slotsPerSheet,
          disabledSlots: state.disabledSlots,
          printFromBottom: state.printFromBottom,
        );

        final loadedStateStub = PrintWorkflowLoaded(
          product: firstItem.product,
          variant: firstItem.variant,
          templates: state.templates,
          selectedTemplate: template,
          quantity: state.totalQuantity,
          availablePrinters: state.availablePrinters,
          selectedPrinter: state.selectedPrinter,
          disabledSlots: state.disabledSlots,
          printFromBottom: state.printFromBottom,
          manufacturingDate: state.manufacturingDate,
          selectedPrinterProfile: state.selectedPrinterProfile,
          selectedTrayProfile: state.selectedTrayProfile,
          compatibilityResult: state.compatibilityResult,
        );

        final parametersPanel = ParametersPanel(
          loadedState: loadedStateStub,
          totalSheets: totalSheets,
          template: template,
          sheetConfig: sheetConfig,
          state: state.isSubmitting ? PrintWorkflowSubmitting(loadedState: loadedStateStub) : loadedStateStub,
          showQuantityField: false,
          showTemplateSelector: false,
          isSubmitting: state.isSubmitting,
          onPrinterChanged: cubit.updatePrinter,
          onManufacturingDateChanged: cubit.updateManufacturingDate,
          onPrint: cubit.printOrderLabels,
        );

        final sheetsPreview = SheetsPreview(
          loadedState: loadedStateStub,
          totalSheets: totalSheets,
          slotsPerSheet: slotsPerSheet,
          activePositions: activePositions,
          sheetConfig: sheetConfig,
          sticker: sticker,
          template: template,
          items: state.items,
          onToggleSlot: cubit.toggleSlot,
          onToggleRowSlots: (sheetIndex, rowIndex, select) => cubit.toggleRowSlots(sheetIndex, rowIndex, select: select),
          onToggleAllFirstSheet: (select) => select ? cubit.selectAllFirstSheet() : cubit.deselectAllFirstSheet(),
          onTogglePrintFromBottom: (val) => cubit.togglePrintFromBottom(value: val),
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
                        'Step 4: Print Preview & Dispatch',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch printing ${state.items.length} variant(s) across ${state.totalQuantity} total labels on "${template.name}".',
                        style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: () => cubit.goToPreviousStep(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Review'),
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
