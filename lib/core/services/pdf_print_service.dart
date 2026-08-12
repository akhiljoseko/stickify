// The named parameters must be public for callers in other libraries, but the
// internal fields are kept private to preserve encapsulation, requiring initializer lists.
// ignore_for_file: prefer_initializing_formals
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/print_calibration_context_resolver.dart';
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
    required LabelLayoutEngine layoutEngine,
    required PrintCalibrationContextResolver calibrationResolver,
    PrintPreFlightValidator preFlightValidator = const PrintPreFlightValidator(),
  })  : _layoutEngine = layoutEngine,
        _calibrationResolver = calibrationResolver,
        _preFlightValidator = preFlightValidator;

  final LabelLayoutEngine _layoutEngine;
  final PrintCalibrationContextResolver _calibrationResolver;
  final PrintPreFlightValidator _preFlightValidator;

  @override
  Future<List<PrinterDevice>> getAvailablePrinters() async {
    final list = await Printing.listPrinters();
    return list
        .map((p) => PrinterDevice(name: p.name, url: p.url, isDefault: p.isDefault))
        .toList();
  }

  @override
  Future<List<DiscoveredPrinter>> getDiscoveredPrinters() {
    throw UnimplementedError('getDiscoveredPrinters is not implemented in PdfPrintService');
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
    bool reverseSheetOrder = false,
    PrintExecutionConfiguration? executionConfiguration,
    DateTime? manufacturingDate,
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

      // 2. Resolve coordinate context using the print calibration context resolver helper.
      final calibrationResult = _calibrationResolver.resolve(
        executionConfiguration: executionConfiguration,
        sheetConfig: sheetConfig,
      );
      if (calibrationResult case Failure(error: final err)) {
        return Result.failure(err);
      }
      final coordinateContext = (calibrationResult as Success<PrintCoordinateContext, AppError>).value;

      // 3. Generate PDF bytes using the layout engine.
      final pdfBytes = await _layoutEngine.buildPdfBytes(
        product: product,
        variant: variant,
        template: template,
        quantity: quantity,
        disabledSlots: disabledSlots,
        printFromBottom: printFromBottom,
        reverseSheetOrder: reverseSheetOrder,
        coordinateContext: coordinateContext,
        manufacturingDate: manufacturingDate,
      );

      final targetFormat = PdfPageFormat(
        sheetConfig.pageWidth * PdfPageFormat.mm,
        sheetConfig.pageHeight * PdfPageFormat.mm,
        marginAll: 0,
      );

      // 4. Dispatch to printing framework
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

  @override
  Future<Result<void, AppError>> printRawPdf({
    required Uint8List pdfBytes,
    required PrinterDevice printer,
    required double widthMm,
    required double heightMm,
    required String docName,
  }) async {
    try {
      final targetFormat = PdfPageFormat(
        widthMm * PdfPageFormat.mm,
        heightMm * PdfPageFormat.mm,
        marginAll: 0,
      );

      await Printing.layoutPdf(
        name: docName,
        onLayout: (format) async => pdfBytes,
        format: targetFormat,
        dynamicLayout: false,
        forceCustomPrintPaper: true,
      );

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        UnexpectedError(
          message: 'Failed to print raw PDF document.',
          originalError: e,
          stackTrace: s,
        ),
      );
    }
  }
}
