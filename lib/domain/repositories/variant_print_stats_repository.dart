import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/variant_print_stats.dart';

abstract interface class VariantPrintStatsRepository {
  Future<Result<void, AppError>> incrementCount({
    required String variantSku,
    required String productId,
    required String productName,
    required String variantName,
    required int labelCount,
    required DateTime printedAt,
    String? imageUrl,
  });

  Future<Result<List<VariantPrintStats>, AppError>> getTopFrequent({int limit = 15});
}
