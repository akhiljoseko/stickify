import 'package:stickify/domain/entities/calibration_rule.dart';

/// Service that determines if a given [CalibrationRule] applies to a specific sticker slot on a sheet.
class CalibrationRuleMatcher {
  /// Creates a [CalibrationRuleMatcher] instance.
  const CalibrationRuleMatcher();

  /// Checks if [rule] matches a sticker slot specified by its position parameters.
  ///
  /// - [row]: Zero-based row index of the slot.
  /// - [column]: Zero-based column index of the slot.
  /// - [absoluteStickerIndex]: Zero-based absolute index of the sticker.
  /// - [totalRows]: Total number of rows in the sheet configuration.
  /// - [totalColumns]: Total number of columns in the sheet configuration.
  bool matches({
    required CalibrationRule rule,
    required int row,
    required int column,
    required int absoluteStickerIndex,
    required int totalRows,
    required int totalColumns,
  }) {
    final target = rule.target;

    switch (target.type) {
      case TargetType.sheet:
        return true;

      case TargetType.row:
        return target.index == row;

      case TargetType.column:
        return target.index == column;

      case TargetType.sticker:
        return target.index == absoluteStickerIndex;

      case TargetType.edge:
        final edge = target.edgeGroup;
        if (edge == null) return false;
        switch (edge) {
          case EdgeGroup.left:
            return column == 0;
          case EdgeGroup.right:
            return column == totalColumns - 1;
          case EdgeGroup.top:
            return row == 0;
          case EdgeGroup.bottom:
            return row == totalRows - 1;
        }
    }
  }
}
