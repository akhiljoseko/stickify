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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final deltaX = actualX - point.expectedX;
    final deltaY = actualY - point.expectedY;
    final hasDelta = deltaX != 0 || deltaY != 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Target: ${point.label}',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Expected: X = ${point.expectedX.toStringAsFixed(1)} mm, '
              'Y = ${point.expectedY.toStringAsFixed(1)} mm',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (hasDelta) ...[
              const SizedBox(height: 2),
              Text(
                'Your delta: X = ${deltaX >= 0 ? "+" : ""}${deltaX.toStringAsFixed(1)} mm, '
                'Y = ${deltaY >= 0 ? "+" : ""}${deltaY.toStringAsFixed(1)} mm',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
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
                const SizedBox(width: 16),
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
