import 'package:equatable/equatable.dart';

class SheetConfig extends Equatable {
  const SheetConfig({
    required this.pageSize,
    required this.marginTop,
    required this.marginBottom,
    required this.marginLeft,
    required this.marginRight,
    required this.columns,
    required this.rows,
    required this.columnGap,
    required this.rowGap,
  });

  final String pageSize;          // e.g. "A4", "Letter", "Custom"
  final double marginTop;         // mm
  final double marginBottom;      // mm
  final double marginLeft;        // mm
  final double marginRight;       // mm
  final int columns;
  final int rows;
  final double columnGap;         // mm
  final double rowGap;            // mm

  @override
  List<Object?> get props => [
        pageSize,
        marginTop,
        marginBottom,
        marginLeft,
        marginRight,
        columns,
        rows,
        columnGap,
        rowGap,
      ];

  SheetConfig copyWith({
    String? pageSize,
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
      pageSize: pageSize ?? this.pageSize,
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
