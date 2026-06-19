import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// A popup modal dialog for searching products and selecting a specific [ProductVariant] to print.
class ProductVariantSelectionDialog extends StatefulWidget {
  /// Creates a [ProductVariantSelectionDialog] instance.
  const ProductVariantSelectionDialog({super.key});

  /// Displays the variant selection dialog over [context].
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (context) => const ProductVariantSelectionDialog(),
    );
  }

  @override
  State<ProductVariantSelectionDialog> createState() => _ProductVariantSelectionDialogState();
}

class _ProductVariantSelectionDialogState extends State<ProductVariantSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final repo = context.read<ProductRepository>();
      final result = await repo.getAllProducts();
      if (mounted) {
        setState(() {
          switch (result) {
            case Success(value: final products):
              _allProducts = products;
              _filteredProducts = products;
            case Failure():
              _allProducts = [];
              _filteredProducts = [];
          }
          _isLoading = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((p) {
        return p.name.toLowerCase().contains(query) || p.sku.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedProduct == null ? 'Select Product' : 'Select Variant',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedProduct == null) ...[
                      // Search field
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Search product name or SKU prefix...',
                          fillColor: colorScheme.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Product List
                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? Center(
                                child: Text(
                                  'No products found.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _filteredProducts.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: colorScheme.outlineVariant,
                                ),
                                itemBuilder: (context, i) {
                                  final p = _filteredProducts[i];
                                  return ListTile(
                                    title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(p.sku, style: const TextStyle(fontFamily: 'JetBrains Mono')),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {
                                      setState(() {
                                        _selectedProduct = p;
                                      });
                                    },
                                  );
                                },
                              ),
                      ),
                    ] else ...[
                      // Back to products selection
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedProduct = null;
                          });
                        },
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back to Products'),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _selectedProduct!.name,
                        style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _selectedProduct!.sku,
                        style: textTheme.bodySmall?.copyWith(fontFamily: 'JetBrains Mono'),
                      ),
                      const SizedBox(height: 20),
                      // Variant selection
                      Expanded(
                        child: _selectedProduct!.variants.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'No variants configured for this product.',
                                      style: textTheme.bodyMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        context.go('/products');
                                      },
                                      child: const Text('Go to Products'),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                itemCount: _selectedProduct!.variants.length,
                                separatorBuilder: (context, index) => Divider(
                                  height: 1,
                                  color: colorScheme.outlineVariant,
                                ),
                                itemBuilder: (context, i) {
                                  final v = _selectedProduct!.variants[i];
                                  return ListTile(
                                    title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text('${v.quantity} ${v.unit} | MRP: ₹${v.mrp.toStringAsFixed(2)}'),
                                    trailing: const Icon(Icons.print_outlined),
                                    onTap: () {
                                      Navigator.pop(context);
                                      PrintTemplateSelectRoute(
                                        productId: _selectedProduct!.id,
                                        variantSku: v.sku,
                                      ).push<void>(context);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
