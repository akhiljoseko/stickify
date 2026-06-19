import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_detail_ingredients_card.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_detail_nutrition_facts_card.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_detail_storage_card.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class MobileProductDetailPanel extends StatelessWidget {
  const MobileProductDetailPanel({
    required this.product,
    required this.onBack,
    super.key,
  });

  final Product product;
  final VoidCallback onBack;

  void _showEditVariantBottomSheet(BuildContext context, ProductVariant variant) {
    final nameController = TextEditingController(text: variant.name);
    final skuController = TextEditingController(text: variant.sku);
    final quantityController = TextEditingController(text: variant.quantity.toString());
    final unitController = TextEditingController(text: variant.unit);
    final wholesaleController = TextEditingController(text: variant.wholesale.toString());
    final mrpController = TextEditingController(text: variant.mrp.toString());
    final formKey = GlobalKey<FormState>();
    String? selectedTemplateId = variant.defaultTemplateId;

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
                  const SizedBox(height: 12),
                  FutureBuilder<List<LabelTemplate>>(
                    future: (() async {
                      final repo = context.read<TemplateRepository>();
                      final result = await repo.fetchTemplates();
                      return switch (result) {
                        Success(value: final templates) =>
                          templates.where((t) => t.isFinalized).toList(),
                        Failure() => <LabelTemplate>[],
                      };
                    })(),
                    builder: (context, snapshot) {
                      final templates = (snapshot.data ?? <LabelTemplate>[])
                        ..sort((a, b) => a.name.compareTo(b.name));
                      final isLoading =
                          snapshot.connectionState != ConnectionState.done;
                      return DropdownButtonFormField<String?>(
                        initialValue: selectedTemplateId,
                        decoration: const InputDecoration(
                          labelText: 'Default Template (optional)',
                          hintText: 'None',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (always pick)'),
                          ),
                          ...templates.map(
                            (t) => DropdownMenuItem<String?>(
                              value: t.id,
                              child: Text(t.name),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (val) {
                                selectedTemplateId = val;
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
                              defaultTemplateId: selectedTemplateId,
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
            const Divider(),
            const SizedBox(height: 8),
            if (product.shelfLifeDays != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 14, color: colorScheme.secondary),
                  const SizedBox(width: 6),
                  Text(
                    'Shelf Life: ${product.shelfLifeDays} Days',
                    style: textTheme.bodySmall?.copyWith(color: colorScheme.secondary),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Packaging Variants & Prices', style: textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => _showAddVariantBottomSheet(context),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add Variant'),
                ),
              ],
            ),
            const Divider(),
            if (product.variants.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text('No packaging variants configured.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                ),
              )
            else
              ...product.variants.map((v) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(v.name, style: textTheme.titleSmall),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${v.quantity} ${v.unit} | SKU: ${v.sku}', style: textTheme.bodySmall),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text('MRP: ₹${v.mrp.toStringAsFixed(2)}', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Text('WS: ₹${v.wholesale.toStringAsFixed(2)}', style: textTheme.bodySmall),
                            const SizedBox(width: 12),
                            Text('₹${v.unitPrice.toStringAsFixed(2)}/${v.unit}', style: textTheme.bodySmall?.copyWith(color: colorScheme.secondary)),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _showEditVariantBottomSheet(context, v);
                        } else if (value == 'print') {
                          PrintTemplateSelectRoute(
                            productId: product.id,
                            variantSku: v.sku,
                          ).go(context);
                        } else if (value == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dialogCtx) => AlertDialog(
                              title: const Text('Delete Variant'),
                              content: Text('Are you sure you want to delete ${v.name}?'),
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
                          if (confirm == true) {
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
                          value: 'print',
                          child: ListTile(
                            leading: Icon(Icons.print_outlined, size: 20),
                            title: Text('Print'),
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
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
                  )),
          ],
        ),
      ),
    );

    final ingredientsCard = ProductDetailIngredientsCard(
      ingredients: product.ingredients,
    );

    final nutritionFactsCard = ProductDetailNutritionFactsCard(
      nutritionFacts: product.nutritionFacts,
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
              ingredientsCard,
              const SizedBox(height: 16),
              nutritionFactsCard,
              const SizedBox(height: 16),
              storageCard,
            ],
          );
        },
      ),
    );
  }

  void _showAddVariantBottomSheet(BuildContext context) {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final quantityController = TextEditingController();
    final unitController = TextEditingController(text: 'gm');
    final wholesaleController = TextEditingController();
    final mrpController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? selectedTemplateId;

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
                    'Add Variant',
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
                          initialValue: 'gm',
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
                  const SizedBox(height: 12),
                  FutureBuilder<List<LabelTemplate>>(
                    future: (() async {
                      final repo = context.read<TemplateRepository>();
                      final result = await repo.fetchTemplates();
                      return switch (result) {
                        Success(value: final templates) =>
                          templates.where((t) => t.isFinalized).toList(),
                        Failure() => <LabelTemplate>[],
                      };
                    })(),
                    builder: (context, snapshot) {
                      final templates = (snapshot.data ?? <LabelTemplate>[])
                        ..sort((a, b) => a.name.compareTo(b.name));
                      final isLoading =
                          snapshot.connectionState != ConnectionState.done;
                      return DropdownButtonFormField<String?>(
                        initialValue: selectedTemplateId,
                        decoration: const InputDecoration(
                          labelText: 'Default Template (optional)',
                          hintText: 'None',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('None (always pick)'),
                          ),
                          ...templates.map(
                            (t) => DropdownMenuItem<String?>(
                              value: t.id,
                              child: Text(t.name),
                            ),
                          ),
                        ],
                        onChanged: isLoading
                            ? null
                            : (val) {
                                selectedTemplateId = val;
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
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
                          defaultTemplateId: selectedTemplateId,
                        );
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
                          variants: List.unmodifiable([...product.variants, newVariant]),
                          lastModified: DateTime.now(),
                        );
                        context.read<ProductCubit>().saveProduct(
                          updatedProduct,
                          nextView: ProductDetailView(updatedProduct),
                        );
                        Navigator.of(modalContext).pop();
                      }
                    },
                    child: const Text('Add Variant'),
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
