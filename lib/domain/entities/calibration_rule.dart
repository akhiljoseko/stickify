import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';

/// The type of layout target that a calibration rule applies to.
enum TargetType {
  /// Applies to the entire sheet.
  sheet,

  /// Applies to a specific row index.
  row,

  /// Applies to a specific column index.
  column,

  /// Applies to a specific absolute sticker index.
  sticker,

  /// Applies to a specific group of edges.
  edge,
}

/// The physical edges of a sheet.
enum EdgeGroup {
  /// The left edge.
  left,

  /// The right edge.
  right,

  /// The top edge.
  top,

  /// The bottom edge.
  bottom,
}

/// Represents the target area of the sheet that is affected by a calibration rule.
@immutable
class CalibrationTarget extends Equatable {
  /// Creates a target that applies to the entire sheet.
  const CalibrationTarget.sheet()
      : type = TargetType.sheet,
        index = null,
        edgeGroup = null;

  /// Creates a target that applies to a specific [row] index.
  const CalibrationTarget.row(int row)
      : type = TargetType.row,
        index = row,
        edgeGroup = null,
        assert(row >= 0, 'Row index must be non-negative');

  /// Creates a target that applies to a specific [column] index.
  const CalibrationTarget.column(int column)
      : type = TargetType.column,
        index = column,
        edgeGroup = null,
        assert(column >= 0, 'Column index must be non-negative');

  /// Creates a target that applies to a specific absolute [stickerIndex].
  const CalibrationTarget.sticker(int stickerIndex)
      : type = TargetType.sticker,
        index = stickerIndex,
        edgeGroup = null,
        assert(stickerIndex >= 0, 'Sticker index must be non-negative');

  /// Creates a target that applies to a specific [edgeGroup].
  const CalibrationTarget.edge(EdgeGroup group)
      : type = TargetType.edge,
        index = null,
        edgeGroup = group;

  /// Internal general constructor for parsing/deserialization.
  const CalibrationTarget.raw({
    required this.type,
    this.index,
    this.edgeGroup,
  })  : assert(
          type != TargetType.sheet || (index == null && edgeGroup == null),
          'Sheet target cannot have index or edge group',
        ),
        assert(
          (type != TargetType.row && type != TargetType.column && type != TargetType.sticker) ||
              (index != null && index >= 0),
          'Index must be non-negative for row, column, or sticker targets',
        ),
        assert(
          type != TargetType.edge || edgeGroup != null,
          'Edge group is required for edge targets',
        );

  /// The type of layout target.
  final TargetType type;

  /// The index (row, column, or sticker) being targeted.
  final int? index;

  /// The edge group being targeted.
  final EdgeGroup? edgeGroup;

  @override
  List<Object?> get props => [type, index, edgeGroup];

  @override
  String toString() =>
      'CalibrationTarget(type: $type, index: $index, edgeGroup: $edgeGroup)';
}

/// Represents a single calibration rule mapping a target area to a coordinate transformation.
@immutable
class CalibrationRule extends Equatable {
  /// Creates a [CalibrationRule].
  const CalibrationRule({
    required this.target,
    required this.transformation,
  });

  /// The target area affected by this calibration rule.
  final CalibrationTarget target;

  /// The transformation applied to the target area.
  final PrintStickerTransform transformation;

  @override
  List<Object?> get props => [target, transformation];

  @override
  String toString() =>
      'CalibrationRule(target: $target, transformation: $transformation)';
}
