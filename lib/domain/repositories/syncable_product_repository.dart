import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/domain/services/sync_queue.dart';

abstract interface class SyncableProductRepository implements ProductRepository, Syncable {}
