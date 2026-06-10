import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  const ProductVariant({
    required this.quantity,
    required this.unit,
    required this.wholesale,
    required this.mrp,
    required this.sku,
  });

  final double quantity;
  final String unit;       // e.g. ml, gm, kg, L, pcs
  final double wholesale;
  final double mrp;
  final String sku;        // variant-level SKU

  @override
  List<Object?> get props => [
        quantity,
        unit,
        wholesale,
        mrp,
        sku,
      ];
}
