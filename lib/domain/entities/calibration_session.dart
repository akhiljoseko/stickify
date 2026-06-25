import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/calibration_measurement.dart';
import 'package:stickify/domain/entities/calibration_sheet_template.dart';
import 'package:stickify/domain/entities/printer_profile.dart';
import 'package:stickify/domain/entities/printer_tray_profile.dart';

/// Represents an in-progress technician calibration session.
@immutable
class CalibrationSession extends Equatable {
  /// Creates a [CalibrationSession] instance.
  CalibrationSession({
    required this.id,
    required this.printerProfile,
    required this.trayProfile,
    required this.paperConfigurationId,
    required this.sheetTemplate,
    required List<CalibrationMeasurement> measurements,
  })  : assert(id.isNotEmpty, 'id cannot be empty'),
        assert(paperConfigurationId.isNotEmpty, 'paperConfigurationId cannot be empty'),
        measurements = List.unmodifiable(measurements);

  /// Unique identifier of the calibration session.
  final String id;

  /// The printer profile being calibrated.
  final PrinterProfile printerProfile;

  /// The tray profile being calibrated.
  final PrinterTrayProfile trayProfile;

  /// Unique identifier of the paper configuration.
  final String paperConfigurationId;

  /// The sheet template used for calibration targets.
  final CalibrationSheetTemplate sheetTemplate;

  /// The list of measurements completed by the technician.
  final List<CalibrationMeasurement> measurements;

  /// Computed getter indicating whether the session is complete.
  ///
  /// Complete when the number of measurements exactly equals the sheet template
  /// points count AND every measurement belongs to a unique point ID.
  bool get isComplete {
    final measuredPointIds = measurements
        .map((m) => m.point.id)
        .toSet();

    return measurements.length == sheetTemplate.points.length &&
        measuredPointIds.length == sheetTemplate.points.length;
  }

  @override
  List<Object?> get props => [
        id,
        printerProfile,
        trayProfile,
        paperConfigurationId,
        sheetTemplate,
        measurements,
      ];
}
