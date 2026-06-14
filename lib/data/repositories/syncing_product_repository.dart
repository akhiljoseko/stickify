import 'dart:developer' as developer;
import 'package:stickify/core/core.dart';
import 'package:stickify/data/repositories/syncing_base.dart';
import 'package:stickify/domain/domain.dart';

/// Syncing wrapper for [ProductRepository] implementing local caching and manual synchronization.
class SyncingProductRepository with SyncableRepository<Product> implements SyncableProductRepository {
  /// Creates a [SyncingProductRepository] instance.
  SyncingProductRepository({
    required this.local,
    required this.syncQueue,
    this.remote,
  });

  /// The local product repository.
  final ProductRepository local;

  /// The sync queue service.
  final SyncQueue syncQueue;

  /// The remote product repository.
  ProductRepository? remote;

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
    developer.log('saveProduct: Saving product. ID: ${product.id}, Name: ${product.name}', name: 'SYNC_DEBUG');
    return executeSyncMutation(
      localCall: () => local.saveProduct(product),
      remoteCall: remote != null ? () => remote!.saveProduct(product) : null,
      syncQueue: syncQueue,
      collection: 'products',
      id: product.id,
      action: SyncAction.save,
    );
  }

  @override
  Future<Result<void, AppError>> deleteProduct(String id) async {
    developer.log('deleteProduct: Deleting product. ID: $id', name: 'SYNC_DEBUG');
    return executeSyncMutation(
      localCall: () => local.deleteProduct(id),
      remoteCall: remote != null ? () => remote!.deleteProduct(id) : null,
      syncQueue: syncQueue,
      collection: 'products',
      id: id,
      action: SyncAction.delete,
    );
  }

  /// Pulls all products from Firestore and overwrites the local cache.
  @override
  Future<Result<void, AppError>> sync(String uid) async {
    developer.log('sync: Starting synchronization for user: $uid', name: 'SYNC_DEBUG');
    if (remote == null) {
      return const Result.failure(
        UnexpectedError(
          message: 'Cannot sync products: remote repository is not configured.',
        ),
      );
    }

    try {
      // 1. Process pending changes in sync queue for products
      developer.log('sync: Retrieving pending items from sync queue.', name: 'SYNC_DEBUG');
      final pendingResult = await syncQueue.getPending();
      final List<SyncOperation> productQueue;
      switch (pendingResult) {
        case Success(value: final pending):
          productQueue = pending
              .where((entry) => entry.collection == 'products')
              .toList();
        case Failure(error: final err):
          return Result.failure(err);
      }
      developer.log('sync: Pending product changes to process: ${productQueue.length}', name: 'SYNC_DEBUG');

      for (final entry in productQueue) {
        developer.log('sync: Processing queue entry. Key: ${entry.collection}_${entry.id}, Action: ${entry.action}', name: 'SYNC_DEBUG');

        if (entry.action == SyncAction.save) {
          final localResult = await local.getProductById(entry.id);
          switch (localResult) {
            case Success(value: final product):
              if (product != null) {
                developer.log('sync: Found product locally. Uploading to remote. ID: ${entry.id}', name: 'SYNC_DEBUG');
                final remoteResult = await remote!.saveProduct(product);
                if (remoteResult is Failure) {
                  return remoteResult;
                }
              } else {
                developer.log('sync: Product not found locally. Skipping upload. ID: ${entry.id}', name: 'SYNC_DEBUG');
              }
            case Failure(error: final err):
              return Result.failure(err);
          }
        } else if (entry.action == SyncAction.delete) {
          developer.log('sync: Deleting product on remote. ID: ${entry.id}', name: 'SYNC_DEBUG');
          final remoteResult = await remote!.deleteProduct(entry.id);
          if (remoteResult is Failure) {
            return remoteResult;
          }
        }
        developer.log('sync: Removing sync queue entry for key: ${entry.collection}_${entry.id}', name: 'SYNC_DEBUG');
        await syncQueue.complete(entry);
      }

      // 2. Pull from remote and overwrite local
      developer.log('sync: Fetching remote products.', name: 'SYNC_DEBUG');
      final remoteResult = await remote!.getAllProducts();
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
