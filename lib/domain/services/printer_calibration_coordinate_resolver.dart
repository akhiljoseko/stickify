import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';
import 'package:stickify/domain/services/calibration_request.dart';
import 'package:stickify/domain/services/calibration_rule_matcher.dart';
import 'package:stickify/domain/services/calibration_transform_composer.dart';

/// Resolves printer tray calibration rules into a [PrintCoordinateContext] for sheet rendering.
class PrinterCalibrationCoordinateResolver {
  /// Resolves the calibration rules from the [request] context.
  ///
  /// Assumes input domain objects are structurally valid.
  /// Returns a [Result] containing the resolved [PrintCoordinateContext], or a
  /// [ValidationError] if the request targets an unsupported paper configuration.
  static Result<PrintCoordinateContext, ValidationError> resolve(
    CalibrationRequest request,
  ) {
    // 1. Verify paper configuration support
    final isSupported = request.tray.supportedPaperConfigurations
        .any((config) => config.id == request.paperConfigId);
    if (!isSupported) {
      return const Result.failure(
        ValidationError(
          message: 'The selected paper configuration is not supported by the tray.',
        ),
      );
    }

    // 2. Active calibration check
    if (!request.tray.calibration.enabled) {
      return const Result.success(PrintCoordinateContext.identity());
    }

    final totalRows = request.sheetConfig.rows;
    final totalColumns = request.sheetConfig.columns;
    final totalSlots = totalRows * totalColumns;

    final stickerTransforms = <int, PrintStickerTransform>{};

    // 3. Iterates through all sticker slots (zero-based indices) to build coordinate context
    for (var absoluteIndex = 0; absoluteIndex < totalSlots; absoluteIndex++) {
      final row = absoluteIndex ~/ totalColumns;
      final column = absoluteIndex % totalColumns;

      final matchingRules = request.tray.calibration.calibrationRules
          .where((rule) => CalibrationRuleMatcher.matches(
                rule: rule,
                row: row,
                column: column,
                absoluteStickerIndex: absoluteIndex,
                totalRows: totalRows,
                totalColumns: totalColumns,
              ))
          .toList();

      final composedTransform = CalibrationTransformComposer.compose(matchingRules);

      // Memory Optimization: only store non-identity transformations
      if (!composedTransform.isIdentity) {
        stickerTransforms[absoluteIndex] = composedTransform;
      }
    }

    return Result.success(
      PrintCoordinateContext(
        stickerTransforms: Map.unmodifiable(stickerTransforms),
      ),
    );
  }
}
