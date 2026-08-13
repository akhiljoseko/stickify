import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stickify/domain/domain.dart';

/// A self-contained tile widget for displaying a [ProductVariant] in the order batch wizard,
/// featuring inline quantity input with local validation, keyboard navigation, and an edit action.
class VariantInlineQuantityTile extends StatefulWidget {
  /// Creates a [VariantInlineQuantityTile].
  const VariantInlineQuantityTile({
    required this.product,
    required this.variant,
    required this.onAdd,
    required this.onEdit,
    this.currentAddedQuantity = 0,
    this.isHighlighted = false,
    this.qtyFocusNode,
    this.onSubmitted,
    this.onCancel,
    super.key,
  });

  /// The parent product.
  final Product product;

  /// The variant being displayed.
  final ProductVariant variant;

  /// Callback when user adds a valid quantity to the order batch.
  final void Function(int quantity) onAdd;

  /// Callback when user clicks edit variant.
  final VoidCallback onEdit;

  /// Currently added quantity in batch (if any).
  final int currentAddedQuantity;

  /// Whether this variant tile is currently highlighted by keyboard navigation.
  final bool isHighlighted;

  /// Optional focus node for the inline quantity text field.
  final FocusNode? qtyFocusNode;

  /// Callback when quantity is submitted via Enter key.
  final VoidCallback? onSubmitted;

  /// Callback when quantity input is cancelled via Escape or Left Arrow.
  final VoidCallback? onCancel;

  @override
  State<VariantInlineQuantityTile> createState() => _VariantInlineQuantityTileState();
}

class _VariantInlineQuantityTileState extends State<VariantInlineQuantityTile> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '0');
    _controller.addListener(_onTextChanged);
    widget.qtyFocusNode?.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(covariant VariantInlineQuantityTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qtyFocusNode != widget.qtyFocusNode) {
      oldWidget.qtyFocusNode?.removeListener(_onFocusChange);
      widget.qtyFocusNode?.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    widget.qtyFocusNode?.removeListener(_onFocusChange);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (widget.qtyFocusNode?.hasFocus == true) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  int get _parsedQuantity => int.tryParse(_controller.text.trim()) ?? 0;
  bool get _isValidQuantity => _parsedQuantity >= 1;

  void _handleAdd() {
    if (!_isValidQuantity) return;
    final qty = _parsedQuantity;
    widget.onAdd(qty);
    _controller.text = '0';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isAdded = widget.currentAddedQuantity > 0;
    final isHighlighted = widget.isHighlighted;

    final backgroundColor = isHighlighted
        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
        : (isAdded ? colorScheme.primaryContainer.withValues(alpha: 0.12) : null);

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          left: BorderSide(
            color: isHighlighted ? colorScheme.primary : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Left: Variant details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.variant.name,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isHighlighted ? colorScheme.primary : colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Quantity: ${widget.variant.quantity} ${widget.variant.unit} | MRP: ₹${widget.variant.mrp}',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isAdded) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.currentAddedQuantity} in order batch',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Right: Inline quantity text field, Add button, Edit button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 75,
                child: KeyboardListener(
                  focusNode: FocusNode(),
                  onKeyEvent: (event) {
                    if (event is KeyDownEvent) {
                      if (event.logicalKey == LogicalKeyboardKey.escape ||
                          event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        widget.qtyFocusNode?.unfocus();
                        widget.onCancel?.call();
                      }
                    }
                  },
                  child: TextField(
                    controller: _controller,
                    focusNode: widget.qtyFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    onSubmitted: (_) {
                      if (_isValidQuantity) {
                        _handleAdd();
                      }
                      widget.onSubmitted?.call();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _isValidQuantity
                    ? () {
                        _handleAdd();
                        widget.onSubmitted?.call();
                      }
                    : null,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                tooltip: 'Edit Variant Details',
                onPressed: widget.onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
