import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';
import 'package:stickify/presentation/features/order_label_print/presentation/steps/step_print_preview.dart';
import 'package:stickify/presentation/features/order_label_print/presentation/steps/step_template_selection.dart';
import 'package:stickify/presentation/features/order_label_print/presentation/steps/step_variant_selection.dart';

/// Entry page for the Order Label Printing Wizard.
class OrderLabelPrintPage extends StatelessWidget {
  /// Creates an [OrderLabelPrintPage].
  const OrderLabelPrintPage({super.key});

  @override
  Widget build(BuildContext context) {
    final locator = context.read<AppServiceLocator>();
    return BlocProvider(
      create: (context) {
        return OrderLabelPrintCubit(
          templateRepository: locator.templateRepository,
          productRepository: locator.productRepository,
          printerDiscoveryService: locator.printerDiscoveryService,
        )..init();
      },
      child: const _OrderLabelPrintView(),
    );
  }
}

class _OrderLabelPrintView extends StatelessWidget {
  const _OrderLabelPrintView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Order Label Printing'),
            leading: FocusTraversalGroup(
              descendantsAreFocusable: false,
              child: IconButton(
                focusNode: FocusNode(canRequestFocus: false),
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/dashboard');
                  }
                },
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: FocusTraversalGroup(
                descendantsAreFocusable: false,
                child: Container(
                  color: colorScheme.surfaceContainerLow,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      _StepIndicatorPill(
                        stepNumber: 1,
                        label: 'Template',
                        isActive: state.step == OrderLabelPrintStep.templateSelection,
                        isCompleted: state.step.index > OrderLabelPrintStep.templateSelection.index,
                        onTap: () => context.read<OrderLabelPrintCubit>().setStep(OrderLabelPrintStep.templateSelection),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      _StepIndicatorPill(
                        stepNumber: 2,
                        label: 'Variants & Qty',
                        isActive: state.step == OrderLabelPrintStep.variantSelection,
                        isCompleted: state.step.index > OrderLabelPrintStep.variantSelection.index,
                        onTap: state.selectedTemplate != null
                            ? () => context.read<OrderLabelPrintCubit>().setStep(OrderLabelPrintStep.variantSelection)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                      const SizedBox(width: 8),
                      _StepIndicatorPill(
                        stepNumber: 3,
                        label: 'Print Preview',
                        isActive: state.step == OrderLabelPrintStep.printPreview,
                        isCompleted: false,
                        onTap: state.items.isNotEmpty
                            ? () => context.read<OrderLabelPrintCubit>().setStep(OrderLabelPrintStep.printPreview)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (state.step) {
              OrderLabelPrintStep.templateSelection => const StepTemplateSelectionView(),
              OrderLabelPrintStep.variantSelection => const StepVariantSelectionView(),
              OrderLabelPrintStep.printPreview => const StepPrintPreviewView(),
            },
          ),
        );
      },
    );
  }
}

class _StepIndicatorPill extends StatelessWidget {
  const _StepIndicatorPill({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.onTap,
  });

  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isCompleted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final Color bgColor;
    final Color fgColor;

    if (isActive) {
      bgColor = colorScheme.primary;
      fgColor = colorScheme.onPrimary;
    } else if (isCompleted) {
      bgColor = colorScheme.primaryContainer;
      fgColor = colorScheme.onPrimaryContainer;
    } else {
      bgColor = colorScheme.surfaceContainerHighest;
      fgColor = colorScheme.onSurfaceVariant;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: fgColor.withValues(alpha: 0.2),
              child: isCompleted
                  ? Icon(Icons.check, size: 12, color: fgColor)
                  : Text('$stepNumber', style: TextStyle(fontSize: 11, color: fgColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: fgColor,
                fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
