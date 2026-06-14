import 'package:stickify/domain/domain.dart';

/// Abstract service interface for validating if a system printer supports a given sheet configuration.
abstract interface class PaperValidationEngine {
  /// Queries the printer capabilities to verify if a paper form matching the sheet config is supported.
  Future<bool> isPaperSizeSupported(PrinterDevice printer, SheetConfig sheet);
}
