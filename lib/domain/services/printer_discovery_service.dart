import 'package:stickify/domain/domain.dart';

/// Abstract service interface for discovering available physical/system printers.
abstract interface class PrinterDiscoveryService {
  /// Retrieves list of available system printer devices.
  Future<List<PrinterDevice>> getAvailablePrinters();
}
