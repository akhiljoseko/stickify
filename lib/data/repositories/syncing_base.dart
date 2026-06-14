import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Mixin providing helper logic for orchestrating local-first writes and syncing queue tracking.
mixin SyncableRepository<T> {
  /// Executes a local write operation, queues a sync operation, and attempts to write to remote.
  Future<Result<R, AppError>> executeSyncMutation<R>({
    required Future<Result<R, AppError>> Function() localCall,
    required Future<Result<void, AppError>> Function()? remoteCall,
    required SyncQueue syncQueue,
    required String collection,
    required String id,
    required SyncAction action,
  }) async {
    final localResult = await localCall();
    if (localResult is Failure<R, AppError>) {
      return localResult;
    }

    final operation = SyncOperation(
      id: id,
      collection: collection,
      action: action,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    final queueResult = await syncQueue.queue(operation);
    if (queueResult is Failure<void, AppError>) {
      return Result.failure(queueResult.error);
    }

    if (remoteCall != null) {
      final remoteResult = await remoteCall();
      if (remoteResult is Success<void, AppError>) {
        await syncQueue.complete(operation);
      }
    }

    return localResult;
  }
}
