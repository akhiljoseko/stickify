import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/optimization_level.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';

/// Represents a selected print optimization strategy with per-sticker transforms.
class OptimizationStrategy extends Equatable {
  /// Creates an [OptimizationStrategy] instance.
  OptimizationStrategy({
    required this.level,
    required this.description,
    required Map<int, PrintStickerTransform> transforms,
  }) : transforms = Map.unmodifiable(transforms);

  /// The optimization level applied.
  final OptimizationLevel level;

  /// Human-readable explanation of why this strategy was chosen.
  final String description;

  /// The transformations to apply per sticker slot, keyed by absolute slot index.
  final Map<int, PrintStickerTransform> transforms;

  @override
  List<Object?> get props => [
        level,
        description,
        transforms,
      ];
}
