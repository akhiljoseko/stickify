import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// A lightweight, thread-safe, local JSON-based NoSQL document database.
class DocumentDatabase {
  DocumentDatabase({Directory? customDirectory}) : _customDirectory = customDirectory;

  final Directory? _customDirectory;
  Directory? _dbDirectory;

  /// Initializes the database directory.
  Future<void> init() async {
    if (_dbDirectory != null) return;

    if (_customDirectory != null) {
      _dbDirectory = _customDirectory;
    } else {
      final appDocsDir = await getApplicationDocumentsDirectory();
      _dbDirectory = Directory('${appDocsDir.path}/stickify_db');
    }

    if (!await _dbDirectory!.exists()) {
      await _dbDirectory!.create(recursive: true);
    }
  }

  Future<File> _getFile(String collection, String id) async {
    final colDir = Directory('${_dbDirectory!.path}/$collection');
    if (!await colDir.exists()) {
      await colDir.create(recursive: true);
    }
    return File('${colDir.path}/$id.json');
  }

  /// Saves a document to a collection.
  Future<void> save(String collection, String id, Map<String, dynamic> data) async {
    await init();
    final file = await _getFile(collection, id);
    await file.writeAsString(jsonEncode(data));
  }

  /// Retrieves a document by its ID.
  Future<Map<String, dynamic>?> get(String collection, String id) async {
    await init();
    final file = await _getFile(collection, id);
    if (await file.exists()) {
      final content = await file.readAsString();
      return jsonDecode(content) as Map<String, dynamic>;
    }
    return null;
  }

  /// Retrieves all documents in a collection.
  Future<List<Map<String, dynamic>>> getAll(String collection) async {
    await init();
    final colDir = Directory('${_dbDirectory!.path}/$collection');
    if (!await colDir.exists()) {
      return [];
    }
    final list = <Map<String, dynamic>>[];
    final entities = colDir.listSync();
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.json')) {
        try {
          final content = await entity.readAsString();
          list.add(jsonDecode(content) as Map<String, dynamic>);
        } catch (_) {}
      }
    }
    return list;
  }

  /// Deletes a document from a collection.
  Future<void> delete(String collection, String id) async {
    await init();
    final file = await _getFile(collection, id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clears the entire database (useful for testing).
  Future<void> clear() async {
    await init();
    if (await _dbDirectory!.exists()) {
      await _dbDirectory!.delete(recursive: true);
      await _dbDirectory!.create(recursive: true);
    }
  }
}
