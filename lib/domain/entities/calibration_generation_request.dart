import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/calibration_session.dart';

/// Represents input to the calibration generation engine.
@immutable
class CalibrationGenerationRequest extends Equatable {
  /// Creates a [CalibrationGenerationRequest] instance.
  CalibrationGenerationRequest({
    required this.session,
  }) : assert(session.isComplete, 'session must be complete to generate calibration rules');

  /// The complete calibration session containing measurements.
  final CalibrationSession session;

  @override
  List<Object?> get props => [session];
}
