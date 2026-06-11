import 'package:equatable/equatable.dart';

/// Base class for all layout elements in a label design template.
///
/// Defines the core placement and dimension attributes (x, y coordinates,
/// width, height, and rotation) required for rendering elements on the editor canvas
/// or when outputting to PDF.
abstract class ElementBlueprint extends Equatable {
  /// Abstract constructor for the base element layout.
  const ElementBlueprint({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
  });

  /// Unique identifier of this blueprint element instance.
  final String id;

  /// X-coordinate of the element relative to the canvas origin (logical pixels).
  final double x;

  /// Y-coordinate of the element relative to the canvas origin (logical pixels).
  final double y;

  /// Width of the element (logical pixels).
  final double width;

  /// Height of the element (logical pixels).
  final double height;

  /// Clockwise rotation angle of the element in degrees.
  final double rotation;

  @override
  List<Object?> get props => [id, x, y, width, height, rotation];

  /// Returns a copy of the blueprint with modified properties.
  ElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  });
}
