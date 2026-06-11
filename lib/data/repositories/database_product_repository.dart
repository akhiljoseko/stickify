import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/data/models/hive/product_hive_model.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

/// Local storage implementation of [ProductRepository] backed by [LocalDatabase].
class DatabaseProductRepository implements ProductRepository {
  /// Creates a [DatabaseProductRepository] instance.
  DatabaseProductRepository({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'products';

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    final all = await getAllProducts();
    all.sort((a, b) => b.totalPrints.compareTo(a.totalPrints));
    return all.take(limit).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final model = await _db.get<ProductHiveModel>(_collection, id);
    return model?.toDomain();
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final allModels = await _db.getAll<ProductHiveModel>(_collection);
    return allModels.map((m) => m.toDomain()).toList();
  }

  @override
  Future<void> saveProduct(Product product) async {
    await _db.save<ProductHiveModel>(
      _collection,
      product.id,
      ProductHiveModel.fromDomain(product),
    );
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _db.delete(_collection, id);
  }
}
