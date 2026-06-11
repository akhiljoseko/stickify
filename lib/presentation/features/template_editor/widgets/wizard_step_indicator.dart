import 'package:flutter/material.dart';
import 'package:stickify/core/utils/adaptive_value.dart';

/// Visual wizard step indicator shown at the top of the template setup process.
///
/// Supports responsive scaling to adapt from small screens to larger viewports.
class WizardStepIndicator extends StatelessWidget {
  /// Creates a [WizardStepIndicator] instance.
  const WizardStepIndicator({
    required this.currentStep,
    super.key,
  });

  /// The active step index (1: Sheet Config, 2: Sticker Setup, 3: Label Designer, 4: Final Preview).
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final steps = [
      'Sheet Config',
      'Sticker Setup',
      'Label Designer',
      'Final Preview',
    ];

    // Check if we should show text labels based on width (e.g. hide on mobile)
    final showLabels = AdaptiveValue<bool>(
      context,
      defaultValue: false, // mobile
      tablet: true,        // tablet
      desktop: true,       // desktop/4k
    ).value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Divider line between steps
            final stepIndex = index ~/ 2;
            final isCompleted = stepIndex < currentStep - 1;
            return Container(
              width: showLabels ? 40 : 20,
              height: 2,
              color: isCompleted ? colorScheme.primary : colorScheme.outlineVariant,
            );
          }

          final stepIndex = index ~/ 2;
          final stepNum = stepIndex + 1;
          final isActive = stepNum == currentStep;
          final isCompleted = stepNum < currentStep;

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted
                      ? colorScheme.primary
                      : isActive
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                  border: Border.all(
                    color: (isActive || isCompleted)
                        ? colorScheme.primary
                        : colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: isCompleted
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: colorScheme.onPrimary,
                        )
                      : Text(
                          '$stepNum',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
              if (showLabels) ...[
                const SizedBox(width: 8),
                Text(
                  steps[stepIndex],
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: isActive || isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: isActive
                        ? colorScheme.primary
                        : isCompleted
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
