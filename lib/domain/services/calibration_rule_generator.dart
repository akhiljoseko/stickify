import 'package:stickify/domain/entities/calibration_generation_request.dart';
import 'package:stickify/domain/entities/calibration_generation_result.dart';
import 'package:stickify/domain/entities/calibration_rule.dart';
import 'package:stickify/domain/entities/print_coordinate_context.dart';

/// Pure domain service that transforms a [CalibrationGenerationRequest]
/// into a [CalibrationGenerationResult].
class CalibrationRuleGenerator {
  /// Creates a [CalibrationRuleGenerator] instance.
  const CalibrationRuleGenerator();

  /// Generates calibration rules from a [CalibrationGenerationRequest].
  CalibrationGenerationResult generate(CalibrationGenerationRequest request) {
    final session = request.session;
    final measurements = session.measurements;

    if (measurements.isEmpty) {
      return CalibrationGenerationResult(generatedRules: const []);
    }

    // 1. Compute average deltaX and deltaY across all measurement points -> global offset.
    double totalDeltaX = 0;
    double totalDeltaY = 0;
    for (final measurement in measurements) {
      totalDeltaX += measurement.deltaX;
      totalDeltaY += measurement.deltaY;
    }
    final averageDeltaX = totalDeltaX / measurements.length;
    final averageDeltaY = totalDeltaY / measurements.length;

    // 2. Compute scale deviation per axis.
    double scaleX = 1;
    final horizontalPairs = <double>[];
    for (var i = 0; i < measurements.length; i++) {
      for (var j = i + 1; j < measurements.length; j++) {
        final m1 = measurements[i];
        final m2 = measurements[j];
        if (m1.point.expectedX != m2.point.expectedX) {
          final expectedDist = (m2.point.expectedX - m1.point.expectedX).abs();
          final measuredDist = (m2.actualX - m1.actualX).abs();
          horizontalPairs.add(measuredDist / expectedDist);
        }
      }
    }
    if (horizontalPairs.isNotEmpty) {
      scaleX = horizontalPairs.reduce((a, b) => a + b) / horizontalPairs.length;
    }

    double scaleY = 1;
    final verticalPairs = <double>[];
    for (var i = 0; i < measurements.length; i++) {
      for (var j = i + 1; j < measurements.length; j++) {
        final m1 = measurements[i];
        final m2 = measurements[j];
        if (m1.point.expectedY != m2.point.expectedY) {
          final expectedDist = (m2.point.expectedY - m1.point.expectedY).abs();
          final measuredDist = (m2.actualY - m1.actualY).abs();
          verticalPairs.add(measuredDist / expectedDist);
        }
      }
    }
    if (verticalPairs.isNotEmpty) {
      scaleY = verticalPairs.reduce((a, b) => a + b) / verticalPairs.length;
    }

    // 3. Generate a single CalibrationRule targeting TargetType.sheet.
    final rule = CalibrationRule(
      target: const CalibrationTarget.sheet(),
      transformation: PrintStickerTransform(
        offsetX: -averageDeltaX,
        offsetY: -averageDeltaY,
        scaleX: scaleX,
        scaleY: scaleY,
      ),
    );

    return CalibrationGenerationResult(
      generatedRules: [rule],
    );
  }
}
