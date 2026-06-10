import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

ImageProvider getImageProvider(String path) {
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return NetworkImage(path);
  } else {
    return FileImage(File(path));
  }
}

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductCubit(
        context.read<ProductRepository>(),
      )..loadProducts(),
      child: const _ProductManagementView(),
    );
  }
}

class _ProductManagementView extends StatelessWidget {
  const _ProductManagementView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductCatalogError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProductCatalogInitial || state is ProductCatalogLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductCatalogError && state.message.isNotEmpty && state is! ProductCatalogSuccess) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text('Failed to load products', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProductCubit>().loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
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

          if (state is ProductCatalogSuccess) {
            switch (state.subView) {
              case 'create':
                return _ProductFormView(
                  onBack: () => context.read<ProductCubit>().setSubView('catalog'),
                  onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                );
              case 'edit':
                return _ProductFormView(
                  product: state.selectedProduct,
                  onBack: () => context.read<ProductCubit>().setSubView('catalog'),
                  onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                );
              case 'details':
                return _ProductDetailView(
                  product: state.selectedProduct!,
                  onBack: () => context.read<ProductCubit>().setSubView('catalog'),
                  onEdit: (product) => context.read<ProductCubit>().setSubView('edit', product),
                  onDelete: (id) async {
                    await context.read<ProductCubit>().deleteProduct(id);
                    if (context.mounted) {
                      context.read<ProductCubit>().setSubView('catalog');
                    }
                  },
                );
              case 'catalog':
              default:
                return _CatalogListView(state: state);
            }
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _CatalogListView extends StatelessWidget {
  const _CatalogListView({required this.state});

  final ProductCatalogSuccess state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: AdaptiveScrollWrapper(
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            slivers: [
              SliverPadding(
                padding: AdaptiveValue<EdgeInsets>(
                  context,
                  defaultValue: const EdgeInsets.all(16),
                  tablet: const EdgeInsets.all(24),
                  desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                ).value,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Assets',
                                style: textTheme.displayLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage SKU labels and print specifications across 428 active assets.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.read<ProductCubit>().setSubView('create'),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isCompact = constraints.maxWidth < 600;
                            final searchField = TextField(
                              onChanged: (val) => context.read<ProductCubit>().applyFilter(query: val),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search, size: 20),
                                hintText: 'Search products by name or SKU...',
                                fillColor: colorScheme.containerLow,
                              ),
                            );

                            final categoryDropdown = DropdownButtonFormField<String>(
                              isExpanded: true,
                              initialValue: state.categoryFilter.isEmpty ? 'All' : state.categoryFilter,
                              decoration: InputDecoration(
                                labelText: 'Category',
                                fillColor: colorScheme.containerLow,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'All', child: Text('All Categories')),
                                DropdownMenuItem(value: 'Beverages', child: Text('Beverages')),
                                DropdownMenuItem(value: 'Dry Goods', child: Text('Dry Goods')),
                                DropdownMenuItem(value: 'Frozen Food', child: Text('Frozen Food')),
                                DropdownMenuItem(value: 'Produce', child: Text('Produce')),
                              ],
                              onChanged: (val) {
                                final categoryVal = (val == null || val == 'All') ? '' : val;
                                context.read<ProductCubit>().applyFilter(category: categoryVal);
                              },
                            );

                            if (isCompact) {
                              return Column(
                                children: [
                                  searchField,
                                  const SizedBox(height: 12),
                                  categoryDropdown,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: searchField),
                                const SizedBox(width: 16),
                                SizedBox(width: 220, child: categoryDropdown),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    AdaptiveLayoutSwitcher(
                      mobile: _ProductCatalogMobileGrid(products: state.filteredProducts),
                      desktop: _ProductCatalogDesktopTable(products: state.filteredProducts),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCatalogDesktopTable extends StatelessWidget {
  const _ProductCatalogDesktopTable({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (products.isEmpty) {
      return const _EmptyCatalogState();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.containerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 32),
                const SizedBox(width: 12),
                Expanded(
                  flex: 4,
                  child: Text(
                    'ASSET',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'SKU / ID',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'CATEGORY',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                const SizedBox(width: 120, child: Text('ACTIONS', textAlign: TextAlign.right)),
              ],
            ),
          ),
          Column(
            children: products.map((product) => _HighDensityProductRow(
              product: product,
              onViewDetails: () => context.read<ProductCubit>().setSubView('details', product),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _ProductCatalogMobileGrid extends StatelessWidget {
  const _ProductCatalogMobileGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (products.isEmpty) {
      return const _EmptyCatalogState();
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
                                  image: getImageProvider(product.imageUrl!),
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
                      onPressed: () => context.read<ProductCubit>().setSubView('details', product),
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

class _EmptyCatalogState extends StatelessWidget {
  const _EmptyCatalogState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 64),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search query or filter category.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HighDensityProductRow extends StatefulWidget {
  const _HighDensityProductRow({
    required this.product,
    required this.onViewDetails,
  });

  final Product product;
  final VoidCallback onViewDetails;

  @override
  State<_HighDensityProductRow> createState() => _HighDensityProductRowState();
}

class _HighDensityProductRowState extends State<_HighDensityProductRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bp = ResponsiveBreakpoints.of(context);
    final enableHoverEffects = !bp.isMobile && !bp.isTablet;

    final rowBgColor = _isHovered
        ? colorScheme.containerLow
        : colorScheme.containerLowest;

    return MouseRegion(
      onEnter: (_) {
        if (enableHoverEffects) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (enableHoverEffects) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: rowBgColor,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.container,
                image: widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: getImageProvider(widget.product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.product.imageUrl == null || widget.product.imageUrl!.isEmpty
                  ? Icon(Icons.inventory_2_outlined, size: 16, color: colorScheme.primary)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.product.storageConditions ?? 'Standard Specs',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.product.sku,
                style: textTheme.labelMedium?.copyWith(
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    ),
                    child: Text(
                      widget.product.category ?? 'N/A',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 120,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onViewDetails,
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      color: colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _ProductFormView extends StatefulWidget {
  const _ProductFormView({
    required this.onBack,
    required this.onSave,
    this.product,
  });

  final Product? product;
  final VoidCallback onBack;
  final ValueChanged<Product> onSave;

  @override
  State<_ProductFormView> createState() => _ProductFormViewState();
}

class _ProductFormViewState extends State<_ProductFormView> {
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

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageUrlController.text = image.path;
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
      assignedStation: widget.product?.assignedStation ?? 'Station #01',
      stationStatus: widget.product?.stationStatus ?? StationStatus.online,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

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
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final name = _ingNameController.text;
                    final pct = double.tryParse(_ingPercentController.text) ?? 0;
                    if (name.isNotEmpty && pct > 0) {
                      setState(() {
                        _ingredients.add(Ingredient(name: name, percentage: pct));
                        _ingNameController.clear();
                        _ingPercentController.clear();
                      });
                    }
                  },
                  child: const Text('Add'),
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
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
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
                  },
                  child: const Text('Add'),
                ),
              ],
            ),
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



class _ProductDetailView extends StatelessWidget {
  const _ProductDetailView({
    required this.product,
    required this.onBack,
    required this.onEdit,
    required this.onDelete,
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
                        image: getImageProvider(product.imageUrl!),
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
                        Text('Oct 24, 2023', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ],
            );

            final actionButtons = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => onEdit(product),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit Product'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => onDelete(product.id),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Delete Product'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(color: colorScheme.error),
                  ),
                ),
              ],
            );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  imgWidget,
                  const SizedBox(height: 20),
                  infoWidget,
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  actionButtons,
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
                SizedBox(width: 180, child: actionButtons),
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
            if (product.category == 'Dry Goods' || product.category == 'Produce') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Sensitive to high humidity',
                    style: textTheme.bodySmall?.copyWith(color: Colors.orange.shade800),
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
