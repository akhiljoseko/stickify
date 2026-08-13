import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stickify/domain/domain.dart';

/// A self-contained tile widget for displaying a [ProductVariant] in the order batch wizard,
/// featuring inline quantity input with local validation and an edit action.
class VariantInlineQuantityTile extends StatefulWidget {
  /// Creates a [VariantInlineQuantityTile].
  const VariantInlineQuantityTile({
    required this.product,
    required this.variant,
    required this.onAdd,
    required this.onEdit,
    this.currentAddedQuantity = 0,
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
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
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

    return Container(
      decoration: BoxDecoration(
        color: isAdded ? colorScheme.primaryContainer.withValues(alpha: 0.15) : null,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5)),
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
                child: TextField(
                  controller: _controller,
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
                  onSubmitted: (_) => _handleAdd(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: _isValidQuantity ? _handleAdd : null,
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
