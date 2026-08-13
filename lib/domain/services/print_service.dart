// The Domain Service pattern defines clean single-purpose service boundaries.

import 'dart:typed_data';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Abstract service interface for printing dynamic labels to physical/system printers.
///
/// Belongs to the global domain layer. Concrete implementations live in
/// `lib/core/services/` or `lib/data/services/`.
abstract interface class PrintService {
  /// Generates a PDF document for the label sheet grids and sends it to the system printer.
  Future<Result<void, AppError>> printLabels({
    required List<PrintableItem> items,
    required LabelTemplate template,
    required Set<int> disabledSlots,
    required PrinterDevice printer,
    bool printFromBottom = false,
    bool reverseSheetOrder = false,
    PrintExecutionConfiguration? executionConfiguration,
    DateTime? manufacturingDate,
  });

  /// Prints raw PDF bytes directly to the target system printer with specified paper format size.
  Future<Result<void, AppError>> printRawPdf({
    required Uint8List pdfBytes,
    required PrinterDevice printer,
    required double widthMm,
    required double heightMm,
    required String docName,
  });
}
