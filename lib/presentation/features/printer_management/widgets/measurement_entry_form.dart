import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/widgets/setup_fields.dart';

/// Entry form widget for entering the technician's measurements for a single target point.
class MeasurementEntryForm extends StatelessWidget {
  /// Creates a [MeasurementEntryForm] instance.
  const MeasurementEntryForm({
    required this.point,
    required this.actualX,
    required this.actualY,
    required this.onChanged,
    super.key,
  });

  /// The calibration measurement point.
  final CalibrationMeasurementPoint point;

  /// The currently entered actual X measurement.
  final double actualX;

  /// The currently entered actual Y measurement.
  final double actualY;

  /// Callback triggered when either coordinate changes.
  final void Function(double actualX, double actualY) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target Point: ${point.label}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Expected Position: X = ${point.expectedX.toStringAsFixed(1)} mm, Y = ${point.expectedY.toStringAsFixed(1)} mm',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: SetupNumberField(
                    key: ValueKey('actual_x_${point.id}'),
                    value: actualX,
                    labelText: 'Measured X (mm)',
                    onChanged: (val) => onChanged(val, actualY),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: SetupNumberField(
                    key: ValueKey('actual_y_${point.id}'),
                    value: actualY,
                    labelText: 'Measured Y (mm)',
                    onChanged: (val) => onChanged(actualX, val),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
