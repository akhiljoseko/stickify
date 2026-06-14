import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/sync_operation.dart';

abstract interface class SyncQueue {
  Future<Result<void, AppError>> queue(SyncOperation operation);
  Future<Result<List<SyncOperation>, AppError>> getPending();
  Future<Result<void, AppError>> complete(SyncOperation operation);
}

// Syncable represents a contract for services that support synchronizing local cached data with a remote store.
// ignore: one_member_abstracts
abstract interface class Syncable {
  Future<Result<void, AppError>> sync(String uid);
}
