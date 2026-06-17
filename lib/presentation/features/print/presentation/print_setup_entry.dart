import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/print/presentation/desktop/desktop_print_setup_screen.dart';
import 'package:stickify/presentation/features/print/presentation/mobile/mobile_print_setup_screen.dart';
import 'package:stickify/presentation/features/print/presentation/shared/print_setup_widgets.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Screen for configuring and executing a label print job.
///
/// Wraps [PrintWorkflowCubit] and allows users to set print quantity, select destination printer,
/// and toggle disabled slots on the sticker sheet.
class PrintSetupPage extends StatelessWidget {
  /// Creates a [PrintSetupPage] instance.
  const PrintSetupPage({
    required this.productId,
    required this.variantSku,
    required this.templateId,
    this.quantity,
    super.key,
  });

  /// The active product ID.
  final String productId;

  /// The active variant SKU.
  final String variantSku;

  /// The active label template ID.
  final String templateId;

  /// Optional initial quantity to pre-fill.
  final int? quantity;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrintWorkflowCubit(
        productRepository: context.read<ProductRepository>(),
        templateRepository: context.read<TemplateRepository>(),
        printJobRepository: context.read<PrintJobRepository>(),
        printService: context.read<PrintService>(),
        printerDiscoveryService: context.read<PrinterDiscoveryService>(),
        printJobIdGenerator: context.read<PrintJobIdGenerator>(),
      )..loadWorkflow(productId, variantSku, templateId, quantity),
      child: const _PrintSetupView(),
    );
  }
}

class _PrintSetupView extends StatelessWidget {
  const _PrintSetupView();

  int _calculateTotalSheets(int qty, int slotsPerSheet, Set<int> disabledSlots) {
    if (qty <= 0) return 0;
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
    return (currentSlot / slotsPerSheet).floor() + 1;
  }

  Set<int> _getActivePositions(int qty, Set<int> disabledSlots) {
    final active = <int>{};
    var activePlaced = 0;
    var currentSlot = 0;
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
          context.read<NotificationService>().showSuccess(
            'Print job ${state.printJob.id} successfully dispatched to printer!',
          );
          const DashboardRoute().go(context);
        }
        if (state is PrintWorkflowError) {
          BlockingErrorDialog.show(
            context,
            message: state.message,
            onClose: () => Navigator.of(context).pop(),
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
            body: ErrorView(
              message: state.message,
              onBack: () => Navigator.of(context).pop(),
            ),
          );
        }

        if (state is PrintWorkflowLoaded || state is PrintWorkflowSubmitting) {
          final loadedState = state is PrintWorkflowLoaded
              ? state
              : (state as PrintWorkflowSubmitting).loadedState;

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

          final parametersPanel = ParametersPanel(
            loadedState: loadedState,
            totalSheets: totalSheets,
            template: template,
            sheetConfig: sheetConfig,
            state: state,
          );

          final sheetsPreview = SheetsPreview(
            loadedState: loadedState,
            totalSheets: totalSheets,
            slotsPerSheet: slotsPerSheet,
            activePositions: activePositions,
            sheetConfig: sheetConfig,
            sticker: sticker,
            template: template,
            product: product,
            variant: variant,
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
                      // Adaptive Layout Switcher using AppEnvironment
                      _AdaptivePrintSetupLayout(
                        parametersPanel: parametersPanel,
                        sheetsPreview: sheetsPreview,
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

class _AdaptivePrintSetupLayout extends StatelessWidget {
  const _AdaptivePrintSetupLayout({
    required this.parametersPanel,
    required this.sheetsPreview,
  });

  final Widget parametersPanel;
  final Widget sheetsPreview;

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();

    switch (env.experience) {
      case AppExperience.mobile:
        return MobilePrintSetupScreen(
          parametersPanel: parametersPanel,
          sheetsPreview: sheetsPreview,
        );
      case AppExperience.tablet:
      case AppExperience.desktop:
        return DesktopPrintSetupScreen(
          parametersPanel: parametersPanel,
          sheetsPreview: sheetsPreview,
        );
    }
  }
}
