
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/print_pre_flight_validator.dart';
import 'package:stickify/core/services/printing/windows/windows_devmode_manager.dart';
import 'package:stickify/domain/domain.dart';

/// Concrete implementation of [PrintService] optimized for Windows platforms.
///
/// Interacts with the Windows registry to temporarily override device page settings
/// to guarantee accurate alignment for custom sheet label printing.
class WindowsPrintService implements PrintService, PrinterDiscoveryService {
  /// Instantiates a new [WindowsPrintService].
  WindowsPrintService({
    required this._layoutEngine,
    required this._paperValidator,
    required this._devModeManager,
    PrintPreFlightValidator? preFlightValidator,
  })  : _preFlightValidator =
            preFlightValidator ?? const PrintPreFlightValidator() {
    _devModeManager.healOnStartup();
  }

  final LabelLayoutEngine _layoutEngine;
  final PaperValidationEngine _paperValidator;
  final WindowsDevModeManager _devModeManager;
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
    String? backupToken;
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

      // 2. Validate custom paper form support
      final paperSupported =
          await _paperValidator.isPaperSizeSupported(printer, sheetConfig);
      if (!paperSupported) {
        return Result.failure(
          ValidationError(
            message: 'Selected printer "${printer.name}" does not support the required paper form size '
                '(${sheetConfig.pageWidth} x ${sheetConfig.pageHeight} mm). '
                'Please register this custom paper size in Windows Print Server Properties.',
          ),
        );
      }
      // 3. Apply Windows DEVMODE registry override
      backupToken = await _devModeManager.applySettings(printer, sheetConfig);

      // 4. Retrieve target printer model
      final printers = await Printing.listPrinters();
      final Printer resolvedPrinter;
      try {
        resolvedPrinter = printers.firstWhere(
          (p) => p.name == printer.name,
        );
      } catch (_) {
        return Result.failure(
          UnexpectedError(
            message: 'Selected printer "${printer.name}" was not found in available system printers.',
          ),
        );
      }

      // 5. Direct print without system dialog using overridden printer settings.
      // The identity PrintCoordinateContext is passed here — no calibration or
      // optimization is applied in Phase 1A. Future phases will resolve and
      // pass a printer-profile-specific context.
      final success = await Printing.directPrintPdf(
        printer: resolvedPrinter,
        onLayout: (format) async {
          return _layoutEngine.buildPdfBytes(
            product: product,
            variant: variant,
            template: template,
            quantity: quantity,
            disabledSlots: disabledSlots,
            printFromBottom: printFromBottom,
            physicalFormat: format,
            coordinateContext: const PrintCoordinateContext.identity(),
          );
        },
        format: PdfPageFormat(
          sheetConfig.pageWidth * PdfPageFormat.mm,
          sheetConfig.pageHeight * PdfPageFormat.mm,
          marginAll: 0,
        ),
        usePrinterSettings: true,
      );

      if (!success) {
        return const Result.failure(
          UnexpectedError(message: 'Windows print spooler rejected the physical layout print job.'),
        );
      }

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        UnexpectedError(
          message: 'Failed to compile and print PDF document on Windows.',
          originalError: e,
          stackTrace: s,
        ),
      );
    } finally {
      // 7. Restore DEVMODE settings
      if (backupToken != null) {
        await _devModeManager.restoreSettings(printer, backupToken);
      }
    }
  }
}
