import 'package:flutter/material.dart';
import 'package:stickify/core/core.dart';

class FormBasicInfoSection extends StatelessWidget {
  const FormBasicInfoSection({
    required this.nameController,
    required this.categoryController,
    required this.shelfLifeController,
    required this.skuController,
    required this.isMobile,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController categoryController;
  final TextEditingController shelfLifeController;
  final TextEditingController skuController;
  final bool isMobile;

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
                Icon(Icons.info_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Basic Information', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Organic Almond Milk'),
              validator: (val) => (val == null || val.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: categoryController.text.isEmpty ? ProductCategories.defaultCategory : categoryController.text,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ProductCategories.all.map((cat) => DropdownMenuItem(
                  value: cat,
                  child: Text(cat),
                )).toList(),
                onChanged: (val) {
                  if (val != null) categoryController.text = val;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: shelfLifeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Shelf Life (Days)', hintText: 'e.g. 45'),
                validator: (val) {
                  if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                    return 'Must be an integer';
                  }
                  return null;
                },
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: categoryController.text.isEmpty ? ProductCategories.defaultCategory : categoryController.text,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ProductCategories.all.map((cat) => DropdownMenuItem(
                        value: cat,
                        child: Text(cat),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) categoryController.text = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: shelfLifeController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Shelf Life (Days)', hintText: 'e.g. 45'),
                      validator: (val) {
                        if (val != null && val.isNotEmpty && int.tryParse(val) == null) {
                          return 'Must be an integer';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: skuController,
              decoration: const InputDecoration(labelText: 'Global SKU Prefix', hintText: 'e.g. ALM-ORG-2024'),
              validator: (val) => (val == null || val.isEmpty) ? 'SKU Prefix is required' : null,
            ),
          ],
        ),
      ),
    );
  }
}
