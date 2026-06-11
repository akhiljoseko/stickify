import 'package:equatable/equatable.dart';

/// Represents a specific variant of a product.
///
/// Contains details about size/packaging, quantity, pricing (wholesale, MRP), and SKU.
class ProductVariant extends Equatable {
  /// Creates a [ProductVariant] instance.
  const ProductVariant({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.wholesale,
    required this.mrp,
    required this.sku,
  });

  /// Name of the variant, e.g. '150g Pouch'.
  final String name;

  /// Numeric quantity for this variant.
  final double quantity;

  /// Unit of measurement, e.g., 'ml', 'gm', 'kg', 'L', 'pcs'.
  final String unit;

  /// Wholesale price for this variant.
  final double wholesale;

  /// Maximum Retail Price (MRP) for this variant.
  final double mrp;

  /// Unique Stock Keeping Unit (SKU) identifying this variant.
  final String sku;

  @override
  List<Object?> get props => [
        name,
        quantity,
        unit,
        wholesale,
        mrp,
        sku,
      ];
}
