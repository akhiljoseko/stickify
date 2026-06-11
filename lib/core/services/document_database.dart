import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stickify/core/services/local_database.dart';

/// A lightweight, thread-safe, local JSON-based NoSQL document database implementing [LocalDatabase].
///
/// This database stores collection records as individual JSON files under
/// a designated application directory or a [customDirectory] provided for testing.
class DocumentDatabase implements LocalDatabase {
  /// Creates a [DocumentDatabase].
  ///
  /// Pass an optional [customDirectory] to override the default system-scoped
  /// application documents directory path.
  DocumentDatabase({this.customDirectory});

  /// The custom directory override, typically set during testing.
  final Directory? customDirectory;
  Directory? _dbDirectory;

  /// Initializes the database directory if it has not already been initialized.
  ///
  /// Resolves the target database root path and ensures it exists.
  @override
  Future<void> init() async {
    if (_dbDirectory != null) return;

    if (customDirectory != null) {
      _dbDirectory = customDirectory;
    } else {
      final appDocsDir = await getApplicationDocumentsDirectory();
      _dbDirectory = Directory('${appDocsDir.path}/stickify_db');
    }

    // Call create directly, which is safe to call even if the directory exists.
    await _dbDirectory!.create(recursive: true);
  }

  /// Helper to get the file reference for a specific collection document.
  Future<File> _getFile(String collection, String id) async {
    final colDir = Directory('${_dbDirectory!.path}/$collection');
    await colDir.create(recursive: true);
    return File('${colDir.path}/$id.json');
  }

  /// Saves a document to a [collection] mapped to the given [id].
  @override
  Future<void> save<T>(String collection, String id, T data) async {
    await init();
    final file = await _getFile(collection, id);
    final map = data as Map<String, dynamic>;
    await file.writeAsString(jsonEncode(map));
  }

  /// Retrieves a document by its [id] from a [collection].
  ///
  /// Returns null if the document does not exist.
  @override
  Future<T?> get<T>(String collection, String id) async {
    await init();
    final file = await _getFile(collection, id);
    if (file.existsSync()) {
      final content = await file.readAsString();
      return (jsonDecode(content) as Map<String, dynamic>) as T;
    }
    return null;
  }

  /// Retrieves all documents stored in a [collection].
  @override
  Future<List<T>> getAll<T>(String collection) async {
    await init();
    final colDir = Directory('${_dbDirectory!.path}/$collection');
    if (!colDir.existsSync()) {
      return [];
    }
    final list = <T>[];
    final entities = colDir.listSync();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          list.add((jsonDecode(content) as Map<String, dynamic>) as T);
        } on Object catch (_) {
          // Ignore corrupted or unreadable document logs silently in the mock DB.
        }
      }
    }
    return list;
  }

  /// Deletes a document with [id] from a [collection].
  @override
  Future<void> delete(String collection, String id) async {
    await init();
    final file = await _getFile(collection, id);
    try {
      await file.delete();
    } on FileSystemException catch (_) {
      // Document already deleted or inaccessible.
    }
  }

  /// Clears the entire database directory.
  ///
  /// Used primarily during integration testing setup/teardown.
  @override
  Future<void> clear() async {
    await init();
    if (_dbDirectory!.existsSync()) {
      await _dbDirectory!.delete(recursive: true);
      await _dbDirectory!.create(recursive: true);
    }
  }
}
