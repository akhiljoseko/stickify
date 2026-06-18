import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/hive/variant_print_stats_hive_model.dart';
import 'package:stickify/domain/domain.dart';

class DatabaseVariantPrintStatsRepository implements VariantPrintStatsRepository {
  DatabaseVariantPrintStatsRepository({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'variant_print_stats';

  @override
  Future<Result<void, AppError>> incrementCount({
    required String variantSku,
    required String productId,
    required String productName,
    required String variantName,
    required int labelCount,
    required DateTime printedAt,
  }) async {
    try {
      final existing = await _db.get<VariantPrintStatsHiveModel>(_collection, variantSku);
      if (existing != null) {
        final updated = VariantPrintStatsHiveModel(
          variantSku: existing.variantSku,
          productId: existing.productId,
          productName: existing.productName,
          variantName: existing.variantName,
          totalPrints: existing.totalPrints + labelCount,
          lastPrintedAt: printedAt,
        );
        await _db.save(_collection, variantSku, updated);
      } else {
        final created = VariantPrintStatsHiveModel(
          variantSku: variantSku,
          productId: productId,
          productName: productName,
          variantName: variantName,
          totalPrints: labelCount,
          lastPrintedAt: printedAt,
        );
        await _db.save(_collection, variantSku, created);
      }
      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to increment variant print stats.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }

  @override
  Future<Result<List<VariantPrintStats>, AppError>> getTopFrequent({int limit = 15}) async {
    try {
      final allModels = await _db.getAll<VariantPrintStatsHiveModel>(_collection);
      final list = allModels.map((m) => m.toDomain()).toList()
        ..sort((a, b) => b.totalPrints.compareTo(a.totalPrints));
      return Result.success(list.take(limit).toList());
    } catch (e, s) {
      return Result.failure(
        DatabaseError(
          message: 'Failed to fetch top frequent variant stats.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
