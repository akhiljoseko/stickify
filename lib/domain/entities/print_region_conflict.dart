import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/calibration_rule.dart';

/// Represents a conflict where a sticker's printable region extends beyond
/// the physical printer capabilities (margins).
class PrintRegionConflict extends Equatable {
  /// Creates a [PrintRegionConflict] instance.
  const PrintRegionConflict({
    required this.affectedEdge,
    required this.overlapMm,
    required this.affectedStickerIndices,
  }) : assert(overlapMm > 0, 'overlapMm must be greater than 0');

  /// The edge where the conflict occurs (left, right, top, or bottom).
  final EdgeGroup affectedEdge;

  /// The amount by which the printable region overlaps the physical limit, in millimeters.
  final double overlapMm;

  /// The absolute indices of the sticker slots impacted by this conflict.
  final List<int> affectedStickerIndices;

  @override
  List<Object?> get props => [
        affectedEdge,
        overlapMm,
        affectedStickerIndices,
      ];
}
