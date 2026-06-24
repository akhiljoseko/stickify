import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/calibration_rule.dart';

/// Represents a technician-measured set of calibration configurations for a printer tray.
@immutable
class PrinterCalibration extends Equatable {
  PrinterCalibration({
    required this.enabled,
    required List<CalibrationRule> calibrationRules,
    this.lastCalibratedAt,
  })  : calibrationRules = List.unmodifiable(calibrationRules),
        assert(
          !enabled || calibrationRules.isNotEmpty,
          'Enabled calibration requires at least one rule',
        );

  /// Whether this calibration is currently active.
  final bool enabled;

  /// The list of custom calibration rules.
  final List<CalibrationRule> calibrationRules;

  /// The timestamp of the last calibration calibration execution.
  final DateTime? lastCalibratedAt;

  @override
  List<Object?> get props => [enabled, calibrationRules, lastCalibratedAt];

  @override
  String toString() =>
      'PrinterCalibration(enabled: $enabled, rulesCount: ${calibrationRules.length}, '
      'lastCalibratedAt: $lastCalibratedAt)';
}
