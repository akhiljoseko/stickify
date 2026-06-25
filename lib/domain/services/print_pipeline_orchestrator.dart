import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';
import 'package:stickify/domain/entities/printer_profile.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';
import 'package:stickify/domain/services/calibration_request.dart';
import 'package:stickify/domain/services/calibration_transform_composer.dart';
import 'package:stickify/domain/services/intelligent_transform_generator.dart';
import 'package:stickify/domain/services/printer_calibration_coordinate_resolver.dart';
import 'package:stickify/domain/services/template_printer_compatibility_analyzer.dart';

/// Orchestrates the printing pipeline by resolving calibration rules,
/// running compatibility analysis, generating optimization transforms,
/// and composing the final coordinate context.
class PrintPipelineOrchestrator {
  /// Creates a [PrintPipelineOrchestrator] with the required services.
  const PrintPipelineOrchestrator({
    required this._calibrationResolver,
    required this._compatibilityAnalyzer,
    required this._transformGenerator,
    required this._transformComposer,
  });

  final PrinterCalibrationCoordinateResolver _calibrationResolver;
  final TemplatePrinterCompatibilityAnalyzer _compatibilityAnalyzer;
  final IntelligentTransformGenerator _transformGenerator;
  final CalibrationTransformComposer _transformComposer;

  /// Sequences the calibration resolver, compatibility analyzer, and transform generator
  /// to produce a fully calibrated and optimized [PrintCoordinateContext].
  Result<PrintCoordinateContext, AppError> resolve({
    required LabelTemplate template,
    required PrinterProfile printer,
    required PrinterTrayProfile tray,
    required String paperConfigurationId,
  }) {
    final sheetConfig = template.sheetConfig;
    if (sheetConfig == null) {
      Log.error(
        'Print pipeline aborted: template "${template.name}" has no sheet configuration.',
        tag: 'PrintPipeline',
      );
      return const Result.failure(
        ValidationError(
          message: 'Template configuration is missing sheet configuration.',
        ),
      );
    }

    Log.info(
      'Print pipeline starting for template "${template.name}", '
      'printer "${printer.displayName}", '
      'tray "${tray.displayName}".',
      tag: 'PrintPipeline',
    );

    // 1. Resolve calibration rules → PrintCoordinateContext (calibration transforms)
    final calibrationRequest = CalibrationRequest(
      tray: tray,
      paperConfigId: paperConfigurationId,
      sheetConfig: sheetConfig,
    );

    final PrintCoordinateContext calibrationContext;
    final calibrationResult = _calibrationResolver.resolve(calibrationRequest);
    switch (calibrationResult) {
      case Failure(error: final err):
        Log.error(
          'Calibration resolution failed: ${err.message}',
          tag: 'PrintPipeline',
        );
        return Result.failure(err);
      case Success(value: final context):
        calibrationContext = context;
    }

    Log.info(
      'Calibration resolved: '
      'global transform offset=(${calibrationContext.globalTransform.offsetX.toStringAsFixed(3)}, '
      '${calibrationContext.globalTransform.offsetY.toStringAsFixed(3)}), '
      'scale=(${calibrationContext.globalTransform.scaleX.toStringAsFixed(5)}, '
      '${calibrationContext.globalTransform.scaleY.toStringAsFixed(5)}). '
      '${calibrationContext.stickerTransforms.length} sticker-specific override(s).',
      tag: 'PrintPipeline',
    );

    // 2. Run Compatibility Analyzer with calibrated positions (post-calibration space)
    final compatibilityResult = _compatibilityAnalyzer.analyze(
      template: template,
      printer: printer,
      tray: tray,
      calibrationContext: calibrationContext,
    );

    Log.info(
      'Compatibility analysis: '
      '${compatibilityResult.conflicts.length} conflict(s) detected. '
      'Recommended level: ${compatibilityResult.recommendedOptimizationLevel.name}.',
      tag: 'PrintPipeline',
    );

    // 3. If conflicts exist, run IntelligentTransformGenerator → OptimizationStrategy
    if (compatibilityResult.hasConflicts) {
      Log.info(
        'Conflicts detected — running optimization transform generator...',
        tag: 'PrintPipeline',
      );
      final strategy = _transformGenerator.generate(
        analysisResult: compatibilityResult,
        template: template,
        printer: printer,
        preferences: printer.optimizationPreferences,
        calibrationContext: calibrationContext,
      );

      // If Level 6 Escalation (unsupported) is triggered, fail the pipeline
      if (strategy.level.name == 'unsupported') {
        Log.error(
          'Print pipeline aborted: template/printer combination is unsupported. '
          '${strategy.description}',
          tag: 'PrintPipeline',
        );
        return Result.failure(
          ValidationError(
            message: strategy.description,
          ),
        );
      }

      Log.info(
        'Optimization strategy: level=${strategy.level.name}, '
        '${strategy.transforms.length} transform(s). ${strategy.description}',
        tag: 'PrintPipeline',
      );

      // 4. Compose transforms: composed = existing ∘ optimization
      final newStickerTransforms = Map<int, PrintStickerTransform>.from(
        calibrationContext.stickerTransforms,
      );

      final totalColumns = sheetConfig.columns;

      for (final entry in strategy.transforms.entries) {
        final stickerIndex = entry.key;
        final optimizationTransform = entry.value;

        final row = stickerIndex ~/ totalColumns;
        final column = stickerIndex % totalColumns;

        // Retrieve effective calibration transform
        final existingCalibration = calibrationContext.resolveFor(
          row: row,
          column: column,
          absoluteSlotIndex: stickerIndex,
        );

        // Compose: calibration FIRST, optimization SECOND
        final composed = _transformComposer.composeTwo(
          existingCalibration,
          optimizationTransform,
        );

        Log.debug(
          '  Slot $stickerIndex (row=$row, col=$column): '
          'calibration=(${existingCalibration.offsetX.toStringAsFixed(3)}, '
          '${existingCalibration.offsetY.toStringAsFixed(3)}, '
          '${existingCalibration.scaleX.toStringAsFixed(5)}, '
          '${existingCalibration.scaleY.toStringAsFixed(5)}) ∘ '
          'optimization=(${optimizationTransform.offsetX.toStringAsFixed(3)}, '
          '${optimizationTransform.offsetY.toStringAsFixed(3)}, '
          '${optimizationTransform.scaleX.toStringAsFixed(5)}, '
          '${optimizationTransform.scaleY.toStringAsFixed(5)}) = '
          'composed=(${composed.offsetX.toStringAsFixed(3)}, '
          '${composed.offsetY.toStringAsFixed(3)}, '
          '${composed.scaleX.toStringAsFixed(5)}, '
          '${composed.scaleY.toStringAsFixed(5)})',
          tag: 'PrintPipeline',
        );

        newStickerTransforms[stickerIndex] = composed;
      }

      Log.info(
        'Print pipeline complete: calibration + optimization composed for '
        '${newStickerTransforms.length} sticker(s).',
        tag: 'PrintPipeline',
      );

      return Result.success(
        PrintCoordinateContext(
          globalTransform: calibrationContext.globalTransform,
          rowTransforms: calibrationContext.rowTransforms,
          columnTransforms: calibrationContext.columnTransforms,
          stickerTransforms: Map.unmodifiable(newStickerTransforms),
        ),
      );
    }

    Log.info(
      'Print pipeline complete: no conflicts, using calibration context directly.',
      tag: 'PrintPipeline',
    );
    // No conflicts, return the calibration context directly
    return Result.success(calibrationContext);
  }
}
