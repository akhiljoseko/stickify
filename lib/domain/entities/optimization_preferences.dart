import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents a technician's configuration overrides and limits for layout
/// engine optimization logic.
@immutable
class OptimizationPreferences extends Equatable {
  /// Creates an [OptimizationPreferences] instance.
  const OptimizationPreferences({
    required this.allowScaling,
    required this.allowTranslation,
    required this.preferShrinkOverShift,
    required this.allowStickerSpecificAdjustment,
  });

  /// Whether the layout engine is allowed to scale down stickers to fit margins.
  final bool allowScaling;

  /// Whether the layout engine is allowed to apply translation shifts to stickers.
  final bool allowTranslation;

  /// If clipping occurs, whether to prefer scaling down (shrinking) over shifting.
  final bool preferShrinkOverShift;

  /// Whether the calibration engine can apply transformations to specific slot indexes.
  final bool allowStickerSpecificAdjustment;

  @override
  List<Object?> get props => [
        allowScaling,
        allowTranslation,
        preferShrinkOverShift,
        allowStickerSpecificAdjustment,
      ];

  @override
  String toString() =>
      'OptimizationPreferences('
      'allowScaling: $allowScaling, '
      'allowTranslation: $allowTranslation, '
      'preferShrinkOverShift: $preferShrinkOverShift, '
      'allowStickerSpecificAdjustment: $allowStickerSpecificAdjustment)';
}
