// The named parameters must be public for callers in other libraries, but the
// internal fields are kept private to preserve encapsulation, requiring initializer lists.
// ignore_for_file: prefer_initializing_formals
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/print_calibration_context_resolver.dart';
import 'package:stickify/core/services/printing/print_pre_flight_validator.dart';
import 'package:stickify/core/services/printing/windows/powershell_scripts.dart';
import 'package:stickify/core/services/printing/windows/windows_devmode_manager.dart';
import 'package:stickify/domain/domain.dart';

/// Concrete implementation of [PrintService] optimized for Windows platforms.
///
/// Interacts with the Windows registry to temporarily override device page settings
/// to guarantee accurate alignment for custom sheet label printing.
class WindowsPrintService implements PrintService, PrinterDiscoveryService {
  WindowsPrintService({
    required LabelLayoutEngine layoutEngine,
    required PaperValidationEngine paperValidator,
    required WindowsDevModeManager devModeManager,
    required PrintCalibrationContextResolver calibrationResolver,
    PrintPreFlightValidator? preFlightValidator,
    Future<ProcessResult> Function(
      String executable,
      List<String> arguments,
    )?
    processRunner,
  }) : _layoutEngine = layoutEngine,
       _paperValidator = paperValidator,
       _devModeManager = devModeManager,
       _calibrationResolver = calibrationResolver,
       _preFlightValidator =
           preFlightValidator ?? const PrintPreFlightValidator(),
       _processRunner = processRunner ?? Process.run {
    _devModeManager.healOnStartup();
  }

  final LabelLayoutEngine _layoutEngine;
  final PaperValidationEngine _paperValidator;
  final WindowsDevModeManager _devModeManager;
  final PrintCalibrationContextResolver _calibrationResolver;
  final PrintPreFlightValidator _preFlightValidator;
  final Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
  )
  _processRunner;

  @override
  Future<List<PrinterDevice>> getAvailablePrinters() async {
    final list = await Printing.listPrinters();
    return list
        .map(
          (p) =>
              PrinterDevice(name: p.name, url: p.url, isDefault: p.isDefault),
        )
        .toList();
  }

  @override
  Future<List<DiscoveredPrinter>> getDiscoveredPrinters() async {
    if (!Platform.isWindows) {
      return _fallbackToPrintingPackage();
    }

    File? scriptFile;
    try {
      final tempDir = Directory.systemTemp;
      scriptFile = File(
        '${tempDir.path}/list_printers_${DateTime.now().millisecondsSinceEpoch}.ps1',
      );
      await scriptFile.writeAsString(PowershellScripts.listPrinters);

      final result = await _processRunner('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ]);

      if (result.exitCode != 0) {
        return await _fallbackToPrintingPackage();
      }

      final decoded = jsonDecode(result.stdout.toString());
      final discoveredList = <DiscoveredPrinter>[];

      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            discoveredList.add(_parseDiscoveredPrinter(item));
          }
        }
      } else if (decoded is Map<String, dynamic>) {
        discoveredList.add(_parseDiscoveredPrinter(decoded));
      }

      return List<DiscoveredPrinter>.unmodifiable(discoveredList);
    } catch (_) {
      return _fallbackToPrintingPackage();
    } finally {
      if (scriptFile != null && scriptFile.existsSync()) {
        try {
          await scriptFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<List<DiscoveredPrinter>> _fallbackToPrintingPackage() async {
    try {
      final list = await Printing.listPrinters();
      final mapped = list.map((p) {
        return DiscoveredPrinter(
          systemPrinterName: p.name,
          status: p.isAvailable
              ? DiscoveredPrinterStatus.online
              : DiscoveredPrinterStatus.offline,
          model: p.model ?? '',
        );
      }).toList();
      return List<DiscoveredPrinter>.unmodifiable(mapped);
    } catch (_) {
      return List<DiscoveredPrinter>.unmodifiable(const []);
    }
  }

  DiscoveredPrinter _parseDiscoveredPrinter(Map<String, dynamic> json) {
    final name = json['Name'] as String? ?? 'Unknown Printer';
    final statusStr = json['PrinterStatus'] as String?;
    final driverName = json['DriverName'] as String? ?? '';
    final manufacturer = json['Manufacturer'] as String? ?? '';
    final driverVersion = json['DriverVersion'] as String? ?? '';

    return DiscoveredPrinter(
      systemPrinterName: name.isNotEmpty ? name : 'Unknown Printer',
      status: _mapPrinterStatus(statusStr),
      manufacturer: manufacturer,
      model: driverName,
      driverName: driverName,
      driverVersion: driverVersion,
    );
  }

  DiscoveredPrinterStatus _mapPrinterStatus(String? statusStr) {
    if (statusStr == null) return DiscoveredPrinterStatus.unknown;
    final lower = statusStr.toLowerCase();
    if (lower == 'normal' || lower == 'paused') {
      return DiscoveredPrinterStatus.online;
    } else if (lower.contains('offline')) {
      return DiscoveredPrinterStatus.offline;
    } else if (lower == 'error' || lower == 'unavailable') {
      return DiscoveredPrinterStatus.unavailable;
    } else {
      if (lower.contains('error') || lower.contains('unavailable')) {
        return DiscoveredPrinterStatus.unavailable;
      }
      return DiscoveredPrinterStatus.online;
    }
  }

  @override
  Future<Result<void, AppError>> printLabels({
    required List<PrintableItem> items,
    required LabelTemplate template,
    required Set<int> disabledSlots,
    required PrinterDevice printer,
    bool printFromBottom = false,
    bool reverseSheetOrder = false,
    PrintExecutionConfiguration? executionConfiguration,
    DateTime? manufacturingDate,
    Set<int>? selectedSheets,
  }) async {
    String? backupToken;
    try {
      // 1. Pre-print validation (delegated to PrintPreFlightValidator per item)
      for (final item in items) {
        final validationResult = _preFlightValidator.validate(
          template: template,
          quantity: item.quantity,
          disabledSlots: disabledSlots,
        );
        if (validationResult case Failure(error: final err)) {
          return Result.failure(err);
        }
      }

      final sheetConfig = template.sheetConfig!;

      // 2. Validate custom paper form support
      final paperSupported = await _paperValidator.isPaperSizeSupported(
        printer,
        sheetConfig,
      );
      if (!paperSupported) {
        return Result.failure(
          ValidationError(
            message:
                'Selected printer "${printer.name}" does not support the required paper form size '
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
            message:
                'Selected printer "${printer.name}" was not found in available system printers.',
          ),
        );
      }

      // 5. Resolve coordinate context
      final calibrationResult = _calibrationResolver.resolve(
        executionConfiguration: executionConfiguration,
        sheetConfig: sheetConfig,
      );
      if (calibrationResult case Failure(error: final err)) {
        return Result.failure(err);
      }
      final coordinateContext =
          (calibrationResult as Success<PrintCoordinateContext, AppError>)
              .value;

      // 6. Direct print without system dialog using overridden printer settings.
      final success = await Printing.directPrintPdf(
        printer: resolvedPrinter,
        onLayout: (format) async {
          return _layoutEngine.buildPdfBytes(
            items: items,
            template: template,
            disabledSlots: disabledSlots,
            printFromBottom: printFromBottom,
            reverseSheetOrder: reverseSheetOrder,
            physicalFormat: format,
            coordinateContext: coordinateContext,
            manufacturingDate: manufacturingDate,
            selectedSheets: selectedSheets,
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
          UnexpectedError(
            message:
                'Windows print spooler rejected the physical layout print job.',
          ),
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

  @override
  Future<Result<void, AppError>> printRawPdf({
    required Uint8List pdfBytes,
    required PrinterDevice printer,
    required double widthMm,
    required double heightMm,
    required String docName,
  }) async {
    String? backupToken;
    try {
      final sheetConfig = SheetConfig(
        pageWidth: widthMm,
        pageHeight: heightMm,
        marginTop: 0,
        marginBottom: 0,
        marginLeft: 0,
        marginRight: 0,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );

      final paperSupported = await _paperValidator.isPaperSizeSupported(
        printer,
        sheetConfig,
      );
      if (!paperSupported) {
        return Result.failure(
          ValidationError(
            message:
                'Selected printer "${printer.name}" does not support the required paper form size '
                '($widthMm x $heightMm mm). '
                'Please register this custom paper size in Windows Print Server Properties.',
          ),
        );
      }

      backupToken = await _devModeManager.applySettings(printer, sheetConfig);

      final printers = await Printing.listPrinters();
      final Printer resolvedPrinter;
      try {
        resolvedPrinter = printers.firstWhere((p) => p.name == printer.name);
      } catch (_) {
        return Result.failure(
          UnexpectedError(
            message:
                'Selected printer "${printer.name}" was not found in available system printers.',
          ),
        );
      }

      final success = await Printing.directPrintPdf(
        printer: resolvedPrinter,
        onLayout: (format) async => pdfBytes,
        format: PdfPageFormat(
          widthMm * PdfPageFormat.mm,
          heightMm * PdfPageFormat.mm,
          marginAll: 0,
        ),
        usePrinterSettings: true,
      );

      if (!success) {
        return const Result.failure(
          UnexpectedError(
            message:
                'Windows print spooler rejected the calibration print job.',
          ),
        );
      }

      return const Result.success(null);
    } catch (e, s) {
      return Result.failure(
        UnexpectedError(
          message: 'Failed to print calibration PDF on Windows.',
          originalError: e,
          stackTrace: s,
        ),
      );
    } finally {
      if (backupToken != null) {
        await _devModeManager.restoreSettings(printer, backupToken);
      }
    }
  }
}
