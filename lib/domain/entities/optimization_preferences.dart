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
    this.minimumAcceptableScale = 0.7,
  }) : assert(
          minimumAcceptableScale > 0.0 && minimumAcceptableScale <= 1.0,
          'minimumAcceptableScale must be in (0.0, 1.0]',
        );

  /// Whether the layout engine is allowed to scale down stickers to fit margins.
  final bool allowScaling;

  /// Whether the layout engine is allowed to apply translation shifts to stickers.
  final bool allowTranslation;

  /// If clipping occurs, whether to prefer scaling down (shrinking) over shifting.
  final bool preferShrinkOverShift;

  /// Whether the calibration engine can apply transformations to specific slot indexes.
  final bool allowStickerSpecificAdjustment;

  /// The minimum scale factor allowed when shrinking sticker content to fit margins.
  final double minimumAcceptableScale;

  /// Creates a copy of this [OptimizationPreferences] with the given fields replaced.
  OptimizationPreferences copyWith({
    bool? allowScaling,
    bool? allowTranslation,
    bool? preferShrinkOverShift,
    bool? allowStickerSpecificAdjustment,
    double? minimumAcceptableScale,
  }) {
    return OptimizationPreferences(
      allowScaling: allowScaling ?? this.allowScaling,
      allowTranslation: allowTranslation ?? this.allowTranslation,
      preferShrinkOverShift: preferShrinkOverShift ?? this.preferShrinkOverShift,
      allowStickerSpecificAdjustment:
          allowStickerSpecificAdjustment ?? this.allowStickerSpecificAdjustment,
      minimumAcceptableScale:
          minimumAcceptableScale ?? this.minimumAcceptableScale,
    );
  }

  @override
  List<Object?> get props => [
        allowScaling,
        allowTranslation,
        preferShrinkOverShift,
        allowStickerSpecificAdjustment,
        minimumAcceptableScale,
      ];

  @override
  String toString() =>
      'OptimizationPreferences('
      'allowScaling: $allowScaling, '
      'allowTranslation: $allowTranslation, '
      'preferShrinkOverShift: $preferShrinkOverShift, '
      'allowStickerSpecificAdjustment: $allowStickerSpecificAdjustment, '
      'minimumAcceptableScale: $minimumAcceptableScale)';
}
