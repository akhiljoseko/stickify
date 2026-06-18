import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_form_view.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_shared_widgets.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Mobile-specific Product catalogue Screen.
/// Provides browsing product catalogue list/details, variant price editing, and full product creation/editing.
class MobileProductManagementScreen extends StatelessWidget {
  /// Creates a [MobileProductManagementScreen] instance.
  const MobileProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubitState = context.watch<ProductCubit>().state;
    final showFab = cubitState is ProductPageLoaded && cubitState.subView is ProductCatalogView;
    final formKey = GlobalKey<ProductFormViewState>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => context.read<ProductCubit>().setSubView(const ProductCreateView()),
              child: const Icon(Icons.add),
            )
          : null,
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductPageError) {
            context.read<NotificationService>().showError(state.message);
          }
        },
        builder: (context, state) {
          if (state is ProductPageLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductPageError && state.message.isNotEmpty) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().fetchPage(pageKey: 0, pageSize: 20),
              onBack: () => Navigator.of(context).pop(),
            );
          }

          if (state is ProductFormSubmitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving product...'),
                ],
              ),
            );
          }

          if (state is ProductPageLoaded) {
            switch (state.subView) {
              case ProductDetailView(:final product):
                return _MobileProductDetailView(
                  product: product,
                  onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                );
              case ProductCreateView():
                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    ),
                    title: const Text('Add Product'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Save Product',
                        onPressed: () => formKey.currentState?.saveForm(),
                      ),
                    ],
                  ),
                  body: ProductFormView(
                    key: formKey,
                    onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                  ),
                );
              case ProductEditView(:final product):
                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    ),
                    title: const Text('Edit Product'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Save Product',
                        onPressed: () => formKey.currentState?.saveForm(),
                      ),
                    ],
                  ),
                  body: ProductFormView(
                    key: formKey,
                    product: product,
                    onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                  ),
                );
              case ProductCatalogView():
                return _MobileCatalogListView(state: state);
            }
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _MobileCatalogListView extends StatelessWidget {
  const _MobileCatalogListView({required this.state});

  final ProductPageLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AdaptiveScrollWrapper(
      builder: (context, controller) => CustomScrollView(
        controller: controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Assets',
                      style: textTheme.displayLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse and manage your active product items.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => context.read<ProductCubit>().applyFilter(query: val),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: 'Search products...',
                            fillColor: colorScheme.containerLow,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: (state.categoryFilter == null || state.categoryFilter!.isEmpty) ? 'All' : state.categoryFilter!,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            fillColor: colorScheme.containerLow,
                          ),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                            ...ProductCategories.all.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                          ],
                          onChanged: (val) {
                            final categoryVal = (val == null || val == 'All') ? '' : val;
                            context.read<ProductCubit>().applyFilter(category: categoryVal);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _MobileProductGrid(products: state.items),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileProductGrid extends StatelessWidget {
  const _MobileProductGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (products.isEmpty) {
      return const EmptyCatalogState();
    }

    return Column(
      children: products.map((product) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: colorScheme.container,
                          image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                              ? DecorationImage(
                                  image: resolveImageProvider(product.imageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: product.imageUrl == null || product.imageUrl!.isEmpty
                            ? Icon(Icons.inventory_2_outlined, color: colorScheme.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: textTheme.titleSmall,
                            ),
                            if (product.category != null && product.category!.isNotEmpty)
                              Text(
                                product.category!,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              product.sku,
                              style: textTheme.labelMedium?.copyWith(
                                fontFamily: 'JetBrains Mono',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.read<ProductCubit>().setSubView(ProductDetailView(product)),
                      child: Text(
                        'View Details',
                        style: TextStyle(
                          color: colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MobileProductDetailView extends StatelessWidget {
  const _MobileProductDetailView({
    required this.product,
    required this.onBack,
  });

  final Product product;
  final VoidCallback onBack;

  void _showEditVariantBottomSheet(BuildContext context, Product product, ProductVariant variant) {
    final nameController = TextEditingController(text: variant.name);
    final skuController = TextEditingController(text: variant.sku);
    final quantityController = TextEditingController(text: variant.quantity.toString());
    final unitController = TextEditingController(text: variant.unit);
    final wholesaleController = TextEditingController(text: variant.wholesale.toString());
    final mrpController = TextEditingController(text: variant.mrp.toString());
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Edit Variant - ${variant.name}',
                    style: Theme.of(modalContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Variant Name'),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                    validator: (val) => (val == null || val.trim().isEmpty) ? 'SKU is required' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          validator: (val) => (val == null || double.tryParse(val) == null) ? 'Must be a number' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: const ['pcs', 'ml', 'gm', 'kg', 'L'].contains(unitController.text) ? unitController.text : 'gm',
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'gm', child: Text('gm')),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'L', child: Text('L')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              unitController.text = val;
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: wholesaleController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'Wholesale Price (₹)'),
                          validator: (val) => (val == null || double.tryParse(val) == null) ? 'Must be a number' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: mrpController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(labelText: 'MRP (₹)'),
                          validator: (val) => (val == null || double.tryParse(val) == null) ? 'Must be a number' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        final newName = nameController.text.trim();
                        final newSku = skuController.text.trim();
                        final newQuantity = double.parse(quantityController.text);
                        final newUnit = unitController.text.trim();
                        final newWholesale = double.parse(wholesaleController.text);
                        final newMrp = double.parse(mrpController.text);

                        final updatedVariants = product.variants.map((v) {
                          if (v.sku == variant.sku) {
                            return ProductVariant(
                              name: newName,
                              quantity: newQuantity,
                              unit: newUnit,
                              sku: newSku,
                              wholesale: newWholesale,
                              mrp: newMrp,
                            );
                          }
                          return v;
                        }).toList();

                        final updatedProduct = Product(
                          id: product.id,
                          name: product.name,
                          sku: product.sku,
                          category: product.category,
                          shelfLifeDays: product.shelfLifeDays,
                          storageConditions: product.storageConditions,
                          imageUrl: product.imageUrl,
                          ingredients: product.ingredients,
                          nutritionFacts: product.nutritionFacts,
                          variants: List.unmodifiable(updatedVariants),
                          lastModified: DateTime.now(),
                        );

                        context.read<ProductCubit>().saveProduct(updatedProduct);
                        Navigator.of(modalContext).pop();
                      }
                    },
                    child: const Text('Save Variant'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final heroHeader = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: colorScheme.containerLow,
                image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: resolveImageProvider(product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: product.imageUrl == null || product.imageUrl!.isEmpty
                  ? Icon(Icons.image_outlined, size: 48, color: colorScheme.outline)
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.container,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (product.category ?? 'N/A').toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    border: Border.all(color: Colors.green.shade200),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Text(
                        'ACTIVE',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(product.name, style: textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              product.storageConditions ?? 'No specific storage requirements.',
              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Text('GLOBAL SKU PREFIX', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
            const SizedBox(height: 4),
            Text(
              product.sku,
              style: textTheme.bodyMedium?.copyWith(
                fontFamily: 'JetBrains Mono',
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );

    final variantsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Packaging Variants & Prices', style: textTheme.titleSmall),
            const Divider(),
            if (product.variants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No packaging variants configured.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                ),
              )
            else
              ...product.variants.map((v) => Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.name, style: textTheme.titleSmall),
                              Text('${v.quantity} ${v.unit} | SKU: ${v.sku}', style: textTheme.bodySmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('MRP: ₹${v.mrp.toStringAsFixed(2)}', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 12),
                                  Text('WS: ₹${v.wholesale.toStringAsFixed(2)}', style: textTheme.bodySmall),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _showEditVariantBottomSheet(context, product, v),
                              tooltip: 'Edit Variant',
                            ),
                            IconButton(
                              icon: const Icon(Icons.print_outlined, size: 20),
                              onPressed: () {
                                PrintTemplateSelectRoute(
                                  productId: product.id,
                                  variantSku: v.sku,
                                ).go(context);
                              },
                              tooltip: 'Print Label',
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );

    final shelfLifeCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Shelf Life & Storage', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 12),
            Text('Recommended Life: ${product.shelfLifeDays ?? 365} Days', style: textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(
              product.storageConditions ?? 'Store in a cool, dry place.',
              style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );

    final ingredientsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ingredients', style: textTheme.titleSmall),
            const Divider(),
            if (product.ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No ingredients listed.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: product.ingredients
                    .map((ing) => Chip(
                          label: Text('${ing.name} (${ing.percentage}%)'),
                          backgroundColor: colorScheme.containerLow,
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );

    final nutritionFactsCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nutrition Facts', style: textTheme.titleSmall),
            const Divider(),
            if (product.nutritionFacts == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No nutrition facts defined.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
              )
            else
              Table(
                border: TableBorder.all(color: colorScheme.outlineVariant, width: 0.5, borderRadius: BorderRadius.circular(4)),
                children: [
                  _buildNutritionRow('Calories', '${product.nutritionFacts!.calories.toStringAsFixed(0)} kcal'),
                  _buildNutritionRow('Protein', '${product.nutritionFacts!.protein.toStringAsFixed(1)} g'),
                  _buildNutritionRow('Total Fat', '${product.nutritionFacts!.totalFat.toStringAsFixed(1)} g'),
                  _buildNutritionRow('Saturated Fat', '${product.nutritionFacts!.saturatedFat.toStringAsFixed(1)} g'),
                  _buildNutritionRow('Carbohydrates', '${product.nutritionFacts!.totalCarbs.toStringAsFixed(1)} g'),
                  _buildNutritionRow('Dietary Fiber', '${product.nutritionFacts!.fiber.toStringAsFixed(1)} g'),
                ],
              ),
          ],
        ),
      ),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: onBack,
        ),
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.read<ProductCubit>().setSubView(ProductEditView(product)),
            tooltip: 'Edit Product',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Delete Product'),
                  content: Text('Are you sure you want to delete ${product.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await context.read<ProductCubit>().deleteProduct(product.id);
                onBack();
              }
            },
            tooltip: 'Delete Product',
          ),
        ],
      ),
      body: AdaptiveScrollWrapper(
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              heroHeader,
              const SizedBox(height: 16),
              variantsCard,
              const SizedBox(height: 16),
              shelfLifeCard,
              const SizedBox(height: 16),
              ingredientsCard,
              const SizedBox(height: 16),
              nutritionFactsCard,
            ],
          );
        },
      ),
    );
  }

  TableRow _buildNutritionRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(value),
        ),
      ],
    );
  }
}
