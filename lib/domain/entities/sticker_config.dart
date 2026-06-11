import 'package:equatable/equatable.dart';

/// Represents a 2D coordinate point defining a boundary of a sticker.
class StickerPoint extends Equatable {
  /// Creates a [StickerPoint] at coordinates ([x], [y]).
  const StickerPoint(this.x, this.y);
  
  /// X-coordinate value.
  final double x;

  /// Y-coordinate value.
  final double y;

  @override
  List<Object?> get props => [x, y];
}

/// Defines the physical layout configuration and bounds of a single sticker.
class StickerConfig extends Equatable {
  /// Creates a [StickerConfig] specification.
  const StickerConfig({
    required this.widthMm,
    required this.heightMm,
    required this.cornerRadiusMm,
    required this.printableArea,
  });

  /// Width of the sticker in millimeters (mm).
  final double widthMm;

  /// Height of the sticker in millimeters (mm).
  final double heightMm;

  /// Corner radius of the sticker in millimeters (mm) for rounded rectangular cutouts.
  final double cornerRadiusMm;
  
  /// Polygon representing the printable area, defined by ordered edge coordinates.
  final List<StickerPoint> printableArea;

  @override
  List<Object?> get props => [
        widthMm,
        heightMm,
        cornerRadiusMm,
        printableArea,
      ];

  /// Creates a copy of this [StickerConfig] with the given fields replaced by new values.
  StickerConfig copyWith({
    double? widthMm,
    double? heightMm,
    double? cornerRadiusMm,
    List<StickerPoint>? printableArea,
  }) {
    return StickerConfig(
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      cornerRadiusMm: cornerRadiusMm ?? this.cornerRadiusMm,
      printableArea: printableArea ?? this.printableArea,
    );
  }
}
