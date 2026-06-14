import 'package:stickify/domain/repositories/print_job_repository.dart';
import 'package:stickify/domain/services/sync_queue.dart';

abstract interface class SyncablePrintJobRepository implements PrintJobRepository, Syncable {}
