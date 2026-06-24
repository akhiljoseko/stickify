import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';

/// Represents all printer-specific runtime decisions required for a single print job.
@immutable
class PrintExecutionConfiguration extends Equatable {
  /// Creates a [PrintExecutionConfiguration] instance.
  ///
  /// Optionally accepts [selectedTray] and [paperConfigurationId].
  ///
  /// Enforces that [paperConfigurationId] is required if a tray is selected.
  const PrintExecutionConfiguration({
    this.selectedTray,
    this.paperConfigurationId,
  }) : assert(
          selectedTray == null || paperConfigurationId != null,
          'paperConfigurationId is required when a printer tray is selected',
        );

  /// The physical tray configured and calibrated for the current printer profile.
  final PrinterTrayProfile? selectedTray;

  /// The unique template or paper format identifier configured for the tray.
  final String? paperConfigurationId;

  @override
  List<Object?> get props => [selectedTray, paperConfigurationId];

  @override
  String toString() =>
      'PrintExecutionConfiguration(selectedTray: ${selectedTray?.trayIdentifier}, '
      'paperConfigurationId: $paperConfigurationId)';
}
