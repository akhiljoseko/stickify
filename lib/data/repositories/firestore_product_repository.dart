import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/firestore/product_firestore_model.dart';
import 'package:stickify/domain/domain.dart';

/// Remote repository implementation of [ProductRepository] backed by [RemoteDatabaseService].
class FirestoreProductRepository implements ProductRepository {
  /// Creates a [FirestoreProductRepository] instance.
  FirestoreProductRepository({
    required this.remoteDb,
    required this.userId,
  });

  /// The abstract remote database service.
  final RemoteDatabaseService remoteDb;

  /// The unique identifier of the authenticated user.
  final String userId;

  String get _collectionPath => 'users/$userId/products';

  @override
  Future<Result<Product?, AppError>> getProductById(String id) async {
    try {
      final data = await remoteDb.getData('$_collectionPath/$id');
      if (data == null) return const Result.success(null);
      return Result.success(ProductFirestoreModel.fromMap(id, data).toDomain());
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to retrieve product from remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<List<Product>, AppError>> getAllProducts() async {
    try {
      final list = await remoteDb.getCollection(_collectionPath);
      final mapped = list.map((json) {
        return ProductFirestoreModel.fromMap(json['id'] as String, json).toDomain();
      }).toList();
      return Result.success(mapped);
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to retrieve products from remote server.',
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
      return Result.failure(NetworkError(
        message: 'Failed to retrieve filtered products from remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> saveProduct(Product product) async {
    try {
      await remoteDb.setData(
        '$_collectionPath/${product.id}',
        ProductFirestoreModel.fromDomain(product).toMap(),
      );
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to save product to remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> deleteProduct(String id) async {
    try {
      await remoteDb.deleteData('$_collectionPath/$id');
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to delete product from remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
