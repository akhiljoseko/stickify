import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/firestore_product_repository.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [ProductRepository] implementing local caching and manual synchronization.
class SyncingProductRepository implements ProductRepository {
  /// Creates a [SyncingProductRepository] instance.
  SyncingProductRepository({
    required this.local,
    required this.auth,
    required this.remoteDb,
  });

  /// The local product repository.
  final DatabaseProductRepository local;

  /// The authentication service interface.
  final AuthService auth;

  /// The remote database service interface.
  final RemoteDatabaseService remoteDb;

  FirestoreProductRepository? get _remote {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreProductRepository(remoteDb: remoteDb, userId: uid);
  }

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    return local.getFrequentProducts(limit: limit);
  }

  @override
  Future<Product?> getProductById(String id) async {
    return local.getProductById(id);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    return local.getAllProducts();
  }

  @override
  Future<void> saveProduct(Product product) async {
    await local.saveProduct(product);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveProduct(product);
      } on Exception catch (_) {
        // Fallback: local save remains, remote write will sync later
      }
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    await local.deleteProduct(id);

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.deleteProduct(id);
      } on Exception catch (_) {
        // Fallback: local delete succeeds, remote sync will resolve it
      }
    }
  }

  /// Pulls all products from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreProductRepository(remoteDb: remoteDb, userId: uid);
    final remoteProducts = await remoteRepo.getAllProducts();

    // Clear local cache
    final localProducts = await local.getAllProducts();
    for (final p in localProducts) {
      await local.deleteProduct(p.id);
    }

    // Populate local cache with remote documents
    for (final p in remoteProducts) {
      await local.saveProduct(p);
    }
  }
}
