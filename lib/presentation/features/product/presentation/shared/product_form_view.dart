import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/platform/file_picker_service.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/presentation/features/product/presentation/shared/form_basic_info_section.dart';
import 'package:stickify/presentation/features/product/presentation/shared/form_ingredients_section.dart';
import 'package:stickify/presentation/features/product/presentation/shared/form_nutrition_section.dart';
import 'package:stickify/presentation/features/product/presentation/shared/form_storage_section.dart';
import 'package:stickify/presentation/features/product/presentation/shared/form_variants_section.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';
import 'package:uuid/uuid.dart';

/// Reusable and adaptive Product Form View supporting both mobile and desktop layouts.
/// Provides fields for basic details, storage, ingredients, nutrition facts, and variants.
class ProductFormView extends StatefulWidget {
  /// Creates a [ProductFormView] instance.
  const ProductFormView({
    required this.onBack,
    required this.onSave,
    this.product,
    this.isCopy = false,
    super.key,
  });

  /// The product to edit, or null if creating a new product.
  final Product? product;

  /// Whether the product is being copied.
  final bool isCopy;

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
  int? _editingVariantIndex;

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

    _nameController = TextEditingController(
      text: widget.isCopy && p != null ? '${p.name} (Copy)' : p?.name,
    );
    _skuController = TextEditingController(
      text: widget.isCopy && p != null ? '${p.sku}-copy' : p?.sku,
    );
    _categoryController = TextEditingController(text: p?.category ?? ProductCategories.defaultCategory);
    _shelfLifeController = TextEditingController(text: p?.shelfLifeDays?.toString() ?? '365');
    _storageController = TextEditingController(text: p?.storageConditions ?? '');
    _imageUrlController = TextEditingController(text: p?.imageUrl ?? '');

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
      if (widget.isCopy) {
        _variants.addAll(p.variants.map((v) => v.copyWith(sku: '${v.sku}-copy')));
      } else {
        _variants.addAll(p.variants);
      }
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

  }

  void _initEmptyNutritionControllers() {
    _caloriesController = TextEditingController(text: '0');
    _proteinController = TextEditingController(text: '0');
    _fatController = TextEditingController(text: '0');
    _saturatedFatController = TextEditingController(text: '0');
    _carbsController = TextEditingController(text: '0');
    _fiberController = TextEditingController(text: '0');
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
      id: widget.isCopy ? 'prod-${const Uuid().v4()}' : (widget.product?.id ?? 'prod-${const Uuid().v4()}'),
      name: name,
      sku: sku,
      category: category,
      shelfLifeDays: shelfLife,
      storageConditions: storage,
      imageUrl: image,
      ingredients: List.unmodifiable(_ingredients),
      nutritionFacts: nutrition,
      variants: List.unmodifiable(_variants),
      lastModified: DateTime.now(),
    );

    widget.onSave(product);
  }

  void _addIngredient() {
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

  void _addVariant() {
    final name = _varNameController.text;
    final sku = _varSkuController.text;
    final qty = double.tryParse(_varQtyController.text) ?? 1.0;
    final unit = _varUnitController.text;
    final wholesale = double.tryParse(_varWholesaleController.text) ?? 0.0;
    final mrp = double.tryParse(_varMrpController.text) ?? 0.0;

    if (name.isNotEmpty && sku.isNotEmpty) {
      setState(() {
        final variant = ProductVariant(
          name: name,
          quantity: qty,
          unit: unit,
          wholesale: wholesale,
          mrp: mrp,
          sku: sku,
        );

        if (_editingVariantIndex != null) {
          _variants[_editingVariantIndex!] = variant;
          _editingVariantIndex = null;
        } else {
          _variants.add(variant);
        }

        _varNameController.clear();
        _varSkuController.text = _skuController.text;
        _varQtyController.clear();
        _varWholesaleController.clear();
        _varMrpController.clear();
        _varUnitController.text = 'pcs';
      });
    }
  }

  void _editVariant(int index) {
    final v = _variants[index];
    setState(() {
      _editingVariantIndex = index;
      _varNameController.text = v.name;
      _varSkuController.text = v.sku;
      _varQtyController.text = v.quantity.toString();
      _varUnitController.text = v.unit;
      _varWholesaleController.text = v.wholesale.toString();
      _varMrpController.text = v.mrp.toString();
    });
  }

  void _cancelEditVariant() {
    setState(() {
      _editingVariantIndex = null;
      _varNameController.clear();
      _varSkuController.text = _skuController.text;
      _varQtyController.clear();
      _varWholesaleController.clear();
      _varMrpController.clear();
      _varUnitController.text = 'pcs';
    });
  }

  void _clearImage() {
    setState(() {
      _imageUrlController.clear();
    });
  }

  /// Expose saveForm publicly for the parent Scaffold's AppBar.
  void saveForm() {
    _saveForm();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isMobile = context.watch<AppEnvironment>().experience == AppExperience.mobile;

    final basicInfoCard = FormBasicInfoSection(
      nameController: _nameController,
      categoryController: _categoryController,
      shelfLifeController: _shelfLifeController,
      skuController: _skuController,
      isMobile: isMobile,
    );

    final storageCard = FormStorageSection(
      storageController: _storageController,
      imageUrlController: _imageUrlController,
      onPickImage: _pickImage,
      onClearImage: _clearImage,
    );

    final ingredientsCard = FormIngredientsSection(
      ingNameController: _ingNameController,
      ingPercentController: _ingPercentController,
      ingredients: _ingredients,
      onAddIngredient: _addIngredient,
      onRemoveIngredient: (i) => setState(() => _ingredients.removeAt(i)),
      isMobile: isMobile,
    );

    final nutritionCard = FormNutritionSection(
      includeNutrition: _includeNutrition,
      onToggleNutrition: (val) => setState(() => _includeNutrition = val),
      caloriesController: _caloriesController,
      proteinController: _proteinController,
      fatController: _fatController,
      saturatedFatController: _saturatedFatController,
      carbsController: _carbsController,
      fiberController: _fiberController,
    );

    final variantsCard = FormVariantsSection(
      varNameController: _varNameController,
      varSkuController: _varSkuController,
      varQtyController: _varQtyController,
      varUnitController: _varUnitController,
      varWholesaleController: _varWholesaleController,
      varMrpController: _varMrpController,
      variants: _variants,
      onAddVariant: _addVariant,
      onRemoveVariant: (i) {
        setState(() {
          _variants.removeAt(i);
          if (_editingVariantIndex == i) {
            _editingVariantIndex = null;
            _varNameController.clear();
            _varSkuController.text = _skuController.text;
            _varQtyController.clear();
            _varWholesaleController.clear();
            _varMrpController.clear();
            _varUnitController.text = 'pcs';
          } else if (_editingVariantIndex != null && _editingVariantIndex! > i) {
            _editingVariantIndex = _editingVariantIndex! - 1;
          }
        });
      },
      onEditVariant: _editVariant,
      isMobile: isMobile,
      editingIndex: _editingVariantIndex,
      onCancelEdit: _cancelEditVariant,
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
                              label: Text(
                                widget.isCopy
                                    ? 'Create Product'
                                    : (widget.product != null
                                        ? 'Update Product'
                                        : 'Create Product'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.isCopy
                              ? 'Copy Product'
                              : (widget.product != null
                                  ? 'Edit Product'
                                  : 'Add New Product'),
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
