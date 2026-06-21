import 'package:stickify/domain/domain.dart';

/// Abstract service interface for discovering available physical/system printers.
abstract interface class PrinterDiscoveryService {
  /// Retrieves list of available system printer devices.
  Future<List<PrinterDevice>> getAvailablePrinters();

  /// Retrieves the hardware margins for a given printer and sheet config.
  Future<PrinterMargins> getPrinterMargins(PrinterDevice printer, SheetConfig sheet);
}
