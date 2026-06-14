/// Abstract interface for remote database operations.
///
/// Decouples repositories from the Cloud Firestore SDK.
abstract class RemoteDatabaseService {
  /// Writes or overwrites a document at [path] with [data].
  Future<void> setData(String path, Map<String, dynamic> data);

  /// Deletes the document located at [path].
  Future<void> deleteData(String path);

  /// Retrieves the document at [path]. Returns null if it does not exist.
  Future<Map<String, dynamic>?> getData(String path);

  /// Retrieves all documents under the collection [path].
  ///
  /// Optionally orders them by [orderBy] and caps results at [limit].
  Future<List<Map<String, dynamic>>> getCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    int? limit,
  });

  /// Queries the collection at [path] filtering by [field] equality.
  Future<List<Map<String, dynamic>>> queryCollection(
    String path, {
    required String field,
    required dynamic isEqualTo,
  });
}
