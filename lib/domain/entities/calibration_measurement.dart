import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/calibration_measurement_point.dart';

/// Represents a technician measurement for a single calibration target.
@immutable
class CalibrationMeasurement extends Equatable {
  /// Creates a [CalibrationMeasurement] instance.
  const CalibrationMeasurement({
    required this.point,
    required this.actualX,
    required this.actualY,
  });

  /// The target calibration measurement point.
  final CalibrationMeasurementPoint point;

  /// The actual measured physical X-coordinate on the sheet in millimeters.
  final double actualX;

  /// The actual measured physical Y-coordinate on the sheet in millimeters.
  final double actualY;

  /// The X-axis delta between the actual measurement and the expected position.
  double get deltaX => actualX - point.expectedX;

  /// The Y-axis delta between the actual measurement and the expected position.
  double get deltaY => actualY - point.expectedY;

  @override
  List<Object?> get props => [point, actualX, actualY];
}
