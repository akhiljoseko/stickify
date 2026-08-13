import 'dart:math' show min;

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
  Future<Result<Product?, AppError>> getProductById(String id) async {
    try {
      final model = await _db.get<ProductHiveModel>(_collection, id);
      return Result.success(model?.toDomain());
    } on AppError catch (e) {
      return Result.failure(e);
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
      final products = allModels.map((m) => m.toDomain()).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Result.success(products);
    } on AppError catch (e) {
      return Result.failure(e);
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
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve filtered products from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<PaginatedResult<Product>, AppError>> getProducts({
    required int page,
    required int pageSize,
    String? query,
    String? category,
  }) async {
    try {
      final allModels = await _db.getAll<ProductHiveModel>(_collection);
      var products = allModels.map((m) => m.toDomain()).toList();

      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        products = products.where((p) =>
          p.name.toLowerCase().contains(q) ||
          p.sku.toLowerCase().contains(q) ||
          p.keywords.any((k) => k.toLowerCase().contains(q))
        ).toList();
      }

      if (category != null && category.isNotEmpty) {
        products = products.where((p) =>
          (p.category ?? '').toLowerCase() == category.toLowerCase()
        ).toList();
      }

      products.sort((a, b) => a.name.compareTo(b.name));

      final totalCount = products.length;
      final start = page * pageSize;
      if (start >= totalCount) {
        return Result.success(PaginatedResult(
          items: [],
          totalCount: totalCount,
          hasMore: false,
          currentPage: page,
        ));
      }
      final end = min(start + pageSize, totalCount);
      final items = products.sublist(start, end);
      final hasMore = end < totalCount;

      return Result.success(PaginatedResult(
        items: items,
        totalCount: totalCount,
        hasMore: hasMore,
        currentPage: page,
      ));
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve paginated products.',
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
    } on AppError catch (e) {
      return Result.failure(e);
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
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to delete product from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
