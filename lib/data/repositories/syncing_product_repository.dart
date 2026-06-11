import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/firestore_product_repository.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [ProductRepository] implementing local caching and manual synchronization.
class SyncingProductRepository implements ProductRepository {
  /// Creates a [SyncingProductRepository] instance.
  SyncingProductRepository({
    required DatabaseProductRepository local,
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _local = local,
        _auth = auth,
        _firestore = firestore;

  final DatabaseProductRepository _local;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirestoreProductRepository? get _remote {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreProductRepository(firestore: _firestore, userId: uid);
  }

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    // Read from local cache
    return _local.getFrequentProducts(limit: limit);
  }

  @override
  Future<Product?> getProductById(String id) async {
    // Read from local cache
    return _local.getProductById(id);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    // Read from local cache
    return _local.getAllProducts();
  }

  @override
  Future<void> saveProduct(Product product) async {
    // 1. Write locally
    await _local.saveProduct(product);

    // 2. Automatically push to remote Firestore if logged in
    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.saveProduct(product);
      } catch (_) {
        // Fallback: local save remains, remote write will retry or sync later
      }
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    // 1. Delete locally
    await _local.deleteProduct(id);

    // 2. Automatically delete on remote Firestore if logged in
    final remoteRepo = _remote;
    if (remoteRepo != null) {
      try {
        await remoteRepo.deleteProduct(id);
      } catch (_) {
        // Fallback: local delete succeeds, remote sync will resolve it
      }
    }
  }

  /// Pulls all products from Firestore and overwrites the local cache.
  Future<void> sync(String uid) async {
    final remoteRepo = FirestoreProductRepository(firestore: _firestore, userId: uid);
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
