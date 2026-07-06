// The named parameters must be public for callers in other libraries, but the
// internal fields are kept private to preserve encapsulation, requiring initializer lists.
// ignore_for_file: prefer_initializing_formals
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';
import 'package:stickify/domain/services/calibration_request.dart';
import 'package:stickify/domain/services/calibration_rule_matcher.dart';
import 'package:stickify/domain/services/calibration_transform_composer.dart';

/// Resolves printer tray calibration rules into a [PrintCoordinateContext] for sheet rendering.
class PrinterCalibrationCoordinateResolver {
  /// Creates a [PrinterCalibrationCoordinateResolver] with its required dependency services.
  const PrinterCalibrationCoordinateResolver({
    required CalibrationRuleMatcher ruleMatcher,
    required CalibrationTransformComposer transformComposer,
  })  : _ruleMatcher = ruleMatcher,
        _transformComposer = transformComposer;

  final CalibrationRuleMatcher _ruleMatcher;
  final CalibrationTransformComposer _transformComposer;

  /// Resolves the calibration rules from the [request] context.
  ///
  /// Assumes input domain objects are structurally valid.
  /// Returns a [Result] containing the resolved [PrintCoordinateContext], or a
  /// [ValidationError] if the request targets an unsupported paper configuration.
  Result<PrintCoordinateContext, ValidationError> resolve(
    CalibrationRequest request,
  ) {
    // 1. Verify paper configuration support
    final supportedIds = request.tray.supportedPaperConfigurations.map((c) => c.id).toList();
    final isSupported = supportedIds.any((id) => id == request.paperConfigId);
    Log.debug(
      'CalibrationResolver: tray="${request.tray.trayIdentifier}", '
      'paperConfigId="${request.paperConfigId}", '
      'supportedPaperConfigs=[${supportedIds.join(", ")}], '
      'isSupported=$isSupported.',
      tag: 'PrintPipeline',
    );
    if (!isSupported) {
      Log.warning(
        'CalibrationResolver: paper config "${request.paperConfigId}" not in tray\'s '
        'supported list [${supportedIds.join(", ")}]. Returning failure.',
        tag: 'PrintPipeline',
      );
      return const Result.failure(
        ValidationError(
          message: 'The selected paper configuration is not supported by the tray.',
        ),
      );
    }

    // 2. Active calibration check
    Log.debug(
      'CalibrationResolver: calibration enabled=${request.tray.calibration.enabled}, '
      'rules count=${request.tray.calibration.calibrationRules.length}.',
      tag: 'PrintPipeline',
    );
    if (!request.tray.calibration.enabled) {
      Log.debug(
        'CalibrationResolver: calibration disabled, returning identity context.',
        tag: 'PrintPipeline',
      );
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
          .where((rule) => _ruleMatcher.matches(
                rule: rule,
                row: row,
                column: column,
                absoluteStickerIndex: absoluteIndex,
                totalRows: totalRows,
                totalColumns: totalColumns,
              ))
          .toList();

      final composedTransform = _transformComposer.compose(matchingRules);

      Log.debug(
        'CalibrationResolver: slot $absoluteIndex (r=$row,c=$column): '
        '${matchingRules.length} rules matched, '
        'composed=(${composedTransform.offsetX.toStringAsFixed(3)}, '
        '${composedTransform.offsetY.toStringAsFixed(3)}, '
        '${composedTransform.scaleX.toStringAsFixed(5)}, '
        '${composedTransform.scaleY.toStringAsFixed(5)}), '
        'isIdentity=${composedTransform.isIdentity}.',
        tag: 'PrintPipeline',
      );

      // Memory Optimization: only store non-identity transformations
      if (!composedTransform.isIdentity) {
        stickerTransforms[absoluteIndex] = composedTransform;
      }
    }

    Log.debug(
      'CalibrationResolver: returning context with ${stickerTransforms.length} '
      'non-identity transform(s) out of $totalSlots slots.',
      tag: 'PrintPipeline',
    );

    return Result.success(
      PrintCoordinateContext(
        stickerTransforms: Map.unmodifiable(stickerTransforms),
      ),
    );
  }
}
