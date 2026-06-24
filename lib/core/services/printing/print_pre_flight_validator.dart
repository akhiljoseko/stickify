import 'package:flutter/foundation.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Validates all pre-flight conditions for a print job before PDF generation
/// begins.
///
/// Responsibilities:
/// - Verify template structural completeness.
/// - Verify dimensional consistency.
/// - Verify sticker grid fits within the sheet.
/// - Verify element containment within the printable area.
///
/// This class has **no** UI dependencies, **no** printer-specific logic,
/// and **no** PDF generation logic. It is injected into print services and
/// can be tested independently.
class PrintPreFlightValidator {
  /// Creates a [PrintPreFlightValidator] instance.
  const PrintPreFlightValidator();

  /// Validates all pre-flight conditions for the given print parameters.
  ///
  /// Returns [Result.success] when all conditions pass.
  /// Returns [Result.failure] with a descriptive [ValidationError] on the
  /// first failing condition.
  ///
  /// Parameters:
  /// - [template]: The label template to validate.
  /// - [quantity]: The number of labels requested.
  /// - [disabledSlots]: The set of slot indices that will be skipped.
  Result<void, AppError> validate({
    required LabelTemplate template,
    required int quantity,
    required Set<int> disabledSlots,
  }) {
    final sheetConfig = template.sheetConfig;
    if (sheetConfig == null) {
      return const Result.failure(
        ValidationError(
          message: 'Sheet configuration is required for custom label printing.',
        ),
      );
    }

    final stickerConfig = template.stickerConfig;
    if (stickerConfig == null) {
      return const Result.failure(
        ValidationError(
          message:
              'Sticker configuration is required for custom label printing.',
        ),
      );
    }

    if (sheetConfig.pageWidth <= 0 || sheetConfig.pageHeight <= 0) {
      return const Result.failure(
        ValidationError(
          message: 'Page width and height must be greater than zero.',
        ),
      );
    }

    if (stickerConfig.widthMm <= 0 || stickerConfig.heightMm <= 0) {
      return const Result.failure(
        ValidationError(
          message: 'Sticker width and height must be greater than zero.',
        ),
      );
    }

    if (sheetConfig.columns <= 0 || sheetConfig.rows <= 0) {
      return const Result.failure(
        ValidationError(
          message: 'Columns and rows must be greater than zero.',
        ),
      );
    }

    if (sheetConfig.columnGap < 0 || sheetConfig.rowGap < 0) {
      return const Result.failure(
        ValidationError(message: 'Gaps cannot be negative.'),
      );
    }

    if (sheetConfig.marginTop < 0 ||
        sheetConfig.marginBottom < 0 ||
        sheetConfig.marginLeft < 0 ||
        sheetConfig.marginRight < 0) {
      return const Result.failure(
        ValidationError(message: 'Margins cannot be negative.'),
      );
    }

    if (quantity <= 0) {
      return const Result.failure(
        ValidationError(message: 'Quantity must be greater than zero.'),
      );
    }

    // Slot index bounds check
    final maxSlots = sheetConfig.columns * sheetConfig.rows;
    for (final slot in disabledSlots) {
      if (slot < 0 || slot >= maxSlots) {
        return const Result.failure(
          ValidationError(message: 'Disabled slot index is out of bounds.'),
        );
      }
    }

    // Grid overflow check
    final requiredWidth = sheetConfig.marginLeft +
        sheetConfig.columns * stickerConfig.widthMm +
        (sheetConfig.columns - 1) * sheetConfig.columnGap +
        sheetConfig.marginRight;
    final requiredHeight = sheetConfig.marginTop +
        sheetConfig.rows * stickerConfig.heightMm +
        (sheetConfig.rows - 1) * sheetConfig.rowGap +
        sheetConfig.marginBottom;

    if (requiredWidth > sheetConfig.pageWidth ||
        requiredHeight > sheetConfig.pageHeight) {
      return Result.failure(
        ValidationError(
          message: 'Sticker grid layout exceeds the physical sheet bounds. '
              'Required size: ${requiredWidth.toStringAsFixed(1)} x '
              '${requiredHeight.toStringAsFixed(1)} mm. '
              'Configured sheet size: ${sheetConfig.pageWidth} x '
              '${sheetConfig.pageHeight} mm.',
        ),
      );
    }

    // Printable area polygon minimum vertex check
    if (stickerConfig.printableArea.isNotEmpty &&
        stickerConfig.printableArea.length < 3) {
      return const Result.failure(
        ValidationError(
          message: 'Printable area polygon must have at least 3 points.',
        ),
      );
    }

    // Barcode / QR containment check
    for (final element in template.elements) {
      final isBarcodeOrQr =
          element is BarcodeElementBlueprint || element is QrElementBlueprint;
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
            message:
                'Barcode/QR element "${element.id}" falls outside the '
                'printable area polygon.',
          ),
        );
      } else if (!isInside) {
        debugPrint(
          'WARNING: Element "${element.id}" is outside the printable area '
          'polygon.',
        );
      }
    }

    return const Result.success(null);
  }
}
