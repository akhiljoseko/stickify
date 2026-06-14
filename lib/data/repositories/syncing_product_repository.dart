import 'dart:developer' as developer;
import 'package:stickify/core/core.dart';
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
    required this.localDatabase,
  });

  /// The local product repository.
  final DatabaseProductRepository local;

  /// The authentication service interface.
  final AuthService auth;

  /// The remote database service interface.
  final RemoteDatabaseService remoteDb;

  /// The local database service interface.
  final LocalDatabase localDatabase;

  FirestoreProductRepository? get _remote {
    final uid = auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreProductRepository(remoteDb: remoteDb, userId: uid);
  }

  @override
  Future<Result<List<Product>, AppError>> getFrequentProducts({int limit = 20}) async {
    return local.getFrequentProducts(limit: limit);
  }

  @override
  Future<Result<Product?, AppError>> getProductById(String id) async {
    return local.getProductById(id);
  }

  @override
  Future<Result<List<Product>, AppError>> getAllProducts() async {
    return local.getAllProducts();
  }

  @override
  Future<Result<List<Product>, AppError>> getFilteredProducts({String query = '', String category = ''}) async {
    return local.getFilteredProducts(query: query, category: category);
  }

  @override
  Future<Result<void, AppError>> saveProduct(Product product) async {
    developer.log('saveProduct: Saving product locally. ID: ${product.id}, Name: ${product.name}', name: 'SYNC_DEBUG');
    final localResult = await local.saveProduct(product);
    if (localResult is Failure) {
      return localResult;
    }

    final syncKey = 'products_${product.id}';
    developer.log('saveProduct: Writing to sync queue box with key: $syncKey', name: 'SYNC_DEBUG');
    try {
      await localDatabase.save('sync_queue', syncKey, {
        'id': product.id,
        'collection': 'products',
        'action': 'save',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to queue sync operation locally.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      developer.log('saveProduct: Authenticated remote sync attempt. User ID: ${auth.currentUser?.uid}', name: 'SYNC_DEBUG');
      final remoteResult = await remoteRepo.saveProduct(product);
      switch (remoteResult) {
        case Success():
          developer.log('saveProduct: Remote save successful. Deleting sync queue key: $syncKey', name: 'SYNC_DEBUG');
          try {
            await localDatabase.delete('sync_queue', syncKey);
          } catch (_) {}
        case Failure(error: final err):
          developer.log('saveProduct: Remote save failed. Error: $err. Sync queue entry remains.', name: 'SYNC_DEBUG');
      }
    } else {
      developer.log('saveProduct: Remote save skipped (user unauthenticated).', name: 'SYNC_DEBUG');
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppError>> deleteProduct(String id) async {
    developer.log('deleteProduct: Deleting product locally. ID: $id', name: 'SYNC_DEBUG');
    final localResult = await local.deleteProduct(id);
    if (localResult is Failure) {
      return localResult;
    }

    final syncKey = 'products_$id';
    developer.log('deleteProduct: Writing delete action to sync queue box with key: $syncKey', name: 'SYNC_DEBUG');
    try {
      await localDatabase.save('sync_queue', syncKey, {
        'id': id,
        'collection': 'products',
        'action': 'delete',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to queue delete sync operation locally.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }

    final remoteRepo = _remote;
    if (remoteRepo != null) {
      developer.log('deleteProduct: Authenticated remote delete attempt. User ID: ${auth.currentUser?.uid}', name: 'SYNC_DEBUG');
      final remoteResult = await remoteRepo.deleteProduct(id);
      switch (remoteResult) {
        case Success():
          developer.log('deleteProduct: Remote delete successful. Deleting sync queue key: $syncKey', name: 'SYNC_DEBUG');
          try {
            await localDatabase.delete('sync_queue', syncKey);
          } catch (_) {}
        case Failure(error: final err):
          developer.log('deleteProduct: Remote delete failed. Error: $err. Sync queue entry remains.', name: 'SYNC_DEBUG');
      }
    } else {
      developer.log('deleteProduct: Remote delete skipped (user unauthenticated).', name: 'SYNC_DEBUG');
    }
    return const Result.success(null);
  }

  /// Pulls all products from Firestore and overwrites the local cache.
  Future<Result<void, AppError>> sync(String uid) async {
    developer.log('sync: Starting synchronization for user: $uid', name: 'SYNC_DEBUG');
    final remoteRepo = FirestoreProductRepository(remoteDb: remoteDb, userId: uid);

    try {
      // 1. Process pending changes in sync queue for products
      developer.log('sync: Retrieving all items from sync_queue local box.', name: 'SYNC_DEBUG');
      final allQueue = await localDatabase.getAll<dynamic>('sync_queue');
      developer.log('sync: Total items in local sync_queue: ${allQueue.length}', name: 'SYNC_DEBUG');

      final productQueue = allQueue
          .where((entry) => entry is Map && entry['collection'] == 'products')
          .cast<Map<dynamic, dynamic>>()
          .toList();
      developer.log('sync: Pending product changes to process: ${productQueue.length}', name: 'SYNC_DEBUG');

      for (final entry in productQueue) {
        final id = entry['id'] as String;
        final action = entry['action'] as String;
        final syncKey = 'products_$id';
        developer.log('sync: Processing queue entry. Key: $syncKey, Action: $action', name: 'SYNC_DEBUG');

        if (action == 'save') {
          final localResult = await local.getProductById(id);
          switch (localResult) {
            case Success(value: final product):
              if (product != null) {
                developer.log('sync: Found product locally. Uploading to remote. ID: $id', name: 'SYNC_DEBUG');
                final remoteResult = await remoteRepo.saveProduct(product);
                if (remoteResult is Failure) {
                  return remoteResult;
                }
              } else {
                developer.log('sync: Product not found locally. Skipping upload. ID: $id', name: 'SYNC_DEBUG');
              }
            case Failure(error: final err):
              return Result.failure(err);
          }
        } else if (action == 'delete') {
          developer.log('sync: Deleting product on remote. ID: $id', name: 'SYNC_DEBUG');
          final remoteResult = await remoteRepo.deleteProduct(id);
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        developer.log('sync: Removing sync queue entry: $syncKey', name: 'SYNC_DEBUG');
        await localDatabase.delete('sync_queue', syncKey);
      }

      // 2. Pull from remote and overwrite local
      developer.log('sync: Fetching remote products from Firestore.', name: 'SYNC_DEBUG');
      final remoteResult = await remoteRepo.getAllProducts();
      switch (remoteResult) {
        case Success(value: final remoteProducts):
          developer.log('sync: Retrieved ${remoteProducts.length} products from remote.', name: 'SYNC_DEBUG');

          // Clear local cache
          developer.log('sync: Clearing local products cache.', name: 'SYNC_DEBUG');
          final localProductsResult = await local.getAllProducts();
          switch (localProductsResult) {
            case Success(value: final localProducts):
              for (final p in localProducts) {
                final deleteResult = await local.deleteProduct(p.id);
                if (deleteResult is Failure) {
                  return deleteResult;
                }
              }
            case Failure(error: final err):
              return Result.failure(err);
          }

          // Populate local cache with remote documents
          developer.log('sync: Populating local database with remote products.', name: 'SYNC_DEBUG');
          for (final p in remoteProducts) {
            final saveResult = await local.saveProduct(p);
            if (saveResult is Failure) {
              return saveResult;
            }
          }
          developer.log('sync: Synchronization completed successfully.', name: 'SYNC_DEBUG');
          return const Result.success(null);

        case Failure(error: final err):
          return Result.failure(err);
      }
    } catch (e, stackTrace) {
      return Result.failure(UnexpectedError(
        message: 'Sync process failed unexpectedly.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
