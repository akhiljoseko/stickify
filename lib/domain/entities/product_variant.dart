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
    this.defaultTemplateId,
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

  /// Optional default template ID for quick-print.
  final String? defaultTemplateId;

  /// Price per single unit, auto-calculated as [mrp] / [quantity].
  double get unitPrice => quantity > 0 ? mrp / quantity : 0;

  ProductVariant copyWith({
    String? name,
    double? quantity,
    String? unit,
    double? wholesale,
    double? mrp,
    String? sku,
    String? defaultTemplateId,
  }) {
    return ProductVariant(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      wholesale: wholesale ?? this.wholesale,
      mrp: mrp ?? this.mrp,
      sku: sku ?? this.sku,
      defaultTemplateId: defaultTemplateId ?? this.defaultTemplateId,
    );
  }

  @override
  List<Object?> get props => [
        name,
        quantity,
        unit,
        wholesale,
        mrp,
        sku,
        defaultTemplateId,
      ];
}
