import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/hive/product_hive_model.dart';
import 'package:stickify/domain/domain.dart';

/// Local storage implementation of [ProductRepository] backed by [LocalDatabase].
class DatabaseProductRepository implements ProductRepository {
  /// Creates a [DatabaseProductRepository] instance.
  DatabaseProductRepository({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'products';

  @override
  Future<Result<List<Product>, AppError>> getFrequentProducts({int limit = 20}) async {
    try {
      final allResult = await getAllProducts();
      switch (allResult) {
        case Success(value: final all):
          final list = List<Product>.from(all);
          list.sort((a, b) => b.totalPrints.compareTo(a.totalPrints));
          return Result.success(list.take(limit).toList());
        case Failure(error: final err):
          return Result.failure(err);
      }
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve frequent products from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<Product?, AppError>> getProductById(String id) async {
    try {
      final model = await _db.get<ProductHiveModel>(_collection, id);
      return Result.success(model?.toDomain());
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve product from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<List<Product>, AppError>> getAllProducts() async {
    try {
      final allModels = await _db.getAll<ProductHiveModel>(_collection);
      return Result.success(allModels.map((m) => m.toDomain()).toList());
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve products from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<List<Product>, AppError>> getFilteredProducts({String query = '', String category = ''}) async {
    try {
      final allResult = await getAllProducts();
      switch (allResult) {
        case Success(value: final all):
          final filtered = all.where((product) {
            final matchesQuery = query.isEmpty ||
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.sku.toLowerCase().contains(query.toLowerCase());
            final matchesCategory = category.isEmpty ||
                (product.category ?? '').toLowerCase() == category.toLowerCase();
            return matchesQuery && matchesCategory;
          }).toList();
          return Result.success(filtered);
        case Failure(error: final err):
          return Result.failure(err);
      }
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve filtered products from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> saveProduct(Product product) async {
    try {
      await _db.save<ProductHiveModel>(
        _collection,
        product.id,
        ProductHiveModel.fromDomain(product),
      );
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to save product to database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> deleteProduct(String id) async {
    try {
      await _db.delete(_collection, id);
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to delete product from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
