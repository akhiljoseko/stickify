import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';
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
    required PrinterCalibrationCoordinateResolver calibrationResolver,
    required TemplatePrinterCompatibilityAnalyzer compatibilityAnalyzer,
    required IntelligentTransformGenerator transformGenerator,
    required CalibrationTransformComposer transformComposer,
  })  : _calibrationResolver = calibrationResolver,
        _compatibilityAnalyzer = compatibilityAnalyzer,
        _transformGenerator = transformGenerator,
        _transformComposer = transformComposer;

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
      return const Result.failure(
        ValidationError(
          message: 'Template configuration is missing sheet configuration.',
        ),
      );
    }

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
        return Result.failure(err);
      case Success(value: final context):
        calibrationContext = context;
    }

    // 2. Run Compatibility Analyzer with calibrated positions (post-calibration space)
    final compatibilityResult = _compatibilityAnalyzer.analyze(
      template: template,
      printer: printer,
      tray: tray,
      calibrationContext: calibrationContext,
    );

    // 3. If conflicts exist, run IntelligentTransformGenerator → OptimizationStrategy
    if (compatibilityResult.hasConflicts) {
      final strategy = _transformGenerator.generate(
        analysisResult: compatibilityResult,
        template: template,
        printer: printer,
        preferences: printer.optimizationPreferences,
        calibrationContext: calibrationContext,
      );

      // If Level 6 Escalation (unsupported) is triggered, fail the pipeline
      if (strategy.level.name == 'unsupported') {
        return Result.failure(
          ValidationError(
            message: strategy.description,
          ),
        );
      }

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

        newStickerTransforms[stickerIndex] = composed;
      }

      return Result.success(
        PrintCoordinateContext(
          globalTransform: calibrationContext.globalTransform,
          rowTransforms: calibrationContext.rowTransforms,
          columnTransforms: calibrationContext.columnTransforms,
          stickerTransforms: Map.unmodifiable(newStickerTransforms),
        ),
      );
    }

    // No conflicts, return the calibration context directly
    return Result.success(calibrationContext);
  }
}
