import 'package:stickify/core/core.dart';
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
      Log.warning(
        'Calibration rule generation skipped: no measurements provided.',
        tag: 'Calibration',
      );
      return CalibrationGenerationResult(generatedRules: const []);
    }

    Log.debug(
      'Computing calibration rules from ${measurements.length} measurement points.',
      tag: 'Calibration',
    );

    // 1. Compute average deltaX and deltaY across all measurement points -> global offset.
    double totalDeltaX = 0;
    double totalDeltaY = 0;
    for (final measurement in measurements) {
      totalDeltaX += measurement.deltaX;
      totalDeltaY += measurement.deltaY;
      Log.debug(
        '  Point "${measurement.point.label}": '
        'expected=(${measurement.point.expectedX}, ${measurement.point.expectedY}), '
        'actual=(${measurement.actualX}, ${measurement.actualY}), '
        'delta=(${measurement.deltaX}, ${measurement.deltaY})',
        tag: 'Calibration',
      );
    }
    final averageDeltaX = totalDeltaX / measurements.length;
    final averageDeltaY = totalDeltaY / measurements.length;
    Log.debug(
      '  Average mechanical offset: X=${averageDeltaX.toStringAsFixed(3)}mm, '
      'Y=${averageDeltaY.toStringAsFixed(3)}mm',
      tag: 'Calibration',
    );

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
          final ratio = measuredDist / expectedDist;
          horizontalPairs.add(ratio);
          Log.debug(
            '  X-pair "${m1.point.label}"↔"${m2.point.label}": '
            'expectedDist=${expectedDist}mm, measuredDist=${measuredDist.toStringAsFixed(3)}mm, '
            'ratio=$ratio',
            tag: 'Calibration',
          );
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
          final ratio = measuredDist / expectedDist;
          verticalPairs.add(ratio);
          Log.debug(
            '  Y-pair "${m1.point.label}"↔"${m2.point.label}": '
            'expectedDist=${expectedDist}mm, measuredDist=${measuredDist.toStringAsFixed(3)}mm, '
            'ratio=$ratio',
            tag: 'Calibration',
          );
        }
      }
    }
    if (verticalPairs.isNotEmpty) {
      scaleY = verticalPairs.reduce((a, b) => a + b) / verticalPairs.length;
    }

    Log.info(
      'Calibration computation complete. '
      'Offset applied: X=${(-averageDeltaX).toStringAsFixed(3)}mm, '
      'Y=${(-averageDeltaY).toStringAsFixed(3)}mm. '
      'Scaling applied: X=${scaleX.toStringAsFixed(5)}, '
      'Y=${scaleY.toStringAsFixed(5)}.',
      tag: 'Calibration',
    );

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
