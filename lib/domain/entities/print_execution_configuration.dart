import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';

/// Represents all printer-specific runtime decisions required for a single print job.
@immutable
class PrintExecutionConfiguration extends Equatable {
  /// Creates a [PrintExecutionConfiguration] instance.
  ///
  /// Optionally accepts [selectedTray], [paperConfigurationId], and [coordinateContext].
  ///
  /// Enforces that [paperConfigurationId] is required if a tray is selected.
  const PrintExecutionConfiguration({
    this.selectedTray,
    this.paperConfigurationId,
    this.coordinateContext,
  }) : assert(
          selectedTray == null || paperConfigurationId != null,
          'paperConfigurationId is required when a printer tray is selected',
        );

  /// The physical tray configured and calibrated for the current printer profile.
  final PrinterTrayProfile? selectedTray;

  /// The unique template or paper format identifier configured for the tray.
  final String? paperConfigurationId;

  /// The pre-computed coordinate transformation context (composed calibration + optimization).
  final PrintCoordinateContext? coordinateContext;

  @override
  List<Object?> get props => [selectedTray, paperConfigurationId, coordinateContext];

  @override
  String toString() =>
      'PrintExecutionConfiguration(selectedTray: ${selectedTray?.trayIdentifier}, '
      'paperConfigurationId: $paperConfigurationId, '
      'coordinateContext: $coordinateContext)';
}
