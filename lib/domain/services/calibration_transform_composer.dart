import 'package:stickify/domain/entities/calibration_rule.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';

/// Composes a set of applicable calibration rules into a single effective transformation.
///
/// ## Composition Rules
/// * **Translation**: Offset parameters are fully cumulative. The final translation offset
///   (`offsetX` and `offsetY`) is the sum of offsets across all matching rules.
/// * **Scale X & Scale Y**: Resolved independently per axis.
///   1. Filter matching rules where the scale on that axis is not equal to 1.0.
///   2. Select the rule with the highest target specificity:
///      `Sticker (5) > Edge (4) > Column (3) > Row (2) > Sheet (1)`.
///   3. If multiple rules share the highest specificity, choose the one with the smallest scale
///      value on that axis (prioritizing shrinking over clipping).
///   4. If no scaling rules apply on an axis, the identity scale of 1.0 is used.
/// * **Anchor X & Anchor Y**: Resolved independently per axis.
///   - The winning scaling rule for an axis provides the anchor for that axis.
///   - If no scaling rule applies on an axis, the identity anchor value of 0.5 is used.
///
/// The resulting [PrintStickerTransform] is a composed transformation that may combine
/// translations from multiple rules, horizontal scaling and horizontal anchor from one rule,
/// and vertical scaling and vertical anchor from another rule.
class CalibrationTransformComposer {
  /// Creates a [CalibrationTransformComposer] instance.
  const CalibrationTransformComposer();

  /// Composes the list of [matchingRules] into a single [PrintStickerTransform].
  PrintStickerTransform compose(List<CalibrationRule> matchingRules) {
    if (matchingRules.isEmpty) {
      return const PrintStickerTransform.identity();
    }

    // 1. Translation is cumulative
    double offsetX = 0;
    double offsetY = 0;
    for (final rule in matchingRules) {
      offsetX += rule.transformation.offsetX;
      offsetY += rule.transformation.offsetY;
    }

    // 2. Resolve Scale X & Anchor X
    CalibrationRule? winningXRule;
    for (final rule in matchingRules) {
      if (rule.transformation.scaleX == 1.0) continue;
      if (winningXRule == null) {
        winningXRule = rule;
      } else {
        final winningSpec = _getSpecificity(winningXRule.target.type);
        final currentSpec = _getSpecificity(rule.target.type);
        if (currentSpec > winningSpec) {
          winningXRule = rule;
        } else if (currentSpec == winningSpec) {
          if (rule.transformation.scaleX < winningXRule.transformation.scaleX) {
            winningXRule = rule;
          }
        }
      }
    }

    // 3. Resolve Scale Y & Anchor Y
    CalibrationRule? winningYRule;
    for (final rule in matchingRules) {
      if (rule.transformation.scaleY == 1.0) continue;
      if (winningYRule == null) {
        winningYRule = rule;
      } else {
        final winningSpec = _getSpecificity(winningYRule.target.type);
        final currentSpec = _getSpecificity(rule.target.type);
        if (currentSpec > winningSpec) {
          winningYRule = rule;
        } else if (currentSpec == winningSpec) {
          if (rule.transformation.scaleY < winningYRule.transformation.scaleY) {
            winningYRule = rule;
          }
        }
      }
    }

    final scaleX = winningXRule?.transformation.scaleX ?? 1.0;
    final anchorX = winningXRule?.transformation.anchorX ?? 0.5;

    final scaleY = winningYRule?.transformation.scaleY ?? 1.0;
    final anchorY = winningYRule?.transformation.anchorY ?? 0.5;

    return PrintStickerTransform(
      offsetX: offsetX,
      offsetY: offsetY,
      scaleX: scaleX,
      scaleY: scaleY,
      anchorX: anchorX,
      anchorY: anchorY,
    );
  }

  /// Composes two [PrintStickerTransform] instances.
  ///
  /// Translation offsets are additive. Scaling factors are multiplied.
  /// The anchor of the second transform takes precedence if it applies scaling.
  PrintStickerTransform composeTwo(PrintStickerTransform first, PrintStickerTransform second) {
    final scaleX = first.scaleX * second.scaleX;
    final scaleY = first.scaleY * second.scaleY;

    final anchorX = second.scaleX != 1.0 ? second.anchorX : first.anchorX;
    final anchorY = second.scaleY != 1.0 ? second.anchorY : first.anchorY;

    return PrintStickerTransform(
      offsetX: first.offsetX + second.offsetX,
      offsetY: first.offsetY + second.offsetY,
      scaleX: scaleX,
      scaleY: scaleY,
      anchorX: anchorX,
      anchorY: anchorY,
    );
  }

  int _getSpecificity(TargetType type) {
    switch (type) {
      case TargetType.sticker:
        return 5;
      case TargetType.edge:
        return 4;
      case TargetType.column:
        return 3;
      case TargetType.row:
        return 2;
      case TargetType.sheet:
        return 1;
    }
  }
}
