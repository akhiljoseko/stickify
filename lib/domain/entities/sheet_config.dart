import 'package:equatable/equatable.dart';

/// Defines the dimensional layout configuration for a physical sheet of labels.
///
/// Contains parameters for the page sizes, outer margins, column/row count,
/// and gaps between neighboring labels.
class SheetConfig extends Equatable {
  /// Creates a [SheetConfig] layout representation.
  const SheetConfig({
    required this.pageWidth,
    required this.pageHeight,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
    required this.columns,
    required this.rows,
    required this.columnGap,
    required this.rowGap,
  });

  /// Width of the entire sheet page in millimeters (mm).
  final double pageWidth;

  /// Height of the entire sheet page in millimeters (mm).
  final double pageHeight;

  /// Outer margin from the top edge of the sheet to the first row of labels in mm.
  final double marginTop;

  /// Outer margin from the bottom edge of the sheet in mm.
  final double marginBottom;

  /// Outer margin from the left edge of the sheet to the first column of labels in mm.
  final double marginLeft;

  /// Outer margin from the right edge of the sheet in mm.
  final double marginRight;

  /// Number of sticker columns in the sheet grid.
  final int columns;

  /// Number of sticker rows in the sheet grid.
  final int rows;

  /// Gap distance between adjacent sticker columns in mm.
  final double columnGap;

  /// Gap distance between adjacent sticker rows in mm.
  final double rowGap;

  @override
  List<Object?> get props => [
        pageWidth,
        pageHeight,
        marginTop,
        marginBottom,
        marginLeft,
        marginRight,
        columns,
        rows,
        columnGap,
        rowGap,
      ];

  /// Creates a copy of this [SheetConfig] with the given fields replaced by new values.
  SheetConfig copyWith({
    double? pageWidth,
    double? pageHeight,
    double? marginTop,
    double? marginBottom,
    double? marginLeft,
    double? marginRight,
    int? columns,
    int? rows,
    double? columnGap,
    double? rowGap,
  }) {
    return SheetConfig(
      pageWidth: pageWidth ?? this.pageWidth,
      pageHeight: pageHeight ?? this.pageHeight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      columnGap: columnGap ?? this.columnGap,
      rowGap: rowGap ?? this.rowGap,
    );
  }
}
