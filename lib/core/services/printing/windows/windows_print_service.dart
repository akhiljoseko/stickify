
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/printing/windows/powershell_scripts.dart';
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
  }) {
    _devModeManager.healOnStartup();
  }

  final LabelLayoutEngine _layoutEngine;
  final PaperValidationEngine _paperValidator;
  final WindowsDevModeManager _devModeManager;

  @override
  Future<List<PrinterDevice>> getAvailablePrinters() async {
    final list = await Printing.listPrinters();
    return list
        .map((p) => PrinterDevice(name: p.name, url: p.url, isDefault: p.isDefault))
        .toList();
  }

  @override
  Future<PrinterMargins> getPrinterMargins(PrinterDevice printer, SheetConfig sheet) async {
    if (!Platform.isWindows) return PrinterMargins.zero;

    try {
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}/get_margins.ps1');
      await scriptFile.writeAsString(PowershellScripts.getMargins);

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
        '-PrinterName',
        printer.name,
        '-WidthMm',
        sheet.pageWidth.toString(),
        '-HeightMm',
        sheet.pageHeight.toString(),
      ]);

      if (result.exitCode == 0) {
        final dynamic decoded = jsonDecode(result.stdout.toString());
        if (decoded is Map) {
          final left = (decoded['Left'] as num?)?.toDouble() ?? 0.0;
          final top = (decoded['Top'] as num?)?.toDouble() ?? 0.0;
          final right = (decoded['Right'] as num?)?.toDouble() ?? 0.0;
          final bottom = (decoded['Bottom'] as num?)?.toDouble() ?? 0.0;
          return PrinterMargins(
            left: left,
            top: top,
            right: right,
            bottom: bottom,
          );
        }
      }
    } catch (_) {
      // Fail-silent, fallback to zero margins
    }
    return PrinterMargins.zero;
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
      // 1. Pre-print validation layer
      final sheetConfig = template.sheetConfig;
      if (sheetConfig == null) {
        return const Result.failure(
          ValidationError(message: 'Sheet configuration is required for custom label printing.'),
        );
      }
      final stickerConfig = template.stickerConfig;
      if (stickerConfig == null) {
        return const Result.failure(
          ValidationError(message: 'Sticker configuration is required for custom label printing.'),
        );
      }

      if (sheetConfig.pageWidth <= 0 || sheetConfig.pageHeight <= 0) {
        return const Result.failure(ValidationError(message: 'Page width and height must be greater than zero.'));
      }
      if (stickerConfig.widthMm <= 0 || stickerConfig.heightMm <= 0) {
        return const Result.failure(ValidationError(message: 'Sticker width and height must be greater than zero.'));
      }
      if (sheetConfig.columns <= 0 || sheetConfig.rows <= 0) {
        return const Result.failure(ValidationError(message: 'Columns and rows must be greater than zero.'));
      }
      if (sheetConfig.columnGap < 0 || sheetConfig.rowGap < 0) {
        return const Result.failure(ValidationError(message: 'Gaps cannot be negative.'));
      }
      if (sheetConfig.marginTop < 0 || sheetConfig.marginBottom < 0 ||
          sheetConfig.marginLeft < 0 || sheetConfig.marginRight < 0) {
        return const Result.failure(ValidationError(message: 'Margins cannot be negative.'));
      }
      if (quantity <= 0) {
        return const Result.failure(ValidationError(message: 'Quantity must be greater than zero.'));
      }

      // Check slot indices
      final maxSlots = sheetConfig.columns * sheetConfig.rows;
      for (final slot in disabledSlots) {
        if (slot < 0 || slot >= maxSlots) {
          return const Result.failure(
            ValidationError(message: 'Disabled slot index is out of bounds.'),
          );
        }
      }

      final requiredWidth = sheetConfig.marginLeft +
          sheetConfig.columns * stickerConfig.widthMm +
          (sheetConfig.columns - 1) * sheetConfig.columnGap +
          sheetConfig.marginRight;
      final requiredHeight = sheetConfig.marginTop +
          sheetConfig.rows * stickerConfig.heightMm +
          (sheetConfig.rows - 1) * sheetConfig.rowGap +
          sheetConfig.marginBottom;

      if (requiredWidth > sheetConfig.pageWidth || requiredHeight > sheetConfig.pageHeight) {
        return Result.failure(
          ValidationError(
            message: 'Sticker grid layout exceeds the physical sheet bounds. '
                'Required size: ${requiredWidth.toStringAsFixed(1)} x ${requiredHeight.toStringAsFixed(1)} mm. '
                'Configured sheet size: ${sheetConfig.pageWidth} x ${sheetConfig.pageHeight} mm.',
          ),
        );
      }

      if (stickerConfig.printableArea.isNotEmpty && stickerConfig.printableArea.length < 3) {
        return const Result.failure(ValidationError(message: 'Printable area polygon must have at least 3 points.'));
      }

      // Barcode / QR containment validation
      for (final element in template.elements) {
        final isBarcodeOrQr = element is BarcodeElementBlueprint || element is QrElementBlueprint;
        final isInside = PolygonUtils.isBoxInPolygon(
          x: element.x,
          y: element.y,
          width: element.width,
          height: element.height,
          rotationDegrees: element.rotation,
          vertices: stickerConfig.printableArea,
        );

        if (isBarcodeOrQr && !isInside) {
          return Result.failure(
            ValidationError(
              message: 'Barcode/QR element "${element.id}" falls outside the printable area polygon.',
            ),
          );
        } else if (!isInside) {
          debugPrint('WARNING: Element "${element.id}" is outside the printable area polygon.');
        }
      }

      // 2. Validate custom paper form support
      final paperSupported = await _paperValidator.isPaperSizeSupported(printer, sheetConfig);
      if (!paperSupported) {
        return Result.failure(
          ValidationError(
            message: 'Selected printer "${printer.name}" does not support the required paper form size '
                '(${sheetConfig.pageWidth} x ${sheetConfig.pageHeight} mm). '
                'Please register this custom paper size in Windows Print Server Properties.',
          ),
        );
      }
      // Retrieve margins
      final margins = await getPrinterMargins(printer, sheetConfig);

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

      // 5. Direct print without system dialog using overridden printer settings
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
            margins: margins,
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
