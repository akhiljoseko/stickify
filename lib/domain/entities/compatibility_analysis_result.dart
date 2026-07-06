import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/optimization_level.dart';
import 'package:stickify/domain/entities/print_region_conflict.dart';

/// Represents the result of a printer compatibility analysis.
class CompatibilityAnalysisResult extends Equatable {
  /// Creates a [CompatibilityAnalysisResult] instance.
  CompatibilityAnalysisResult({
    required List<PrintRegionConflict> conflicts,
    required this.recommendedOptimizationLevel,
  }) : conflicts = List.unmodifiable(conflicts);

  /// List of detected conflicts.
  final List<PrintRegionConflict> conflicts;

  /// The level of optimization recommended to resolve the conflicts.
  final OptimizationLevel recommendedOptimizationLevel;

  /// Returns whether any conflicts were detected during analysis.
  bool get hasConflicts => conflicts.isNotEmpty;

  @override
  List<Object?> get props => [
        conflicts,
        recommendedOptimizationLevel,
      ];
}
