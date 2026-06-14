/// Generic NoSQL-style Local Database interface.
///
/// Decouples repositories from specific storage implementations (e.g. Hive, JSON files).
abstract class LocalDatabase {
  /// Initializes the database engine.
  Future<void> init([String? path]);

  /// Saves a document [data] mapped to [id] inside a [collection].
  Future<void> save<T>(String collection, String id, T data);

  /// Retrieves a document by [id] from a [collection].
  Future<T?> get<T>(String collection, String id);

  /// Retrieves all documents stored in a [collection].
  Future<List<T>> getAll<T>(String collection);

  /// Deletes a document with [id] from a [collection].
  Future<void> delete(String collection, String id);

  /// Wipes all database data.
  Future<void> clear();
}
