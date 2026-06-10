import 'package:equatable/equatable.dart';

class StickerPoint extends Equatable {
  const StickerPoint(this.x, this.y);
  
  final double x;
  final double y;

  @override
  List<Object?> get props => [x, y];
}

class StickerConfig extends Equatable {
  const StickerConfig({
    required this.widthMm,
    required this.heightMm,
    required this.cornerRadiusMm,
    required this.printableArea,
  });

  final double widthMm;
  final double heightMm;
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
