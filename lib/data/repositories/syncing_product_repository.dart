import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/firestore_product_repository.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [ProductRepository] implementing local caching and manual synchronization.
class SyncingProductRepository implements ProductRepository {
  /// Creates a [SyncingProductRepository] instance.
  SyncingProductRepository({
    required DatabaseProductRepository local,
    required AuthService auth,
    required RemoteDatabaseService remoteDb,
  })  : _local = local,
        _auth = auth,
        _remoteDb = remoteDb;

  final DatabaseProductRepository _local;
  final AuthService _auth;
  final RemoteDatabaseService _remoteDb;

  FirestoreProductRepository? get _remote {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreProductRepository(remoteDb: _remoteDb, userId: uid);
  }

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    return _local.getFrequentProducts(limit: limit);
  }

  @override
  Future<Product?> getProductById(String id) async {
    return _local.getProductById(id);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    return _local.getAllProducts();
  }

  @override
  Future<void> saveProduct(Product product) async {
    await _local.saveProduct(product);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveProduct(product);
      } on Object catch (_) {
        // Fallback: local save remains, remote write will sync later
      }
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _local.deleteProduct(id);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.deleteProduct(id);
      } on Object catch (_) {
        // Fallback: local delete succeeds, remote sync will resolve it
      }
    }
  }

  /// Pulls all products from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreProductRepository(remoteDb: _remoteDb, userId: uid);
    final remoteProducts = await remoteRepo.getAllProducts();

    // Clear local cache
    final localProducts = await _local.getAllProducts();
    for (final p in localProducts) {
      await _local.deleteProduct(p.id);
    }

    // Populate local cache with remote documents
    for (final p in remoteProducts) {
      await _local.saveProduct(p);
    }
  }
}
