import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/calibration_measurement_point.dart';

/// Represents the measurement template printed during calibration.
@immutable
class CalibrationSheetTemplate extends Equatable {
  /// Creates a [CalibrationSheetTemplate] instance.
  CalibrationSheetTemplate({
    required this.id,
    required this.name,
    required List<CalibrationMeasurementPoint> points,
  })  : assert(id.isNotEmpty, 'id cannot be empty'),
        assert(name.isNotEmpty, 'name cannot be empty'),
        assert(points.isNotEmpty, 'points cannot be empty'),
        points = List.unmodifiable(points);

  /// Unique identifier of the sheet template.
  final String id;

  /// Human-readable name of the template.
  final String name;

  /// The list of target points printed on the sheet.
  final List<CalibrationMeasurementPoint> points;

  @override
  List<Object?> get props => [id, name, points];
}
