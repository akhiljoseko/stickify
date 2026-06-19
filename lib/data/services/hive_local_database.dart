import 'dart:io';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stickify/data/models/hive/hive_registrar.g.dart';
import 'package:stickify/domain/domain.dart';

/// Local database implementation powered by Hive Community Edition (`hive_ce`).
class HiveLocalDatabase implements LocalDatabase {
  final Map<String, Box<dynamic>> _openedBoxes = {};

  @override
  Future<void> init([String? path]) async {
    if (path != null) {
      Hive.init(path);
    } else {
      final docsDir = await getApplicationDocumentsDirectory();
      final dbDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}label-grid${Platform.pathSeparator}database',
      );
      if (!dbDir.existsSync()) {
        dbDir.createSync(recursive: true);
      }
      Hive.init(dbDir.path);
    }
    try {
      Hive.registerAdapters();
    } on Object catch (_) {
      // Adapters might already be registered in tests or separate isolates
    }
  }

  Future<Box<dynamic>> _getBox(String name) async {
    if (_openedBoxes.containsKey(name)) {
      final box = _openedBoxes[name];
      if (box != null && box.isOpen) {
        return box;
      }
    }
    final box = await Hive.openBox<dynamic>(name);
    _openedBoxes[name] = box;
    return box;
  }

  @override
  Future<void> save<T>(String collection, String id, T data) async {
    final box = await _getBox(collection);
    await box.put(id, data);
  }

  @override
  Future<T?> get<T>(String collection, String id) async {
    final box = await _getBox(collection);
    final value = box.get(id);
    if (value == null) return null;
    return value as T;
  }

  @override
  Future<List<T>> getAll<T>(String collection) async {
    final box = await _getBox(collection);
    return box.values.cast<T>().toList();
  }

  @override
  Future<void> delete(String collection, String id) async {
    final box = await _getBox(collection);
    await box.delete(id);
  }

  @override
  Future<void> clear() async {
    for (final box in _openedBoxes.values) {
      if (box.isOpen) {
        await box.clear();
        await box.close();
      }
    }
    _openedBoxes.clear();
    await Hive.deleteFromDisk();
  }
}
