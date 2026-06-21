import 'package:equatable/equatable.dart';

/// Represents the hardware printable margins of a printer.
class PrinterMargins extends Equatable {
  /// Constructor for creating printer margins representation.
  const PrinterMargins({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Creates a [PrinterMargins] instance from a JSON map.
  factory PrinterMargins.fromJson(Map<String, dynamic> json) => PrinterMargins(
        left: (json['left'] as num).toDouble(),
        top: (json['top'] as num).toDouble(),
        right: (json['right'] as num).toDouble(),
        bottom: (json['bottom'] as num).toDouble(),
      );

  /// Left margin in millimeters.
  final double left;

  /// Top margin in millimeters.
  final double top;

  /// Right margin in millimeters.
  final double right;

  /// Bottom margin in millimeters.
  final double bottom;

  /// Creates a [PrinterMargins] instance with zero margins.
  static const zero = PrinterMargins(left: 0, top: 0, right: 0, bottom: 0);

  /// Converts this [PrinterMargins] instance to a JSON map.
  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };

  @override
  List<Object?> get props => [left, top, right, bottom];
}
