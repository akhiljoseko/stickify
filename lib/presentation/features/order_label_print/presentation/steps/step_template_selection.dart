import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';
import 'package:stickify/presentation/widgets/widgets.dart';

/// Step 1: Template Selection View
class StepTemplateSelectionView extends StatelessWidget {
  /// Creates a [StepTemplateSelectionView].
  const StepTemplateSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final selectedTemplate = state.selectedTemplate;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 1: Select Label Template',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the physical sheet layout template that will be used for all product labels in this order.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TemplateSelectorField(
                            templates: state.templates,
                            selectedTemplateId: selectedTemplate?.id,
                            labelText: 'Order Label Template',
                            onChanged: (id) {
                              if (id != null) {
                                final template = state.templates.firstWhere((t) => t.id == id);
                                context.read<OrderLabelPrintCubit>().selectTemplate(template);
                              }
                            },
                          ),
                          if (selectedTemplate != null) ...[
                            const SizedBox(height: 20),
                            const Divider(),
                            const SizedBox(height: 16),
                            Text(
                              'Template Details',
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            if (selectedTemplate.sheetConfig != null) ...[
                              _SpecRow(
                                label: 'Page Format',
                                value: '${selectedTemplate.sheetConfig!.pageWidth.toInt()} x ${selectedTemplate.sheetConfig!.pageHeight.toInt()} mm',
                              ),
                              const SizedBox(height: 8),
                              _SpecRow(
                                label: 'Grid Layout',
                                value: '${selectedTemplate.sheetConfig!.columns} columns x ${selectedTemplate.sheetConfig!.rows} rows (${selectedTemplate.sheetConfig!.columns * selectedTemplate.sheetConfig!.rows} slots per sheet)',
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (selectedTemplate.stickerConfig != null) ...[
                              _SpecRow(
                                label: 'Sticker Size',
                                value: '${selectedTemplate.stickerConfig!.widthMm.toInt()} x ${selectedTemplate.stickerConfig!.heightMm.toInt()} mm',
                              ),
                              const SizedBox(height: 8),
                            ],
                            _SpecRow(
                              label: 'Design Elements',
                              value: '${selectedTemplate.elements.length} layout elements',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                      ),
                      onPressed: selectedTemplate == null
                          ? null
                          : () {
                              context.read<OrderLabelPrintCubit>().goToNextStep();
                            },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Continue to Product Selection', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        Text(value, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
