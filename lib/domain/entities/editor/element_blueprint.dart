import 'package:equatable/equatable.dart';

abstract class ElementBlueprint extends Equatable {
  const ElementBlueprint({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.rotation,
  });

  final String id;
  final double x;        // canvas-relative logical pixels
  final double y;        // canvas-relative logical pixels
  final double width;    // width in logical pixels
  final double height;   // height in logical pixels
  final double rotation; // rotation in degrees

  @override
  List<Object?> get props => [id, x, y, width, height, rotation];

  /// Abstract copyWith to be implemented by sub-classes
  ElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
  });
}
