import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/data/models/firestore/product_firestore_model.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

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
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    final list = await remoteDb.getCollection(
      _collectionPath,
      orderBy: 'totalPrints',
      descending: true,
      limit: limit,
    );
    return list.map((json) {
      return ProductFirestoreModel.fromMap(json['id'] as String, json).toDomain();
    }).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final data = await remoteDb.getData('$_collectionPath/$id');
    if (data == null) return null;
    return ProductFirestoreModel.fromMap(id, data).toDomain();
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final list = await remoteDb.getCollection(_collectionPath);
    return list.map((json) {
      return ProductFirestoreModel.fromMap(json['id'] as String, json).toDomain();
    }).toList();
  }

  @override
  Future<void> saveProduct(Product product) async {
    await remoteDb.setData(
      '$_collectionPath/${product.id}',
      ProductFirestoreModel.fromDomain(product).toMap(),
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    await remoteDb.deleteData('$_collectionPath/$id');
  }
}
