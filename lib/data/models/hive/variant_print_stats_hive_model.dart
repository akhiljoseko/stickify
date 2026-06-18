import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

class VariantPrintStatsHiveModel extends HiveObject {
  VariantPrintStatsHiveModel({
    required this.variantSku,
    required this.productId,
    required this.productName,
    required this.variantName,
    required this.totalPrints,
    required this.lastPrintedAt,
  });

  factory VariantPrintStatsHiveModel.fromDomain(VariantPrintStats s) {
    return VariantPrintStatsHiveModel(
      variantSku: s.variantSku,
      productId: s.productId,
      productName: s.productName,
      variantName: s.variantName,
      totalPrints: s.totalPrints,
      lastPrintedAt: s.lastPrintedAt,
    );
  }

  final String variantSku;
  final String productId;
  final String productName;
  final String variantName;
  final int totalPrints;
  final DateTime lastPrintedAt;

  VariantPrintStats toDomain() {
    return VariantPrintStats(
      variantSku: variantSku,
      productId: productId,
      productName: productName,
      variantName: variantName,
      totalPrints: totalPrints,
      lastPrintedAt: lastPrintedAt,
    );
  }
}
