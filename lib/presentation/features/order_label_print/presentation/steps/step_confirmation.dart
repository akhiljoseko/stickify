import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';

/// Step 3: Confirmation / Review List View
class StepConfirmationView extends StatelessWidget {
  /// Creates a [StepConfirmationView].
  const StepConfirmationView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        final template = state.selectedTemplate;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step 3: Review & Confirm Order Batch',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Verify all items and quantities in your print order. You can edit quantities or remove items before proceeding to layout preview.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Summary Header Card
                  Card(
                    color: colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Template: ${template?.name ?? "None"}',
                                style: textTheme.titleMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${state.items.length} Product Variant(s) in Order',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${state.totalQuantity} Total Labels',
                                style: textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${state.totalSheets} Sheet(s) Required',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Items List Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Items (${state.items.length})',
                            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                          if (state.items.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No items in order batch.'),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.items.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = state.items[index];

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: colorScheme.secondaryContainer,
                                        child: Text('${index + 1}', style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.variant.name,
                                              style: textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Quantity: ${item.variant.quantity} ${item.variant.unit} | MRP: ₹${item.variant.mrp}',
                                              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      SizedBox(
                                        width: 120,
                                        child: _ItemQuantityField(
                                          initialQuantity: item.quantity,
                                          onChanged: (newQty) {
                                            context.read<OrderLabelPrintCubit>().updateItemQuantity(index, newQty);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () {
                                          context.read<OrderLabelPrintCubit>().removeItem(index);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          context.read<OrderLabelPrintCubit>().goToPreviousStep();
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Variant Selection'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        ),
                        onPressed: state.items.isEmpty
                            ? null
                            : () {
                                context.read<OrderLabelPrintCubit>().goToNextStep();
                              },
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Proceed to Print Preview', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
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

class _ItemQuantityField extends StatefulWidget {
  const _ItemQuantityField({
    required this.initialQuantity,
    required this.onChanged,
  });

  final int initialQuantity;
  final ValueChanged<int> onChanged;

  @override
  State<_ItemQuantityField> createState() => _ItemQuantityFieldState();
}

class _ItemQuantityFieldState extends State<_ItemQuantityField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuantity.toString());
  }

  @override
  void didUpdateWidget(_ItemQuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuantity != widget.initialQuantity && _controller.text != widget.initialQuantity.toString()) {
      _controller.text = widget.initialQuantity.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: const InputDecoration(
        labelText: 'Qty',
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (val) {
        final parsed = int.tryParse(val) ?? 0;
        widget.onChanged(parsed);
      },
    );
  }
}
