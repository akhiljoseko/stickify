import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

class HiveSyncQueue implements SyncQueue {
  HiveSyncQueue({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'sync_queue';

  String _getKey(SyncOperation op) => '${op.collection}_${op.id}';

  @override
  Future<Result<void, AppError>> queue(SyncOperation operation) async {
    try {
      await _db.save(_collection, _getKey(operation), operation.toMap());
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to queue sync operation.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<List<SyncOperation>, AppError>> getPending() async {
    try {
      final list = await _db.getAll<dynamic>(_collection);
      final operations = list
          .whereType<Map<dynamic, dynamic>>()
          .map(SyncOperation.fromMap)
          .toList();
      return Result.success(operations);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve pending sync operations.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> complete(SyncOperation operation) async {
    try {
      await _db.delete(_collection, _getKey(operation));
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to complete sync operation.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
