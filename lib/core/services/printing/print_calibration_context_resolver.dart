import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Internal infrastructure helper that encapsulates the orchestration of calibration resolution.
class PrintCalibrationContextResolver {
  /// Instantiates a new [PrintCalibrationContextResolver] with the domain resolver.
  const PrintCalibrationContextResolver(this._domainResolver);

  final PrinterCalibrationCoordinateResolver _domainResolver;

  /// Resolves the calibration rules from the [executionConfiguration] and [sheetConfig].
  Result<PrintCoordinateContext, AppError> resolve({
    required PrintExecutionConfiguration? executionConfiguration,
    required SheetConfig? sheetConfig,
  }) {
    if (executionConfiguration == null) {
      return const Result.success(PrintCoordinateContext.identity());
    }

    final tray = executionConfiguration.selectedTray;
    if (tray == null) {
      return const Result.success(PrintCoordinateContext.identity());
    }

    if (sheetConfig == null) {
      return const Result.failure(
        ValidationError(
          message: 'Sheet configuration is required for calibration.',
        ),
      );
    }

    final paperConfigurationId = executionConfiguration.paperConfigurationId;
    if (paperConfigurationId == null) {
      return const Result.failure(
        ValidationError(
          message: 'Paper configuration ID is required when a printer tray is selected.',
        ),
      );
    }

    if (executionConfiguration.coordinateContext != null) {
      return Result.success(executionConfiguration.coordinateContext!);
    }

    final request = CalibrationRequest(
      tray: tray,
      paperConfigId: paperConfigurationId,
      sheetConfig: sheetConfig,
    );

    return _domainResolver.resolve(request);
  }
}
