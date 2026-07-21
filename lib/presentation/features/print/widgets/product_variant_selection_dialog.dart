import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/product/presentation/shared/edit_variant_dialog.dart';

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
  State<ProductVariantSelectionDialog> createState() =>
      _ProductVariantSelectionDialogState();
}

class _ProductVariantSelectionDialogState
    extends State<ProductVariantSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _productScrollController = ScrollController();
  final ScrollController _variantScrollController = ScrollController();
  final FocusNode _dialogFocusNode = FocusNode();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  Product? _selectedProduct;
  bool _isLoading = true;
  int _highlightedIndex = 0;
  double _savedProductScrollOffset = 0;
  int _savedProductHighlightedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _dialogFocusNode.dispose();
    _productScrollController.dispose();
    _variantScrollController.dispose();
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
              final sortedProducts = List<Product>.from(products)
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );
              _allProducts = sortedProducts;
              _filteredProducts = sortedProducts;
            case Failure():
              _allProducts = [];
              _filteredProducts = [];
          }
          _isLoading = false;
          _highlightedIndex = 0;
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
        return p.name.toLowerCase().contains(query) ||
            p.sku.toLowerCase().contains(query) ||
            p.keywords.any((k) => k.toLowerCase().contains(query));
      }).toList();
      _highlightedIndex = 0;
    });
  }

  List<ProductVariant> _getSortedVariants() {
    if (_selectedProduct == null) return [];
    return _selectedProduct!.sortedVariants;
  }

  void _editVariant(ProductVariant variant) {
    EditVariantDialog.show(
      context,
      product: _selectedProduct!,
      variant: variant,
      onSave: (updatedVariant) async {
        final updatedVariants = _selectedProduct!.variants.map((v) {
          return v.sku == variant.sku ? updatedVariant : v;
        }).toList();

        final updatedProduct = Product(
          id: _selectedProduct!.id,
          name: _selectedProduct!.name,
          sku: _selectedProduct!.sku,
          category: _selectedProduct!.category,
          shelfLifeDays: _selectedProduct!.shelfLifeDays,
          storageConditions: _selectedProduct!.storageConditions,
          imageUrl: _selectedProduct!.imageUrl,
          ingredients: _selectedProduct!.ingredients,
          nutritionFacts: _selectedProduct!.nutritionFacts,
          variants: List.unmodifiable(updatedVariants),
          lastModified: DateTime.now(),
        );

        final repo = context.read<ProductRepository>();
        final saveResult = await repo.saveProduct(updatedProduct);
        if (saveResult is Success) {
          await _loadProducts();
          if (mounted) {
            setState(() {
              _selectedProduct = _allProducts.firstWhere(
                (p) => p.id == updatedProduct.id,
                orElse: () => updatedProduct,
              );
            });
          }
        }
      },
    );
  }

  void _handleCtrlS() {
    if (_selectedProduct != null) {
      setState(() {
        _selectedProduct = null;
        _highlightedIndex = _savedProductHighlightedIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
        if (_productScrollController.hasClients) {
          _productScrollController.jumpTo(_savedProductScrollOffset);
        }
      });
    } else {
      _searchFocusNode.requestFocus();
      _searchController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _searchController.text.length,
      );
    }
  }

  void _handleArrowDown() {
    if (_selectedProduct == null) {
      if (_filteredProducts.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1).clamp(
            0,
            _filteredProducts.length - 1,
          );
        });
        _scrollToHighlightedIndex();
      }
    } else {
      final variants = _getSortedVariants();
      if (variants.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex + 1).clamp(
            0,
            variants.length - 1,
          );
        });
        _scrollToHighlightedIndex();
      }
    }
  }

  void _handleArrowUp() {
    if (_selectedProduct == null) {
      if (_filteredProducts.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1).clamp(
            0,
            _filteredProducts.length - 1,
          );
        });
        _scrollToHighlightedIndex();
      }
    } else {
      final variants = _getSortedVariants();
      if (variants.isNotEmpty) {
        setState(() {
          _highlightedIndex = (_highlightedIndex - 1).clamp(
            0,
            variants.length - 1,
          );
        });
        _scrollToHighlightedIndex();
      }
    }
  }

  void _handleEnter() {
    if (_selectedProduct == null) {
      if (_filteredProducts.isNotEmpty &&
          _highlightedIndex >= 0 &&
          _highlightedIndex < _filteredProducts.length) {
        setState(() {
          _savedProductScrollOffset = _productScrollController.hasClients
              ? _productScrollController.offset
              : 0.0;
          _savedProductHighlightedIndex = _highlightedIndex;
          _selectedProduct = _filteredProducts[_highlightedIndex];
          _highlightedIndex = 0;
        });
        _dialogFocusNode.requestFocus();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_variantScrollController.hasClients) {
            _variantScrollController.jumpTo(0);
          }
        });
      }
    } else {
      final variants = _getSortedVariants();
      if (variants.isNotEmpty &&
          _highlightedIndex >= 0 &&
          _highlightedIndex < variants.length) {
        final v = variants[_highlightedIndex];
        PrintTemplateSelectRoute(
          productId: _selectedProduct!.id,
          variantSku: v.sku,
        ).push<void>(context);
        setState(() {
          _selectedProduct = null;
          _highlightedIndex = 0;
        });
      }
    }
  }

  void _handleBackspace() {
    if (_selectedProduct != null) {
      setState(() {
        _selectedProduct = null;
        _highlightedIndex = _savedProductHighlightedIndex;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _searchFocusNode.requestFocus();
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
        if (_productScrollController.hasClients) {
          _productScrollController.jumpTo(_savedProductScrollOffset);
        }
      });
    }
  }

  void _scrollToHighlightedIndex() {
    final controller = _selectedProduct == null
        ? _productScrollController
        : _variantScrollController;
    if (!controller.hasClients) return;

    const itemHeight = 72;
    final targetOffset = _highlightedIndex * itemHeight;
    final viewportHeight = controller.position.viewportDimension;
    final currentScroll = controller.offset;

    if (targetOffset + itemHeight > currentScroll + viewportHeight) {
      controller.animateTo(
        targetOffset + itemHeight - viewportHeight,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    } else if (targetOffset < currentScroll) {
      controller.animateTo(
        targetOffset.toDouble(),
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Focus(
        focusNode: _dialogFocusNode,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            final key = event.logicalKey;
            final isCtrl =
                HardwareKeyboard.instance.isControlPressed ||
                HardwareKeyboard.instance.isMetaPressed;

            if (isCtrl && key == LogicalKeyboardKey.keyS) {
              _handleCtrlS();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.arrowDown) {
              _handleArrowDown();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.arrowUp) {
              _handleArrowUp();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter) {
              _handleEnter();
              return KeyEventResult.handled;
            }

            if (key == LogicalKeyboardKey.backspace) {
              if (_selectedProduct != null) {
                _handleBackspace();
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
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
                            _selectedProduct == null
                                ? 'Select Product'
                                : 'Select Variant',
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
                          focusNode: _searchFocusNode,
                          autofocus: true,
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
                                  controller: _productScrollController,
                                  itemCount: _filteredProducts.length,
                                  separatorBuilder: (context, index) => Divider(
                                    height: 1,
                                    color: colorScheme.outlineVariant,
                                  ),
                                  itemBuilder: (context, i) {
                                    final p = _filteredProducts[i];
                                    final isHighlighted =
                                        i == _highlightedIndex;
                                    return ListTile(
                                      selected: isHighlighted,
                                      selectedTileColor: colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.2),
                                      title: Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        p.sku,
                                        style: const TextStyle(
                                          fontFamily: 'JetBrains Mono',
                                        ),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        setState(() {
                                          _savedProductScrollOffset = _productScrollController.hasClients
                                              ? _productScrollController.offset
                                              : 0.0;
                                          _savedProductHighlightedIndex = i;
                                          _selectedProduct = p;
                                          _highlightedIndex = 0;
                                        });
                                        _dialogFocusNode.requestFocus();
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              if (_variantScrollController
                                                  .hasClients) {
                                                _variantScrollController.jumpTo(
                                                  0,
                                                );
                                              }
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
                              _highlightedIndex = _savedProductHighlightedIndex;
                            });
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _searchFocusNode.requestFocus();
                              _searchController.selection = TextSelection(
                                baseOffset: 0,
                                extentOffset: _searchController.text.length,
                              );
                              if (_productScrollController.hasClients) {
                                _productScrollController.jumpTo(_savedProductScrollOffset);
                              }
                            });
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back to Products'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _selectedProduct!.name,
                          style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _selectedProduct!.sku,
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'JetBrains Mono',
                          ),
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
                              : () {
                                  final sortedVariants = _getSortedVariants();
                                  return ListView.separated(
                                    controller: _variantScrollController,
                                    itemCount: sortedVariants.length,
                                    separatorBuilder: (context, index) =>
                                        Divider(
                                          height: 1,
                                          color: colorScheme.outlineVariant,
                                        ),
                                    itemBuilder: (context, i) {
                                      final v = sortedVariants[i];
                                      final isHighlighted =
                                          i == _highlightedIndex;
                                      return ListTile(
                                        selected: isHighlighted,
                                        selectedTileColor: colorScheme
                                            .primaryContainer
                                            .withValues(alpha: 0.2),
                                        title: Text(
                                          v.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          '${v.quantity} ${v.unit} | MRP: ₹${v.mrp.toStringAsFixed(2)}',
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              key: ValueKey('edit_variant_${v.sku}'),
                                              icon: const Icon(Icons.edit_outlined),
                                              onPressed: () => _editVariant(v),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.print_outlined),
                                          ],
                                        ),
                                        onTap: () {
                                          PrintTemplateSelectRoute(
                                            productId: _selectedProduct!.id,
                                            variantSku: v.sku,
                                          ).push<void>(context);
                                          setState(() {
                                            _selectedProduct = null;
                                            _highlightedIndex = 0;
                                          });
                                        },
                                      );
                                    },
                                  );
                                }(),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
