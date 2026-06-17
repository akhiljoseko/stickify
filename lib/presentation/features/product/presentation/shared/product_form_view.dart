import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/platform/file_picker_service.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_shared_widgets.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Reusable and adaptive Product Form View supporting both mobile and desktop layouts.
/// Provides fields for basic details, storage, ingredients, nutrition facts, and variants.
class ProductFormView extends StatefulWidget {
  /// Creates a [ProductFormView] instance.
  const ProductFormView({
    required this.onBack,
    required this.onSave,
    this.product,
    super.key,
  });

  /// The product to edit, or null if creating a new product.
  final Product? product;

  /// Callback when the user requests to go back.
  final VoidCallback onBack;

  /// Callback when the product is saved.
  final ValueChanged<Product> onSave;

  @override
  State<ProductFormView> createState() => ProductFormViewState();
}

class ProductFormViewState extends State<ProductFormView> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _categoryController;
  late final TextEditingController _shelfLifeController;
  late final TextEditingController _storageController;
  late final TextEditingController _imageUrlController;

  bool _includeNutrition = false;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _saturatedFatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fiberController;

  final List<Ingredient> _ingredients = [];
  final List<ProductVariant> _variants = [];

  final TextEditingController _ingNameController = TextEditingController();
  final TextEditingController _ingPercentController = TextEditingController();

  final TextEditingController _varNameController = TextEditingController();
  final TextEditingController _varSkuController = TextEditingController();
  final TextEditingController _varQtyController = TextEditingController();
  final TextEditingController _varUnitController = TextEditingController(text: 'pcs');
  final TextEditingController _varWholesaleController = TextEditingController();
  final TextEditingController _varMrpController = TextEditingController();

  Future<void> _pickImage() async {
    final path = await context.read<FilePickerService>().pickImage();
    if (path != null) {
      setState(() {
        _imageUrlController.text = path;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameController = TextEditingController(text: p?.name)..addListener(_rebuild);
    _skuController = TextEditingController(text: p?.sku)..addListener(_rebuild);
    _categoryController = TextEditingController(text: p?.category ?? 'Beverages')..addListener(_rebuild);
    _shelfLifeController = TextEditingController(text: p?.shelfLifeDays?.toString() ?? '365')..addListener(_rebuild);
    _storageController = TextEditingController(text: p?.storageConditions ?? '')..addListener(_rebuild);
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '')..addListener(_rebuild);

    var previousSku = _skuController.text;
    _skuController.addListener(() {
      final currentSku = _skuController.text;
      if (_varSkuController.text.isEmpty || _varSkuController.text == previousSku) {
        _varSkuController.text = currentSku;
      }
      previousSku = currentSku;
    });

    if (p != null) {
      _ingredients.addAll(p.ingredients);
      _variants.addAll(p.variants);
      if (p.nutritionFacts != null) {
        _includeNutrition = true;
        _caloriesController = TextEditingController(text: p.nutritionFacts!.calories.toString());
        _proteinController = TextEditingController(text: p.nutritionFacts!.protein.toString());
        _fatController = TextEditingController(text: p.nutritionFacts!.totalFat.toString());
        _saturatedFatController = TextEditingController(text: p.nutritionFacts!.saturatedFat.toString());
        _carbsController = TextEditingController(text: p.nutritionFacts!.totalCarbs.toString());
        _fiberController = TextEditingController(text: p.nutritionFacts!.fiber.toString());
      } else {
        _initEmptyNutritionControllers();
      }
    } else {
      _initEmptyNutritionControllers();
    }

    _caloriesController.addListener(_rebuild);
    _proteinController.addListener(_rebuild);
    _fatController.addListener(_rebuild);
    _saturatedFatController.addListener(_rebuild);
    _carbsController.addListener(_rebuild);
    _fiberController.addListener(_rebuild);
  }

  void _initEmptyNutritionControllers() {
    _caloriesController = TextEditingController(text: '0');
    _proteinController = TextEditingController(text: '0');
    _fatController = TextEditingController(text: '0');
    _saturatedFatController = TextEditingController(text: '0');
    _carbsController = TextEditingController(text: '0');
    _fiberController = TextEditingController(text: '0');
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _categoryController.dispose();
    _shelfLifeController.dispose();
    _storageController.dispose();
    _imageUrlController.dispose();

    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _saturatedFatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();

    _ingNameController.dispose();
    _ingPercentController.dispose();

    _varNameController.dispose();
    _varSkuController.dispose();
    _varQtyController.dispose();
    _varUnitController.dispose();
    _varWholesaleController.dispose();
    _varMrpController.dispose();

    super.dispose();
  }

  void _saveForm() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text;
    final sku = _skuController.text;
    final category = _categoryController.text;
    final shelfLife = int.tryParse(_shelfLifeController.text);
    final storage = _storageController.text.isEmpty ? null : _storageController.text;
    final image = _imageUrlController.text.isEmpty ? null : _imageUrlController.text;

    NutritionFacts? nutrition;
    if (_includeNutrition) {
      nutrition = NutritionFacts(
        calories: double.tryParse(_caloriesController.text) ?? 0,
        protein: double.tryParse(_proteinController.text) ?? 0,
        totalFat: double.tryParse(_fatController.text) ?? 0,
        saturatedFat: double.tryParse(_saturatedFatController.text) ?? 0,
        totalCarbs: double.tryParse(_carbsController.text) ?? 0,
        fiber: double.tryParse(_fiberController.text) ?? 0,
      );
    }

    final product = Product(
      id: widget.product?.id ?? 'prod-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      sku: sku,
      totalPrints: widget.product?.totalPrints ?? 0,
      lastPrintedAt: widget.product?.lastPrintedAt ?? DateTime.now(),
      category: category,
      shelfLifeDays: shelfLife,
      storageConditions: storage,
      imageUrl: image,
      ingredients: List.unmodifiable(_ingredients),
      nutritionFacts: nutrition,
      variants: List.unmodifiable(_variants),
    );

    widget.onSave(product);
  }

  /// Expose saveForm publicly for the parent Scaffold's AppBar.
  void saveForm() {
    _saveForm();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isMobile = context.watch<AppEnvironment>().experience == AppExperience.mobile;

    void addIngredientAction() {
      final name = _ingNameController.text;
      final pct = double.tryParse(_ingPercentController.text) ?? 0;
      if (name.isNotEmpty && pct > 0) {
        setState(() {
          _ingredients.add(Ingredient(name: name, percentage: pct));
          _ingNameController.clear();
          _ingPercentController.clear();
        });
      }
    }

    void addVariantAction() {
      final name = _varNameController.text;
      final sku = _varSkuController.text;
      final qty = double.tryParse(_varQtyController.text) ?? 1.0;
      final unit = _varUnitController.text;
      final wholesale = double.tryParse(_varWholesaleController.text) ?? 0.0;
      final mrp = double.tryParse(_varMrpController.text) ?? 0.0;

      if (name.isNotEmpty && sku.isNotEmpty) {
        setState(() {
          _variants.add(
            ProductVariant(
              name: name,
              quantity: qty,
              unit: unit,
              wholesale: wholesale,
              mrp: mrp,
              sku: sku,
            ),
          );
          _varNameController.clear();
          _varSkuController.text = _skuController.text; // reset to global sku
          _varQtyController.clear();
          _varWholesaleController.clear();
          _varMrpController.clear();
        });
      }
    }

    final basicInfoCard = Card(
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
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Product Name', hintText: 'e.g. Organic Almond Milk'),
              validator: (val) => (val == null || val.isEmpty) ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _categoryController.text.isEmpty ? 'Beverages' : _categoryController.text,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                  DropdownMenuItem(value: 'Dry Goods', child: Text('Dry Goods')),
                  DropdownMenuItem(value: 'Frozen Food', child: Text('Frozen Food')),
                  DropdownMenuItem(value: 'Produce', child: Text('Produce')),
                ],
                onChanged: (val) {
                  if (val != null) _categoryController.text = val;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shelfLifeController,
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
                      initialValue: _categoryController.text.isEmpty ? 'Beverages' : _categoryController.text,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                        DropdownMenuItem(value: 'Dry Goods', child: Text('Dry Goods')),
                        DropdownMenuItem(value: 'Frozen Food', child: Text('Frozen Food')),
                        DropdownMenuItem(value: 'Produce', child: Text('Produce')),
                      ],
                      onChanged: (val) {
                        if (val != null) _categoryController.text = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _shelfLifeController,
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
              controller: _skuController,
              decoration: const InputDecoration(labelText: 'Global SKU Prefix', hintText: 'e.g. ALM-ORG-2024'),
              validator: (val) => (val == null || val.isEmpty) ? 'SKU Prefix is required' : null,
            ),
          ],
        ),
      ),
    );

    final storageCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.thermostat_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Storage & Compliance', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storageController,
              decoration: const InputDecoration(labelText: 'Storage Conditions', hintText: 'e.g. Keep refrigerated below 5°C'),
            ),
            const SizedBox(height: 16),
            Text('Product Image', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                ),
                child: _imageUrlController.text.isNotEmpty
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image(
                                image: getImageProvider(_imageUrlController.text),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
                              radius: 16,
                              child: IconButton(
                                icon: Icon(Icons.close, size: 16, color: colorScheme.error),
                                onPressed: () {
                                  setState(() {
                                    _imageUrlController.clear();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to select image', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                          ],
                        ),
                      ),
              ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu_outlined, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Granular Ingredients', style: textTheme.titleSmall),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              TextField(
                controller: _ingNameController,
                decoration: const InputDecoration(labelText: 'Ingredient Name', hintText: 'e.g. Organic Almonds'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Percent (%)', hintText: '12.5'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: addIngredientAction,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ingNameController,
                      decoration: const InputDecoration(labelText: 'Ingredient Name', hintText: 'e.g. Organic Almonds'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _ingPercentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Percent (%)', hintText: '12.5'),
                    ),
                  ),
                  IconButton(
                    onPressed: addIngredientAction,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Ingredient',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ingredients.length,
                itemBuilder: (context, i) {
                  final ing = _ingredients[i];
                  return ListTile(
                    title: Text(ing.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${ing.percentage}%', style: textTheme.bodyMedium),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () {
                            setState(() {
                              _ingredients.removeAt(i);
                            });
                          },
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

    final nutritionCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_outlined, color: colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Nutrition Facts', style: textTheme.titleSmall),
                  ],
                ),
                Switch(
                  value: _includeNutrition,
                  onChanged: (val) => setState(() => _includeNutrition = val),
                ),
              ],
            ),
            if (_includeNutrition) ...[
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _caloriesController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Calories (kcal)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _proteinController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Protein (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _fatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Fat (g)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _saturatedFatController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Saturated Fat (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _carbsController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Total Carbs (g)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fiberController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Fiber (g)'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
              children: [
                Icon(Icons.layers_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Product Variants', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            if (isMobile) ...[
              TextField(
                controller: _varNameController,
                decoration: const InputDecoration(labelText: 'Variant Name', hintText: 'e.g. 150g Pouch'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _varSkuController,
                decoration: const InputDecoration(labelText: 'Variant SKU', hintText: 'e.g. ALM-150P-001'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _varQtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Qty', hintText: '150'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _varUnitController.text,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                        DropdownMenuItem(value: 'gm', child: Text('gm')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'L', child: Text('L')),
                      ],
                      onChanged: (val) {
                        if (val != null) _varUnitController.text = val;
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
                      controller: _varWholesaleController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Wholesale (₹)', hintText: '8.50'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _varMrpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'MRP (₹)', hintText: '12.50'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: addVariantAction,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Variant'),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _varNameController,
                      decoration: const InputDecoration(labelText: 'Variant Name', hintText: 'e.g. 150g Pouch'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _varSkuController,
                      decoration: const InputDecoration(labelText: 'Variant SKU', hintText: 'e.g. ALM-150P-001'),
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
                      controller: _varQtyController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Qty', hintText: '150'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _varUnitController.text,
                      decoration: const InputDecoration(labelText: 'Unit'),
                      items: const [
                        DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                        DropdownMenuItem(value: 'ml', child: Text('ml')),
                        DropdownMenuItem(value: 'gm', child: Text('gm')),
                        DropdownMenuItem(value: 'kg', child: Text('kg')),
                        DropdownMenuItem(value: 'L', child: Text('L')),
                      ],
                      onChanged: (val) {
                        if (val != null) _varUnitController.text = val;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _varWholesaleController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Wholesale (₹)', hintText: '8.50'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _varMrpController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'MRP (₹)', hintText: '12.50'),
                    ),
                  ),
                  IconButton(
                    onPressed: addVariantAction,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Variant',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
            if (_variants.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _variants.length,
                itemBuilder: (context, i) {
                  final v = _variants[i];
                  return ListTile(
                    title: Text(v.name, style: textTheme.titleSmall),
                    subtitle: Text('${v.sku} | ${v.quantity} ${v.unit} | Wholesale: ₹${v.wholesale} | MRP: ₹${v.mrp}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () {
                        setState(() {
                          _variants.removeAt(i);
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );

    final formFields = Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdaptiveLayoutSwitcher(
            mobile: Column(
              children: [
                basicInfoCard,
                const SizedBox(height: 16),
                storageCard,
              ],
            ),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: basicInfoCard),
                const SizedBox(width: 16),
                Expanded(child: storageCard),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AdaptiveLayoutSwitcher(
            mobile: Column(
              children: [
                ingredientsCard,
                const SizedBox(height: 16),
                nutritionCard,
              ],
            ),
            desktop: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: ingredientsCard),
                const SizedBox(width: 16),
                Expanded(flex: 5, child: nutritionCard),
              ],
            ),
          ),
          const SizedBox(height: 16),
          variantsCard,
        ],
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: AdaptiveScrollWrapper(
          builder: (context, controller) {
            return CustomScrollView(
              controller: controller,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (!isMobile) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            OutlinedButton.icon(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back, size: 16),
                              label: const Text('Back to Catalog'),
                            ),
                            ElevatedButton.icon(
                              onPressed: _saveForm,
                              icon: const Icon(Icons.save, size: 16),
                              label: Text(widget.product != null ? 'Update Product' : 'Create Product'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.product != null ? 'Edit Product' : 'Add New Product',
                          style: textTheme.displayLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                      formFields,
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
