import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_cubit.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';
import 'package:stickify/presentation/features/order_label_print/presentation/widgets/variant_inline_quantity_tile.dart';
import 'package:stickify/presentation/features/product/presentation/shared/edit_variant_dialog.dart';

/// Step 2: Variant & Quantity Selection View (2-column layout on Desktop with 3-Level Hierarchical Keyboard Navigation)
class StepVariantSelectionView extends StatefulWidget {
  /// Creates a [StepVariantSelectionView].
  const StepVariantSelectionView({super.key});

  @override
  State<StepVariantSelectionView> createState() => _StepVariantSelectionViewState();
}

class _StepVariantSelectionViewState extends State<StepVariantSelectionView> {
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _qtyFocusNode = FocusNode();

  int _currentLevel = 1; // 0: Search, 1: Product List, 2: Variant List, 3: Qty Field
  int _highlightedProductIndex = 0;
  int _highlightedVariantIndex = 0;
  final Set<String> _expandedProductIds = {};

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _qtyFocusNode.dispose();
    super.dispose();
  }

  void _onSearchFocusChange() {
    if (_searchFocusNode.hasFocus) {
      setState(() {
        _currentLevel = 0;
      });
    }
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final state = context.read<OrderLabelPrintCubit>().state;
    final products = state.filteredProducts;
    final key = event.logicalKey;
    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isAlt = HardwareKeyboard.instance.isAltPressed;

    // GLOBAL SEARCH SHORTCUT (Any Level): Ctrl + F / Ctrl + S / Slash
    if ((isCtrl && (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.keyS)) ||
        (key == LogicalKeyboardKey.slash && _currentLevel != 0 && _currentLevel != 3)) {
      _handleFocusSearch();
      return true;
    }

    // GLOBAL PROCEED SHORTCUT (Any Level): Ctrl + Enter / Alt + Enter
    if ((isCtrl || isAlt) &&
        (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter)) {
      _handleProceedToPrint();
      return true;
    }

    if (products.isEmpty) return false;
    _highlightedProductIndex = _highlightedProductIndex.clamp(0, products.length - 1);
    final activeProduct = products[_highlightedProductIndex];
    final variants = activeProduct.variants;

    // LEVEL 0: SEARCH BAR
    if (_currentLevel == 0) {
      if (key == LogicalKeyboardKey.arrowDown ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter) {
        _searchFocusNode.unfocus();
        setState(() {
          _currentLevel = 1;
        });
        return true;
      }
      return false;
    }

    // LEVEL 1: PRODUCT LIST NAVIGATION
    if (_currentLevel == 1) {
      if (key == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _highlightedProductIndex = (_highlightedProductIndex + 1).clamp(0, products.length - 1);
        });
        _scrollToHighlightedIndex();
        return true;
      }

      if (key == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _highlightedProductIndex = (_highlightedProductIndex - 1).clamp(0, products.length - 1);
        });
        _scrollToHighlightedIndex();
        return true;
      }

      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.arrowRight) {
        setState(() {
          _expandedProductIds.add(activeProduct.id);
          _currentLevel = 2;
          _highlightedVariantIndex = 0;
        });
        return true;
      }

      if (key == LogicalKeyboardKey.escape && state.searchQuery.isNotEmpty) {
        context.read<OrderLabelPrintCubit>().updateSearchQuery('');
        return true;
      }
    }

    // LEVEL 2: VARIANT LIST NAVIGATION (Inside Expanded Product)
    if (_currentLevel == 2) {
      if (key == LogicalKeyboardKey.arrowDown) {
        if (variants.isNotEmpty) {
          setState(() {
            _highlightedVariantIndex = (_highlightedVariantIndex + 1).clamp(0, variants.length - 1);
          });
        }
        return true;
      }

      if (key == LogicalKeyboardKey.arrowUp) {
        if (variants.isNotEmpty) {
          setState(() {
            _highlightedVariantIndex = (_highlightedVariantIndex - 1).clamp(0, variants.length - 1);
          });
        }
        return true;
      }

      if (key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter ||
          key == LogicalKeyboardKey.arrowRight) {
        if (variants.isNotEmpty) {
          setState(() {
            _currentLevel = 3;
          });
          _qtyFocusNode.requestFocus();
        }
        return true;
      }

      // Left Arrow / Escape / Backspace: Collapse product and return to Level 1 Product List
      if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.escape ||
          key == LogicalKeyboardKey.backspace) {
        setState(() {
          _expandedProductIds.remove(activeProduct.id);
          _currentLevel = 1;
        });
        return true;
      }
    }

    // LEVEL 3: QUANTITY FIELD INPUT
    if (_currentLevel == 3) {
      if (key == LogicalKeyboardKey.escape) {
        _qtyFocusNode.unfocus();
        setState(() {
          _currentLevel = 2;
        });
        return true;
      }
    }

    return false;
  }

  void _scrollToHighlightedIndex() {
    if (!_scrollController.hasClients) return;
    const itemEstimateHeight = 76.0;
    final targetOffset = _highlightedProductIndex * itemEstimateHeight;
    final viewportHeight = _scrollController.position.viewportDimension;
    final currentScroll = _scrollController.offset;

    if (targetOffset + itemEstimateHeight > currentScroll + viewportHeight) {
      _scrollController.animateTo(
        targetOffset + itemEstimateHeight - viewportHeight,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    } else if (targetOffset < currentScroll) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleFocusSearch() {
    _searchFocusNode.requestFocus();
    setState(() {
      _currentLevel = 0;
    });
  }

  void _handleProceedToPrint() {
    final cubit = context.read<OrderLabelPrintCubit>();
    if (cubit.state.items.isNotEmpty) {
      cubit.goToNextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.of(context).isMobile;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (_highlightedProductIndex >= state.filteredProducts.length && state.filteredProducts.isNotEmpty) {
          _highlightedProductIndex = 0;
        }

        if (isMobile) {
          return _MobileVariantSelectionLayout(
            searchFocusNode: _searchFocusNode,
            scrollController: _scrollController,
            qtyFocusNode: _qtyFocusNode,
            currentLevel: _currentLevel,
            highlightedProductIndex: _highlightedProductIndex,
            highlightedVariantIndex: _highlightedVariantIndex,
            expandedProductIds: _expandedProductIds,
            onProductTap: (index, productId) {
              setState(() {
                _highlightedProductIndex = index;
                if (_expandedProductIds.contains(productId)) {
                  _expandedProductIds.remove(productId);
                  _currentLevel = 1;
                } else {
                  _expandedProductIds.add(productId);
                  _currentLevel = 2;
                  _highlightedVariantIndex = 0;
                }
              });
            },
            onVariantTap: (variantIndex) {
              setState(() {
                _highlightedVariantIndex = variantIndex;
                _currentLevel = 3;
              });
              _qtyFocusNode.requestFocus();
            },
            onQtySubmitted: () {
              setState(() {
                _currentLevel = 2;
              });
            },
            onQtyCancel: () {
              setState(() {
                _currentLevel = 2;
              });
            },
          );
        }

        return _DesktopVariantSelectionLayout(
          searchFocusNode: _searchFocusNode,
          scrollController: _scrollController,
          qtyFocusNode: _qtyFocusNode,
          currentLevel: _currentLevel,
          highlightedProductIndex: _highlightedProductIndex,
          highlightedVariantIndex: _highlightedVariantIndex,
          expandedProductIds: _expandedProductIds,
          onProductTap: (index, productId) {
            setState(() {
              _highlightedProductIndex = index;
              if (_expandedProductIds.contains(productId)) {
                _expandedProductIds.remove(productId);
                _currentLevel = 1;
              } else {
                _expandedProductIds.add(productId);
                _currentLevel = 2;
                _highlightedVariantIndex = 0;
              }
            });
          },
          onVariantTap: (variantIndex) {
            setState(() {
              _highlightedVariantIndex = variantIndex;
              _currentLevel = 3;
            });
            _qtyFocusNode.requestFocus();
          },
          onQtySubmitted: () {
            setState(() {
              _currentLevel = 2;
            });
          },
          onQtyCancel: () {
            setState(() {
              _currentLevel = 2;
            });
          },
        );
      },
    );
  }
}

class _DesktopVariantSelectionLayout extends StatelessWidget {
  const _DesktopVariantSelectionLayout({
    required this.searchFocusNode,
    required this.scrollController,
    required this.qtyFocusNode,
    required this.currentLevel,
    required this.highlightedProductIndex,
    required this.highlightedVariantIndex,
    required this.expandedProductIds,
    required this.onProductTap,
    required this.onVariantTap,
    required this.onQtySubmitted,
    required this.onQtyCancel,
  });

  final FocusNode searchFocusNode;
  final ScrollController scrollController;
  final FocusNode qtyFocusNode;
  final int currentLevel;
  final int highlightedProductIndex;
  final int highlightedVariantIndex;
  final Set<String> expandedProductIds;
  final void Function(int index, String productId) onProductTap;
  final void Function(int variantIndex) onVariantTap;
  final VoidCallback onQtySubmitted;
  final VoidCallback onQtyCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Product & Variant Browser
                Expanded(
                  flex: 5,
                  child: Card(
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
                                  Icon(Icons.search, color: colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select Products & Variants',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const Wrap(
                                spacing: 6,
                                children: [
                                  _ShortcutBadge(label: 'Ctrl+F', description: 'Search'),
                                  _ShortcutBadge(label: '↑/↓', description: 'Navigate'),
                                  _ShortcutBadge(label: 'Enter / →', description: 'Select/Focus'),
                                  _ShortcutBadge(label: 'Esc / ←', description: 'Collapse/Back'),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _ProductSearchBar(focusNode: searchFocusNode),
                          const SizedBox(height: 12),
                          Expanded(
                            child: _ProductBrowserList(
                              scrollController: scrollController,
                              qtyFocusNode: qtyFocusNode,
                              currentLevel: currentLevel,
                              highlightedProductIndex: highlightedProductIndex,
                              highlightedVariantIndex: highlightedVariantIndex,
                              expandedProductIds: expandedProductIds,
                              onProductTap: onProductTap,
                              onVariantTap: onVariantTap,
                              onQtySubmitted: onQtySubmitted,
                              onQtyCancel: onQtyCancel,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right Panel: Running Order Batch
                Expanded(
                  flex: 4,
                  child: Card(
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _RunningBatchHeader(),
                          const SizedBox(height: 12),
                          const Expanded(child: _RunningBatchList()),
                          const SizedBox(height: 16),
                          const _Step2ActionButtons(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileVariantSelectionLayout extends StatelessWidget {
  const _MobileVariantSelectionLayout({
    required this.searchFocusNode,
    required this.scrollController,
    required this.qtyFocusNode,
    required this.currentLevel,
    required this.highlightedProductIndex,
    required this.highlightedVariantIndex,
    required this.expandedProductIds,
    required this.onProductTap,
    required this.onVariantTap,
    required this.onQtySubmitted,
    required this.onQtyCancel,
  });

  final FocusNode searchFocusNode;
  final ScrollController scrollController;
  final FocusNode qtyFocusNode;
  final int currentLevel;
  final int highlightedProductIndex;
  final int highlightedVariantIndex;
  final Set<String> expandedProductIds;
  final void Function(int index, String productId) onProductTap;
  final void Function(int variantIndex) onVariantTap;
  final VoidCallback onQtySubmitted;
  final VoidCallback onQtyCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _ProductSearchBar(focusNode: searchFocusNode),
          const SizedBox(height: 12),
          Expanded(
            child: _ProductBrowserList(
              scrollController: scrollController,
              qtyFocusNode: qtyFocusNode,
              currentLevel: currentLevel,
              highlightedProductIndex: highlightedProductIndex,
              highlightedVariantIndex: highlightedVariantIndex,
              expandedProductIds: expandedProductIds,
              onProductTap: onProductTap,
              onVariantTap: onVariantTap,
              onQtySubmitted: onQtySubmitted,
              onQtyCancel: onQtyCancel,
            ),
          ),
          const SizedBox(height: 12),
          const _RunningBatchHeader(),
          const SizedBox(height: 12),
          const _Step2ActionButtons(),
        ],
      ),
    );
  }
}

class _ShortcutBadge extends StatelessWidget {
  const _ShortcutBadge({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductSearchBar extends StatefulWidget {
  const _ProductSearchBar({required this.focusNode});

  final FocusNode focusNode;

  @override
  State<_ProductSearchBar> createState() => _ProductSearchBarState();
}

class _ProductSearchBarState extends State<_ProductSearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: context.read<OrderLabelPrintCubit>().state.searchQuery,
    );

    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      decoration: InputDecoration(
        hintText: 'Search products or SKUs... (Ctrl + F)',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  context.read<OrderLabelPrintCubit>().updateSearchQuery('');
                },
              )
            : null,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (val) {
        context.read<OrderLabelPrintCubit>().updateSearchQuery(val);
      },
    );
  }
}

class _ProductBrowserList extends StatelessWidget {
  const _ProductBrowserList({
    required this.scrollController,
    required this.qtyFocusNode,
    required this.currentLevel,
    required this.highlightedProductIndex,
    required this.highlightedVariantIndex,
    required this.expandedProductIds,
    required this.onProductTap,
    required this.onVariantTap,
    required this.onQtySubmitted,
    required this.onQtyCancel,
  });

  final ScrollController scrollController;
  final FocusNode qtyFocusNode;
  final int currentLevel;
  final int highlightedProductIndex;
  final int highlightedVariantIndex;
  final Set<String> expandedProductIds;
  final void Function(int index, String productId) onProductTap;
  final void Function(int variantIndex) onVariantTap;
  final VoidCallback onQtySubmitted;
  final VoidCallback onQtyCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (state.filteredProducts.isEmpty) {
          return Center(
            child: Text(
              state.searchQuery.isEmpty
                  ? 'No products found'
                  : 'No matching products found',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return ListView.builder(
          controller: scrollController,
          itemCount: state.filteredProducts.length,
          itemBuilder: (context, productIndex) {
            final product = state.filteredProducts[productIndex];
            final isProductHighlighted = productIndex == highlightedProductIndex && currentLevel == 1;
            final isExpanded = expandedProductIds.contains(product.id);

            final cardBorderColor = isProductHighlighted
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.5);
            final cardBackgroundColor = isProductHighlighted
                ? colorScheme.primaryContainer.withValues(alpha: 0.15)
                : colorScheme.surface;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: cardBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: cardBorderColor,
                  width: isProductHighlighted ? 2.0 : 1.0,
                ),
              ),
              child: ExpansionTile(
                key: ValueKey('expansion_${product.id}_$isExpanded'),
                initiallyExpanded: isExpanded,
                onExpansionChanged: (_) => onProductTap(productIndex, product.id),
                title: Text(
                  product.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isProductHighlighted ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  '${product.variants.length} variant(s) available',
                ),
                children: product.variants.asMap().entries.map((entry) {
                  final variantIndex = entry.key;
                  final variant = entry.value;

                  final isVariantHighlighted =
                      productIndex == highlightedProductIndex &&
                      variantIndex == highlightedVariantIndex &&
                      (currentLevel == 2 || currentLevel == 3);

                  final existingItem = state.items.firstWhere(
                    (i) =>
                        i.product.id == product.id &&
                        i.variant.sku == variant.sku,
                    orElse: () => PrintableItem(
                      product: product,
                      variant: variant,
                      quantity: 0,
                    ),
                  );

                  return InkWell(
                    onTap: () => onVariantTap(variantIndex),
                    child: VariantInlineQuantityTile(
                      product: product,
                      variant: variant,
                      currentAddedQuantity: existingItem.quantity,
                      isHighlighted: isVariantHighlighted,
                      qtyFocusNode: isVariantHighlighted ? qtyFocusNode : null,
                      onSubmitted: onQtySubmitted,
                      onCancel: onQtyCancel,
                      onAdd: (quantity) {
                        context.read<OrderLabelPrintCubit>().addOrUpdateItem(
                          product,
                          variant,
                          quantity,
                        );
                      },
                      onEdit: () {
                        _showEditVariantDialog(context, product, variant);
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditVariantDialog(
    BuildContext context,
    Product product,
    ProductVariant variant,
  ) {
    final cubit = context.read<OrderLabelPrintCubit>();
    final productRepository = context.read<ProductRepository>();

    EditVariantDialog.show(
      context,
      product: product,
      variant: variant,
      onSave: (updatedVariant) async {
        final updatedVariants = product.variants
            .map(
              (v) => v.sku == variant.sku ? updatedVariant : v,
            )
            .toList();
        final updatedProduct = product.copyWith(variants: updatedVariants);

        final result = await productRepository.saveProduct(updatedProduct);
        if (result is Success) {
          await cubit.refreshProductCatalog(
            updatedProduct,
            variant,
            updatedVariant,
          );
        }
      },
    );
  }
}

class _RunningBatchHeader extends StatelessWidget {
  const _RunningBatchHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Batch Summary',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${state.items.length} variant(s) selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
              Text(
                '${state.totalQuantity} Labels',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RunningBatchList extends StatelessWidget {
  const _RunningBatchList();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
      builder: (context, state) {
        if (state.items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.post_add, size: 48, color: colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    'No items added to batch yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Browse products on the left, enter label quantities, and click Add.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: state.items.length,
          itemBuilder: (context, index) {
            final item = state.items[index];

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item.variant.name} (${item.variant.quantity} ${item.variant.unit}) | MRP: ₹${item.variant.mrp}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 20,
                          ),
                          onPressed: () {
                            context
                                .read<OrderLabelPrintCubit>()
                                .updateItemQuantity(index, item.quantity - 1);
                          },
                        ),
                        SizedBox(
                          width: 48,
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () {
                            context
                                .read<OrderLabelPrintCubit>()
                                .updateItemQuantity(index, item.quantity + 1);
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            context.read<OrderLabelPrintCubit>().removeItem(
                              index,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _Step2ActionButtons extends StatelessWidget {
  const _Step2ActionButtons();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OrderLabelPrintCubit>();

    return FocusTraversalGroup(
      descendantsAreFocusable: false,
      child: BlocBuilder<OrderLabelPrintCubit, OrderLabelPrintState>(
        builder: (context, state) {
          return Row(
            children: [
              OutlinedButton.icon(
                focusNode: FocusNode(canRequestFocus: false),
                onPressed: () => cubit.goToPreviousStep(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  focusNode: FocusNode(canRequestFocus: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: state.items.isEmpty
                      ? null
                      : () => cubit.goToNextStep(),
                  label: const Text(
                    'Proceed to Print',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
