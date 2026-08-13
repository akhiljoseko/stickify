import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';
import 'package:stickify/presentation/features/order_label_print/presentation/widgets/variant_inline_quantity_tile.dart';
import 'package:stickify/presentation/features/product/presentation/shared/edit_variant_dialog.dart';

/// Step 2: Variant & Quantity Selection View (2-column layout on Desktop)
class StepVariantSelectionView extends StatelessWidget {
  /// Creates a [StepVariantSelectionView].
  const StepVariantSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (isMobile) {
          return const _MobileVariantSelectionLayout();
        }
        return const _DesktopVariantSelectionLayout();
      },
    );
  }
}

class _DesktopVariantSelectionLayout extends StatelessWidget {
  const _DesktopVariantSelectionLayout();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Product & Variant Browser
                Expanded(
                  flex: 5,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.search, color: colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Select Products & Variants',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const _ProductSearchBar(),
                          const SizedBox(height: 12),
                          const Expanded(child: _ProductBrowserList()),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right Panel: Running Order Batch
                Expanded(
                  flex: 4,
                  child: Card(
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RunningBatchHeader(),
                          const SizedBox(height: 12),
                          const Expanded(child: _RunningBatchList()),
                          const SizedBox(height: 16),
                          const _Step2ActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileVariantSelectionLayout extends StatelessWidget {
  const _MobileVariantSelectionLayout();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const _ProductSearchBar(),
          const SizedBox(height: 12),
          const Expanded(child: _ProductBrowserList()),
          const SizedBox(height: 12),
          const _RunningBatchHeader(),
          const SizedBox(height: 12),
          const _Step2ActionButtons(),
        ],
      ),
    );
  }
}

class _ProductSearchBar extends StatefulWidget {
  const _ProductSearchBar();

  @override
  State<_ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<_ProductSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OrderLabelPrintCubit>().state.searchQuery,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        hintText: 'Search products or SKUs...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  context.read<OrderLabelPrintCubit>().updateSearchQuery('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (val) {
        context.read<OrderLabelPrintCubit>().updateSearchQuery(val);
      },
    );
  }
}

class _ProductBrowserList extends StatelessWidget {
  const _ProductBrowserList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (state.filteredProducts.isEmpty) {
          return Center(
            child: Text(
              state.searchQuery.isEmpty
                  ? 'No products found'
                  : 'No matching products found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: state.filteredProducts.length,
          itemBuilder: (context, index) {
            final product = state.filteredProducts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ExpansionTile(
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${product.variants.length} variant(s) available',
                ),
                children: product.variants.map((variant) {
                  final existingItem = state.items.firstWhere(
                    (i) =>
                        i.product.id == product.id &&
                        i.variant.sku == variant.sku,
                    orElse: () => PrintableItem(
                      product: product,
                      variant: variant,
                      quantity: 0,
                    ),
                  );

                  return VariantInlineQuantityTile(
                    product: product,
                    variant: variant,
                    currentAddedQuantity: existingItem.quantity,
                    onAdd: (quantity) {
                      context.read<OrderLabelPrintCubit>().addOrUpdateItem(
                        product,
                        variant,
                        quantity,
                      );
                    },
                    onEdit: () {
                      _showEditVariantDialog(context, product, variant);
                    },
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditVariantDialog(
    BuildContext context,
    Product product,
    ProductVariant variant,
  ) {
    final cubit = context.read<OrderLabelPrintCubit>();
    final productRepository = context.read<ProductRepository>();

    EditVariantDialog.show(
      context,
      product: product,
      variant: variant,
      onSave: (updatedVariant) async {
        final updatedVariants = product.variants
            .map(
              (v) => v.sku == variant.sku ? updatedVariant : v,
            )
            .toList();
        final updatedProduct = product.copyWith(variants: updatedVariants);

        final result = await productRepository.saveProduct(updatedProduct);
        if (result is Success) {
          await cubit.refreshProductCatalog(
            updatedProduct,
            variant,
            updatedVariant,
          );
        }
      },
    );
  }
}

class _RunningBatchHeader extends StatelessWidget {
  const _RunningBatchHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Batch Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${state.items.length} variant(s) selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Text(
                '${state.totalQuantity} Labels',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RunningBatchList extends StatelessWidget {
  const _RunningBatchList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.post_add, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'No items added to batch yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse products on the left, enter label quantities, and click Add.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item.variant.name} (${item.variant.quantity} ${item.variant.unit}) | MRP: ₹${item.variant.mrp}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          onPressed: () {
                            context
                                .read<OrderLabelPrintCubit>()
                                .updateItemQuantity(index, item.quantity - 1);
                          },
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () {
                            context
                                .read<OrderLabelPrintCubit>()
                                .updateItemQuantity(index, item.quantity + 1);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            context.read<OrderLabelPrintCubit>().removeItem(
                              index,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Step2ActionButtons extends StatelessWidget {
  const _Step2ActionButtons();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderLabelPrintCubit>();

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        return Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => cubit.goToPreviousStep(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: state.items.isEmpty
                    ? null
                    : () => cubit.goToNextStep(),
                label: const Text(
                  'Proceed to Print',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
