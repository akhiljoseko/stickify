import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/template_editor/core/element_renderer_registry.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class PrintSetupPage extends StatelessWidget {
  const PrintSetupPage({
    required this.productId,
    required this.variantSku,
    required this.templateId,
    super.key,
  });

  final String productId;
  final String variantSku;
  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrintWorkflowCubit(
        productRepository: context.read<ProductRepository>(),
        templateRepository: context.read<TemplateRepository>(),
        printJobRepository: context.read<PrintJobRepository>(),
      )..loadWorkflow(productId, variantSku, templateId),
      child: const _PrintSetupView(),
    );
  }
}

class _PrintSetupView extends StatelessWidget {
  const _PrintSetupView();

  // Dynamic layout reflowing helper
  int _calculateTotalSheets(int qty, int slotsPerSheet, Set<int> disabledSlots) {
    if (qty <= 0) return 0;
    int activePlaced = 0;
    int currentSlot = 0;
    while (activePlaced < qty) {
      if (!disabledSlots.contains(currentSlot)) {
        activePlaced++;
      }
      if (activePlaced < qty) {
        currentSlot++;
      }
    }
    return (currentSlot / slotsPerSheet).floor() + 1;
  }

  // Helper to resolve positions of active labels
  Set<int> _getActivePositions(int qty, Set<int> disabledSlots) {
    final active = <int>{};
    int activePlaced = 0;
    int currentSlot = 0;
    while (activePlaced < qty) {
      if (!disabledSlots.contains(currentSlot)) {
        active.add(currentSlot);
        activePlaced++;
      }
      currentSlot++;
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
        if (state is PrintWorkflowSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Print job ${state.printJob.id} successfully dispatched to printer!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
            ),
          );
          // Return to dashboard
          const DashboardRoute().go(context);
        }
        if (state is PrintWorkflowError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is PrintWorkflowInitial || state is PrintWorkflowLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is PrintWorkflowError && state is! PrintWorkflowLoaded) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: textTheme.titleMedium),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is PrintWorkflowLoaded || state is PrintWorkflowSubmitting) {
          final loadedState = state is PrintWorkflowLoaded
              ? state
              : (context.read<PrintWorkflowCubit>().state as PrintWorkflowLoaded);

          final product = loadedState.product;
          final variant = loadedState.variant;
          final template = loadedState.selectedTemplate!;
          final sheetConfig = template.sheetConfig ??
              const SheetConfig(
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
              );
          final sticker = template.stickerConfig ??
              const StickerConfig(
                widthMm: 100,
                heightMm: 60,
                cornerRadiusMm: 4,
                printableArea: [],
              );

          final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
          final totalSheets = _calculateTotalSheets(
            loadedState.quantity,
            slotsPerSheet,
            loadedState.disabledSlots,
          );
          final activePositions = _getActivePositions(
            loadedState.quantity,
            loadedState.disabledSlots,
          );

          // Left panel contents (Parameters)
          final parametersPanel = Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Print Parameters', style: textTheme.titleSmall?.copyWith(color: colorScheme.primary)),
                  const SizedBox(height: 20),
                  // Quantity
                  TextFormField(
                    initialValue: loadedState.quantity.toString(),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quantity to Print',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 0;
                      context.read<PrintWorkflowCubit>().updateQuantity(parsed);
                    },
                  ),
                  const SizedBox(height: 20),
                   // Printer Selection
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: loadedState.selectedPrinter,
                    decoration: const InputDecoration(
                      labelText: 'Printer Selection',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Zebra ZT411-A (Default)', child: Text('Zebra ZT411-A (Default)')),
                      DropdownMenuItem(value: 'Brother QL-820NWB', child: Text('Brother QL-820NWB')),
                      DropdownMenuItem(value: 'Industrial Master B3', child: Text('Industrial Master B3')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        context.read<PrintWorkflowCubit>().updatePrinter(val);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  // Stock Metadata
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Label Stock', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            template.name,
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Orientation', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                      Text(
                        sheetConfig.pageWidth > sheetConfig.pageHeight ? 'Landscape' : 'Portrait',
                        style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Labels',
                              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                            ),
                            Text(
                              loadedState.quantity.toString(),
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sheets Required',
                              style: textTheme.bodyLarge?.copyWith(color: colorScheme.onPrimaryContainer),
                            ),
                            Text(
                              totalSheets.toString(),
                              style: textTheme.headlineMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Print button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: state is PrintWorkflowSubmitting
                          ? null
                          : () => context.read<PrintWorkflowCubit>().startPrintJob(),
                      icon: state is PrintWorkflowSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.print),
                      label: Text(
                        state is PrintWorkflowSubmitting ? 'Sending to Printer...' : 'Start Print Job',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );

          // Right panel contents (Sheet layout preview)
          final sheetsPreview = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sheet Layout Preview', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  // Legend
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          border: Border.all(color: colorScheme.primary),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('Active', style: textTheme.bodySmall),
                      const SizedBox(width: 16),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerLow,
                          border: Border.all(color: colorScheme.outlineVariant),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Icon(Icons.close, size: 8, color: Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      Text('Used/Skipped', style: textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Sheets scrollable container
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalSheets,
                separatorBuilder: (_, __) => const SizedBox(height: 24),
                itemBuilder: (context, sheetIndex) {
                  final disabledOnSheet = loadedState.disabledSlots
                      .where((s) => s >= sheetIndex * slotsPerSheet && s < (sheetIndex + 1) * slotsPerSheet)
                      .length;
                  final activeOnSheet = activePositions
                      .where((s) => s >= sheetIndex * slotsPerSheet && s < (sheetIndex + 1) * slotsPerSheet)
                      .length;

                  final sheetTitle = 'Sheet ${sheetIndex + 1}';
                  final statusLabel = disabledOnSheet > 0
                      ? '$activeOnSheet Active, $disabledOnSheet Skipped'
                      : '$activeOnSheet Labels';

                  return Card(
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(sheetTitle.toUpperCase(), style: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: disabledOnSheet > 0
                                      ? colorScheme.errorContainer.withOpacity(0.3)
                                      : colorScheme.tertiaryContainer.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: textTheme.labelSmall?.copyWith(
                                    color: disabledOnSheet > 0 ? colorScheme.error : colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // The Sheet Surface Container
                          Center(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: colorScheme.outlineVariant, width: 2),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  )
                                ],
                              ),
                              child: AspectRatio(
                                aspectRatio: sheetConfig.pageWidth / sheetConfig.pageHeight,
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final paddingLeft = (sheetConfig.marginLeft / sheetConfig.pageWidth) * constraints.maxWidth;
                                    final paddingRight = (sheetConfig.marginRight / sheetConfig.pageWidth) * constraints.maxWidth;
                                    final paddingTop = (sheetConfig.marginTop / sheetConfig.pageHeight) * constraints.maxHeight;
                                    final paddingBottom = (sheetConfig.marginBottom / sheetConfig.pageHeight) * constraints.maxHeight;

                                    return Padding(
                                      padding: EdgeInsets.fromLTRB(paddingLeft, paddingTop, paddingRight, paddingBottom),
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: sheetConfig.columns,
                                          crossAxisSpacing: (sheetConfig.columnGap / sheetConfig.pageWidth) * constraints.maxWidth,
                                          mainAxisSpacing: (sheetConfig.rowGap / sheetConfig.pageHeight) * constraints.maxHeight,
                                          childAspectRatio: sticker.widthMm / sticker.heightMm,
                                        ),
                                        itemCount: slotsPerSheet,
                                        itemBuilder: (context, slotGridIndex) {
                                          final absIndex = sheetIndex * slotsPerSheet + slotGridIndex;
                                          final isDisabled = loadedState.disabledSlots.contains(absIndex);
                                          final isActive = activePositions.contains(absIndex);

                                          if (isDisabled) {
                                            return InkWell(
                                              onTap: () => context.read<PrintWorkflowCubit>().toggleSlot(absIndex),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: colorScheme.surfaceContainerLow,
                                                  border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Center(
                                                  child: Icon(Icons.close, color: Colors.grey),
                                                ),
                                              ),
                                            );
                                          }

                                          if (isActive) {
                                            return InkWell(
                                              onTap: () => context.read<PrintWorkflowCubit>().toggleSlot(absIndex),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: colorScheme.primary, width: 1.5),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(3),
                                                  child: FittedBox(
                                                    fit: BoxFit.contain,
                                                    child: SizedBox(
                                                      width: sticker.widthMm * 4,
                                                      height: sticker.heightMm * 4,
                                                      child: Stack(
                                                        children: template.elements.map((bp) {
                                                          final width = bp.width;
                                                          final height = bp.height;
                                                          final left = bp.x;
                                                          final top = bp.y;
                                                          final renderedChild = ElementRendererRegistry.forBlueprint(bp)
                                                              .render(context, bp, product: product, variant: variant);

                                                          return Positioned(
                                                            left: left,
                                                            top: top,
                                                            width: width,
                                                            height: height,
                                                            child: Transform.rotate(
                                                              angle: bp.rotation * (3.141592653589793 / 180),
                                                              child: SizedBox(
                                                                width: width,
                                                                height: height,
                                                                child: renderedChild,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }

                                          // Unused/Empty slot at the end
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(color: colorScheme.outlineVariant, style: BorderStyle.solid),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.radio_button_unchecked, color: Colors.grey, size: 16),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              // Help Box
              Card(
                color: colorScheme.surfaceContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'If you\'re using a label sheet that has already been partially printed, click on individual slots to mark them as "Used". LabelFlow will automatically adjust the printing sequence and calculate the required sheets.',
                          style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );

          return Scaffold(
            appBar: AppBar(
              title: const Text('Print Configuration'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            body: AdaptiveScrollWrapper(
              builder: (context, controller) {
                return SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        color: colorScheme.surfaceContainerLowest,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(product.name, style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Variant: ${variant.name} | SKU: ${variant.sku} | Template: ${template.name}',
                                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.description, size: 16, color: colorScheme.primary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Template Loaded',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Responsive Columns Layout
                      AdaptiveLayoutSwitcher(
                        mobile: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            parametersPanel,
                            const SizedBox(height: 24),
                            sheetsPreview,
                          ],
                        ),
                        desktop: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 4, child: parametersPanel),
                            const SizedBox(width: 24),
                            Expanded(flex: 8, child: sheetsPreview),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
