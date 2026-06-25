import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a physical calibration target printed on a sheet.
@immutable
class CalibrationMeasurementPoint extends Equatable {
  /// Creates a [CalibrationMeasurementPoint] instance.
  CalibrationMeasurementPoint({
    required this.id,
    required this.label,
    required this.expectedX,
    required this.expectedY,
  })  : assert(id.isNotEmpty, 'id cannot be empty'),
        assert(label.isNotEmpty, 'label cannot be empty');

  /// Unique identifier of the measurement point.
  final String id;

  /// Human-readable label of the measurement target (e.g. "TL", "TR").
  final String label;

  /// Expected physical X-coordinate on the sheet in millimeters.
  final double expectedX;

  /// Expected physical Y-coordinate on the sheet in millimeters.
  final double expectedY;

  @override
  List<Object?> get props => [id, label, expectedX, expectedY];
}
