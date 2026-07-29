import 'package:flutter/material.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/presentation/features/product/presentation/shared/quantity_unit_dropdown.dart';

class FormVariantsSection extends StatelessWidget {
  const FormVariantsSection({
    required this.varNameController,
    required this.varSkuController,
    required this.varQtyController,
    required this.varUnitController,
    required this.varWholesaleController,
    required this.varMrpController,
    required this.variants,
    required this.onAddVariant,
    required this.onRemoveVariant,
    required this.onEditVariant,
    required this.isMobile,
    required this.globalSku,
    this.editingIndex,
    this.onCancelEdit,
    super.key,
  });

  final TextEditingController varNameController;
  final TextEditingController varSkuController;
  final TextEditingController varQtyController;
  final TextEditingController varUnitController;
  final TextEditingController varWholesaleController;
  final TextEditingController varMrpController;
  final List<ProductVariant> variants;
  final VoidCallback onAddVariant;
  final ValueChanged<int> onRemoveVariant;
  final ValueChanged<int> onEditVariant;
  final bool isMobile;
  final String globalSku;
  final int? editingIndex;
  final VoidCallback? onCancelEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.layers_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Product Variants', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              TextField(
                controller: varNameController,
                decoration: const InputDecoration(labelText: 'Variant Name', hintText: 'e.g. 150g Pouch'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: varSkuController,
                decoration: InputDecoration(
                  labelText: 'Variant SKU',
                  prefixText: globalSku.isNotEmpty ? '$globalSku-' : null,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: varQtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Qty', hintText: '150'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: QuantityUnitDropdown(
                      isExpanded: true,
                      initialValue: varUnitController.text,
                      onChanged: (val) {
                        if (val != null) varUnitController.text = val;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: varWholesaleController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Wholesale (₹)', hintText: '8.50'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: varMrpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'MRP (₹)', hintText: '12.50'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onAddVariant,
                        icon: Icon(editingIndex != null ? Icons.check : Icons.add),
                        label: Text(editingIndex != null ? 'Update Variant' : 'Add Variant'),
                      ),
                    ),
                    if (editingIndex != null && onCancelEdit != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onCancelEdit,
                        icon: const Icon(Icons.cancel_outlined),
                        tooltip: 'Cancel Edit',
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: varNameController,
                      decoration: const InputDecoration(labelText: 'Variant Name', hintText: 'e.g. 150g Pouch'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: varSkuController,
                      decoration: InputDecoration(
                        labelText: 'Variant SKU',
                        prefixText: globalSku.isNotEmpty ? '$globalSku-' : null,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: varQtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Qty', hintText: '150'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: QuantityUnitDropdown(
                      isExpanded: true,
                      initialValue: varUnitController.text,
                      onChanged: (val) {
                        if (val != null) varUnitController.text = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: varWholesaleController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Wholesale (₹)', hintText: '8.50'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: varMrpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'MRP (₹)', hintText: '12.50'),
                    ),
                  ),
                  IconButton(
                    onPressed: onAddVariant,
                    icon: Icon(editingIndex != null ? Icons.check_circle_outlined : Icons.add_circle_outline),
                    tooltip: editingIndex != null ? 'Update Variant' : 'Add Variant',
                    visualDensity: VisualDensity.compact,
                  ),
                  if (editingIndex != null && onCancelEdit != null) ...[
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: onCancelEdit,
                      icon: const Icon(Icons.cancel_outlined),
                      tooltip: 'Cancel Edit',
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
            ],
            if (variants.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: variants.length,
                itemBuilder: (context, i) {
                  final v = variants[i];
                  return ListTile(
                    title: Text(v.name, style: textTheme.titleSmall),
                    subtitle: Text(
                      '${v.sku} | ${v.quantity} ${v.unit} | '
                      'Wholesale: ${formatCurrency(v.wholesale)} | '
                      'MRP: ${formatCurrency(v.mrp)}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          onPressed: () => onEditVariant(i),
                          tooltip: 'Edit Variant',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => onRemoveVariant(i),
                          tooltip: 'Delete Variant',
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
