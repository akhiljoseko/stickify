import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Concrete implementation of [PrintService] using the `pdf` and `printing` packages.
///
/// This service coordinates the rendering of structured sticker layouts on print sheets
/// by delegating PDF compilation to a [LabelLayoutEngine], and then dispatching the
/// job to the printing system.
class PdfPrintService implements PrintService {
  /// Instantiates a new [PdfPrintService].
  const PdfPrintService({
    required LabelLayoutEngine layoutEngine,
  }) : _layoutEngine = layoutEngine;

  final LabelLayoutEngine _layoutEngine;

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
  }) async {
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
          // Log a warning for non-barcode elements that are clipped
          debugPrint('WARNING: Element "${element.id}" is outside the printable area polygon.');
        }
      }

      // 2. Generate PDF bytes using the layout engine
      final pdfBytes = await _layoutEngine.buildPdfBytes(
        product: product,
        variant: variant,
        template: template,
        quantity: quantity,
        disabledSlots: disabledSlots,
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
