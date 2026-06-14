// The Domain Service pattern defines clean single-purpose service boundaries.
// ignore_for_file: one_member_abstracts

import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Abstract service interface for printing dynamic labels to physical/system printers.
///
/// Belongs to the global domain layer. Concrete implementations live in
/// `lib/core/services/` or `lib/data/services/`.
abstract interface class PrintService {
  /// Retrieves list of available system printer devices.
  Future<List<PrinterDevice>> getAvailablePrinters();

  /// Generates a PDF document for the label sheet grids and sends it to the system printer.
  Future<Result<void, AppError>> printLabels({
    required Product product,
    required ProductVariant variant,
    required LabelTemplate template,
    required int quantity,
    required Set<int> disabledSlots,
    required PrinterDevice printer,
  });
}
