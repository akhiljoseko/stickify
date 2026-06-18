import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/utils/image_utils.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_detail_ingredients_card.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_detail_nutrition_facts_card.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_detail_storage_card.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class ProductDetailPanel extends StatelessWidget {
  const ProductDetailPanel({
    required this.product,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Product product;
  final VoidCallback onBack;
  final ValueChanged<Product> onEdit;
  final ValueChanged<String> onDelete;

  void _showEditVariantDialog(BuildContext context, ProductVariant variant) {
    final nameController = TextEditingController(text: variant.name);
    final skuController = TextEditingController(text: variant.sku);
    final quantityController = TextEditingController(text: variant.quantity.toString());
    final unitController = TextEditingController(text: variant.unit);
    final wholesaleController = TextEditingController(text: variant.wholesale.toString());
    final mrpController = TextEditingController(text: variant.mrp.toString());
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Edit Variant - ${variant.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                            if (val != null) unitController.text = val;
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final updatedVariants = product.variants.map((v) {
                    if (v.sku == variant.sku) {
                      return ProductVariant(
                        name: nameController.text.trim(),
                        sku: skuController.text.trim(),
                        quantity: double.parse(quantityController.text),
                        unit: unitController.text.trim(),
                        wholesale: double.parse(wholesaleController.text),
                        mrp: double.parse(mrpController.text),
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

                  context.read<ProductCubit>().saveProduct(
                    updatedProduct,
                    nextView: ProductDetailView(updatedProduct),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Save Variant'),
            ),
          ],
        );
      },
    );
  }

  void _showAddVariantDialog(BuildContext context) {
    final nameController = TextEditingController();
    final skuController = TextEditingController(text: product.sku);
    final quantityController = TextEditingController(text: '1');
    final unitController = TextEditingController(text: 'pcs');
    final wholesaleController = TextEditingController();
    final mrpController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Variant'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                          initialValue: unitController.text,
                          decoration: const InputDecoration(labelText: 'Unit'),
                          items: const [
                            DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                            DropdownMenuItem(value: 'ml', child: Text('ml')),
                            DropdownMenuItem(value: 'gm', child: Text('gm')),
                            DropdownMenuItem(value: 'kg', child: Text('kg')),
                            DropdownMenuItem(value: 'L', child: Text('L')),
                          ],
                          onChanged: (val) {
                            if (val != null) unitController.text = val;
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
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newVariant = ProductVariant(
                    name: nameController.text.trim(),
                    sku: skuController.text.trim(),
                    quantity: double.parse(quantityController.text),
                    unit: unitController.text.trim(),
                    wholesale: double.parse(wholesaleController.text),
                    mrp: double.parse(mrpController.text),
                  );
                  final updatedVariants = [...product.variants, newVariant];
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
                  context.read<ProductCubit>().saveProduct(
                    updatedProduct,
                    nextView: ProductDetailView(updatedProduct),
                  );
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Add Variant'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _confirmDeleteVariant(BuildContext ctx, ProductVariant variant) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Variant'),
        content: Text('Are you sure you want to delete ${variant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  Future<bool> _confirmDeleteProduct(BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirm == true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final heroHeader = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 200,
              height: 200,
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
                  ? Icon(Icons.image_outlined, size: 64, color: colorScheme.outline)
                  : null,
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 12),
                  Text(product.name, style: textTheme.displayLarge),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 32,
                    runSpacing: 12,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('GLOBAL SKU PREFIX', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                          const SizedBox(height: 6),
                          Text(product.sku, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CATEGORY', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                          const SizedBox(height: 6),
                          Text(product.category ?? 'N/A', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LAST MODIFIED', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                          const SizedBox(height: 6),
                          Text(
                            product.lastModified != null ? DateFormat.yMMMd().format(product.lastModified!) : 'N/A',
                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (product.shelfLifeDays != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('SHELF LIFE', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                            const SizedBox(height: 6),
                            Text('${product.shelfLifeDays} Days', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            SizedBox(
              width: 180,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => onEdit(product),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit Product'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      if (await _confirmDeleteProduct(context)) {
                        onDelete(product.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Delete Product'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error),
                    ),
                  ),
                ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Packaging Variants', style: textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => _showAddVariantDialog(context),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add Variant'),
                ),
              ],
            ),
            const Divider(),
            if (product.variants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('No packaging variants configured.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                ),
              )
            else
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(3),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                  3: FlexColumnWidth(2),
                  4: FlexColumnWidth(2),
                  5: FixedColumnWidth(120),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: colorScheme.containerLow),
                    children: [
                      _headerCell(textTheme, 'VARIANT NAME'),
                      _headerCell(textTheme, 'QUANTITY'),
                      _headerCell(textTheme, 'MRP (INR)'),
                      _headerCell(textTheme, '₹/UNIT'),
                      _headerCell(textTheme, 'SKU CODE'),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SizedBox(),
                      ),
                    ],
                  ),
                  ...product.variants.map((v) => TableRow(
                        children: [
                          _cell(textTheme, v.name),
                          _cell(textTheme, '${v.quantity} ${v.unit}'),
                          _cell(textTheme, '₹${v.mrp.toStringAsFixed(2)}'),
                          _cell(textTheme, '₹${v.unitPrice.toStringAsFixed(2)}/${v.unit}'),
                          _cell(textTheme, v.sku, mono: true),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    PrintTemplateSelectRoute(
                                      productId: product.id,
                                      variantSku: v.sku,
                                    ).go(context);
                                  },
                                  icon: const Icon(Icons.print_outlined, size: 18),
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                  ),
                                  color: colorScheme.onPrimary,
                                  tooltip: 'Print Label',
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert, size: 18),
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      _showEditVariantDialog(context, v);
                                    } else if (value == 'delete') {
                                      if (await _confirmDeleteVariant(context, v)) {
                                        if (!context.mounted) return;
                                        final updatedVariants = product.variants.where((v2) => v2.sku != v.sku).toList();
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
                                        await context.read<ProductCubit>().saveProduct(
                                          updatedProduct,
                                          nextView: ProductDetailView(updatedProduct),
                                        );
                                      }
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: ListTile(
                                        leading: Icon(Icons.edit_outlined, size: 20),
                                        title: Text('Edit'),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: ListTile(
                                        leading: Icon(Icons.delete_outline, size: 20),
                                        title: Text('Delete'),
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      )),
                ],
              ),
          ],
        ),
      ),
    );

    final ingredientsCard = ProductDetailIngredientsCard(
      ingredients: product.ingredients,
    );

    final nutritionFactsCard = ProductDetailNutritionFactsCard(
      nutritionFacts: product.nutritionFacts,
      subtitle: 'Per 100g serving',
    );

    final storageCard = ProductDetailStorageCard(
      storageConditions: product.storageConditions,
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
            onPressed: () => onEdit(product),
            tooltip: 'Edit Product',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: AdaptiveScrollWrapper(
            builder: (context, controller) {
              return CustomScrollView(
                controller: controller,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        heroHeader,
                        const SizedBox(height: 16),
                        variantsCard,
                        const SizedBox(height: 16),
                        AdaptiveLayoutSwitcher(
                          mobile: Column(
                            children: [
                              ingredientsCard,
                              const SizedBox(height: 16),
                              nutritionFactsCard,
                              const SizedBox(height: 16),
                              storageCard,
                            ],
                          ),
                          desktop: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ingredientsCard,
                                    const SizedBox(height: 16),
                                    ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 600),
                                      child: storageCard,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: nutritionFactsCard,
                              ),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _headerCell(TextTheme textTheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text, style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
    );
  }

  Widget _cell(TextTheme textTheme, String text, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        style: mono
            ? textTheme.bodyMedium?.copyWith(fontFamily: 'JetBrains Mono')
            : textTheme.bodyMedium,
      ),
    );
  }
}
