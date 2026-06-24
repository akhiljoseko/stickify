
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/print_pre_flight_validator.dart';
import 'package:stickify/domain/domain.dart';

/// Concrete implementation of [PrintService] using the `pdf` and `printing` packages.
///
/// This service coordinates the rendering of structured sticker layouts on print sheets
/// by delegating PDF compilation to a [LabelLayoutEngine], and then dispatching the
/// job to the printing system.
class PdfPrintService implements PrintService, PrinterDiscoveryService {
  /// Instantiates a new [PdfPrintService].
  const PdfPrintService({
    required this._layoutEngine,
    this._preFlightValidator = const PrintPreFlightValidator(),
  });

  final LabelLayoutEngine _layoutEngine;
  final PrintPreFlightValidator _preFlightValidator;

  @override
  Future<List<PrinterDevice>> getAvailablePrinters() async {
    final list = await Printing.listPrinters();
    return list
        .map((p) => PrinterDevice(name: p.name, url: p.url, isDefault: p.isDefault))
        .toList();
  }

  @override
  Future<Result<void, AppError>> printLabels({
    required Product product,
    required ProductVariant variant,
    required LabelTemplate template,
    required int quantity,
    required Set<int> disabledSlots,
    required PrinterDevice printer,
    bool printFromBottom = false,
  }) async {
    try {
      // 1. Pre-print validation (delegated to PrintPreFlightValidator)
      final validationResult = _preFlightValidator.validate(
        template: template,
        quantity: quantity,
        disabledSlots: disabledSlots,
      );
      if (validationResult case Failure(error: final err)) {
        return Result.failure(err);
      }

      final sheetConfig = template.sheetConfig!;

      // 2. Generate PDF bytes using the layout engine.
      // The identity PrintCoordinateContext is passed here — no calibration or
      // optimization is applied in Phase 1A. Future phases will resolve and
      // pass a printer-profile-specific context.
      final pdfBytes = await _layoutEngine.buildPdfBytes(
        product: product,
        variant: variant,
        template: template,
        quantity: quantity,
        disabledSlots: disabledSlots,
        printFromBottom: printFromBottom,
        coordinateContext: const PrintCoordinateContext.identity(),
      );

      final targetFormat = PdfPageFormat(
        sheetConfig.pageWidth * PdfPageFormat.mm,
        sheetConfig.pageHeight * PdfPageFormat.mm,
        marginAll: 0,
      );

      // 3. Dispatch to printing framework
      await Printing.layoutPdf(
        name: '${product.name}_${variant.name}_labels',
        onLayout: (format) async => pdfBytes,
        format: targetFormat,
        dynamicLayout: false,
        forceCustomPrintPaper: true,
      );

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        UnexpectedError(
          message: 'Failed to compile and print PDF document.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
