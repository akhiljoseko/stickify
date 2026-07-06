import 'package:stickify/domain/entities/discovered_printer.dart';
import 'package:stickify/domain/entities/printer_device.dart';

/// Abstract service interface for discovering available physical/system printers.
abstract interface class PrinterDiscoveryService {
  /// Retrieves list of available system printer devices.
  Future<List<PrinterDevice>> getAvailablePrinters();

  /// Retrieves list of discovered physical printers from the operating system.
  ///
  /// Implementation must return an immutable collection (e.g. via [List.unmodifiable]).
  Future<List<DiscoveredPrinter>> getDiscoveredPrinters();
}
