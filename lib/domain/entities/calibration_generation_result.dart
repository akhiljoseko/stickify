import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/calibration_rule.dart';

/// Represents output from the calibration generation engine.
@immutable
class CalibrationGenerationResult extends Equatable {
  /// Creates a [CalibrationGenerationResult] instance.
  CalibrationGenerationResult({
    required List<CalibrationRule> generatedRules,
  }) : generatedRules = List.unmodifiable(generatedRules);

  /// The generated calibration rules.
  final List<CalibrationRule> generatedRules;

  @override
  List<Object?> get props => [generatedRules];
}
