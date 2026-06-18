import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/utils/image_utils.dart';
import 'package:stickify/domain/entities/product.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final heroHeader = Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 700;

            final imgWidget = Container(
              width: isCompact ? double.infinity : 200,
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
            );

            final infoWidget = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text(product.name, style: textTheme.displayLarge),
                const SizedBox(height: 12),
                Text(
                  product.storageConditions ?? 'No specific storage requirements outlined for this asset.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 32,
                  runSpacing: 12,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('GLOBAL SKU PREFIX', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.sku,
                            style: textTheme.labelMedium?.copyWith(
                              fontFamily: 'JetBrains Mono',
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
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
                  ],
                ),
              ],
            );

            Future<bool> confirmDelete() async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Product'),
                  content: Text('Are you sure you want to delete ${product.name}?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              return confirm == true;
            }

            Widget adaptiveActions;

            if (constraints.maxWidth < 300) {
              adaptiveActions = PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  if (value == 'edit') {
                    onEdit(product);
                  } else if (value == 'delete' && await confirmDelete()) {
                    onDelete(product.id);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(
                    leading: Icon(Icons.edit, size: 20),
                    title: Text('Edit'),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                  )),
                  const PopupMenuItem(value: 'delete', child: ListTile(
                    leading: Icon(Icons.delete_outline, size: 20),
                    title: Text('Delete'),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    contentPadding: EdgeInsets.zero,
                  )),
                ],
              );
            } else if (constraints.maxWidth < 500) {
              adaptiveActions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onEdit(product),
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit Product',
                  ),
                  IconButton(
                    onPressed: () async {
                      if (await confirmDelete()) {
                        onDelete(product.id);
                      }
                    },
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Delete Product',
                  ),
                ],
              );
            } else {
              adaptiveActions = Column(
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
                      if (await confirmDelete()) {
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
              );
            }

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: imgWidget),
                      adaptiveActions,
                    ],
                  ),
                  const SizedBox(height: 20),
                  infoWidget,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                imgWidget,
                const SizedBox(width: 24),
                Expanded(child: infoWidget),
                const SizedBox(width: 24),
                SizedBox(width: 180, child: adaptiveActions),
              ],
            );
          },
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
                  onPressed: () => onEdit(product),
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
                  3: FlexColumnWidth(3),
                  4: FixedColumnWidth(100),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: colorScheme.containerLow),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('VARIANT NAME', style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('QUANTITY', style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('MRP (INR)', style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text('SKU CODE', style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: SizedBox(),
                      ),
                    ],
                  ),
                  ...product.variants.map((v) => TableRow(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text(v.name, style: textTheme.bodyMedium),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text('${v.quantity} ${v.unit}', style: textTheme.bodyMedium),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text('₹${v.mrp.toStringAsFixed(2)}', style: textTheme.bodyMedium),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Text(
                              v.sku,
                              style: textTheme.bodyMedium?.copyWith(fontFamily: 'JetBrains Mono'),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.print_outlined, size: 18),
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
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.containerLow,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Recommended Life', style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${product.shelfLifeDays ?? 365} Days',
                    style: textTheme.headlineMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('STORAGE CONDITIONS', style: textTheme.labelSmall?.copyWith(color: colorScheme.outline)),
            const SizedBox(height: 6),
            Text(
              product.storageConditions ?? 'Store in a cool, dry place away from direct sunlight.',
              style: textTheme.bodyMedium,
            ),
            if (product.category == 'Snacks') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Sensitive to high humidity',
                      style: textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
            ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ingredients', style: textTheme.titleSmall),
                TextButton.icon(
                  onPressed: () => onEdit(product),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit List'),
                ),
              ],
            ),
            const Divider(),
            if (product.ingredients.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
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
            if (product.ingredients.any((i) => i.name.toLowerCase().contains('almond') || i.name.toLowerCase().contains('nut'))) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ALLERGEN WARNING',
                      style: textTheme.labelSmall?.copyWith(color: colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Contains Nuts (Almonds). Processed in a facility that also handles soy, dairy, and wheat.',
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ],
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nutrition Facts', style: textTheme.titleSmall),
                Text('Per 100g serving', style: textTheme.bodySmall?.copyWith(color: colorScheme.outline, fontStyle: FontStyle.italic)),
              ],
            ),
            const Divider(),
            if (product.nutritionFacts == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No nutrition facts defined.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
              )
            else
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: colorScheme.containerLow,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('COMPONENT', style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
                          Text('VALUE', style: textTheme.labelSmall?.copyWith(fontFamily: 'JetBrains Mono')),
                        ],
                      ),
                    ),
                    _buildNutritionRow(textTheme, 'Calories', '${product.nutritionFacts!.calories.toStringAsFixed(0)} kcal'),
                    _buildNutritionRow(textTheme, 'Protein', '${product.nutritionFacts!.protein.toStringAsFixed(1)} g'),
                    _buildNutritionRow(textTheme, 'Total Fat', '${product.nutritionFacts!.totalFat.toStringAsFixed(1)} g'),
                    _buildNutritionRow(textTheme, 'Saturated Fat', '${product.nutritionFacts!.saturatedFat.toStringAsFixed(1)} g'),
                    _buildNutritionRow(textTheme, 'Total Carbohydrates', '${product.nutritionFacts!.totalCarbs.toStringAsFixed(1)} g'),
                    _buildNutritionRow(textTheme, 'Dietary Fiber', '${product.nutritionFacts!.fiber.toStringAsFixed(1)} g'),
                  ],
                ),
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
                        AdaptiveLayoutSwitcher(
                          mobile: Column(
                            children: [
                              variantsCard,
                              const SizedBox(height: 16),
                              shelfLifeCard,
                            ],
                          ),
                          desktop: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 8, child: variantsCard),
                              const SizedBox(width: 16),
                              Expanded(flex: 4, child: shelfLifeCard),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        AdaptiveLayoutSwitcher(
                          mobile: Column(
                            children: [
                              ingredientsCard,
                              const SizedBox(height: 16),
                              nutritionFactsCard,
                            ],
                          ),
                          desktop: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: ingredientsCard),
                              const SizedBox(width: 16),
                              Expanded(child: nutritionFactsCard),
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

  Widget _buildNutritionRow(TextTheme textTheme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }
}
