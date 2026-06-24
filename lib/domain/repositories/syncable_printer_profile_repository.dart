import 'package:stickify/domain/repositories/printer_profile_repository.dart';
import 'package:stickify/domain/services/sync_queue.dart';

abstract interface class SyncablePrinterProfileRepository
    implements PrinterProfileRepository, Syncable {}
