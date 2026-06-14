import 'package:stickify/domain/repositories/template_repository.dart';
import 'package:stickify/domain/services/sync_queue.dart';

abstract interface class SyncableTemplateRepository implements TemplateRepository, Syncable {}
