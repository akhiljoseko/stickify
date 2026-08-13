import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';

/// Represents a product variant and its quantity designated for printing.
///
/// Combines the parent [Product], the specific [ProductVariant], and the
/// target print [quantity] into a single unit consumed by the printing engine.
class PrintableItem extends Equatable {
  /// Creates a [PrintableItem] instance.
  const PrintableItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  /// The parent product.
  final Product product;

  /// The specific variant of the product to print.
  final ProductVariant variant;

  /// Number of labels to print for this item.
  final int quantity;

  /// Creates a copy of this [PrintableItem] with updated fields.
  PrintableItem copyWith({
    Product? product,
    ProductVariant? variant,
    int? quantity,
  }) {
    return PrintableItem(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, variant, quantity];
}
