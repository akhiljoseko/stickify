import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/hive_registrar.g.dart';

/// Local database implementation powered by Hive Community Edition (`hive_ce`).
class HiveLocalDatabase implements LocalDatabase {
  final Map<String, Box<dynamic>> _openedBoxes = {};

  @override
  Future<void> init([String? path]) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    try {
      Hive.registerAdapters();
    } on Object catch (_) {
      // Adapters might already be registered in tests or separate isolates
    }
  }

  Future<Box<T>> _getBox<T>(String name) async {
    if (_openedBoxes.containsKey(name)) {
      final box = _openedBoxes[name];
      if (box != null && box.isOpen) {
        return box as Box<T>;
      }
    }
    final box = await Hive.openBox<T>(name);
    _openedBoxes[name] = box;
    return box;
  }

  @override
  Future<void> save<T>(String collection, String id, T data) async {
    final box = await _getBox<T>(collection);
    await box.put(id, data);
  }

  @override
  Future<T?> get<T>(String collection, String id) async {
    final box = await _getBox<T>(collection);
    return box.get(id);
  }

  @override
  Future<List<T>> getAll<T>(String collection) async {
    final box = await _getBox<T>(collection);
    return box.values.toList();
  }

  @override
  Future<void> delete(String collection, String id) async {
    final box = await _getBox<dynamic>(collection);
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
