import 'package:equatable/equatable.dart';

class VariantPrintStats extends Equatable {
  const VariantPrintStats({
    required this.variantSku,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.totalPrints,
    required this.lastPrintedAt,
  });

  final String variantSku;
  final String productId;
  final String productName;
  final String variantName;
  final int totalPrints;
  final DateTime lastPrintedAt;

  @override
  List<Object?> get props => [
        variantSku,
        productId,
        productName,
        variantName,
        totalPrints,
        lastPrintedAt,
      ];

  VariantPrintStats copyWith({
    String? variantSku,
    String? productId,
    String? productName,
    String? variantName,
    int? totalPrints,
    DateTime? lastPrintedAt,
  }) {
    return VariantPrintStats(
      variantSku: variantSku ?? this.variantSku,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      totalPrints: totalPrints ?? this.totalPrints,
      lastPrintedAt: lastPrintedAt ?? this.lastPrintedAt,
    );
  }
}
