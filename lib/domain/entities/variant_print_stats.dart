import 'package:equatable/equatable.dart';

class VariantPrintStats extends Equatable {
  const VariantPrintStats({
    required this.variantSku,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.totalPrints,
    required this.lastPrintedAt,
    this.imageUrl,
  });

  final String variantSku;
  final String productId;
  final String productName;
  final String variantName;
  final int totalPrints;
  final DateTime lastPrintedAt;
  final String? imageUrl;

  @override
  List<Object?> get props => [
        variantSku,
        productId,
        productName,
        variantName,
        totalPrints,
        lastPrintedAt,
        imageUrl,
      ];

  VariantPrintStats copyWith({
    String? variantSku,
    String? productId,
    String? productName,
    String? variantName,
    int? totalPrints,
    DateTime? lastPrintedAt,
    String? imageUrl,
  }) {
    return VariantPrintStats(
      variantSku: variantSku ?? this.variantSku,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantName: variantName ?? this.variantName,
      totalPrints: totalPrints ?? this.totalPrints,
      lastPrintedAt: lastPrintedAt ?? this.lastPrintedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
