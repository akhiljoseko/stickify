import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_state.dart';
import 'package:stickify/presentation/features/printer_management/widgets/measurement_entry_form.dart';

/// Page container for the Technician Calibration Wizard.
class CalibrationWizardPage extends StatelessWidget {
  /// Creates a [CalibrationWizardPage] instance.
  const CalibrationWizardPage({
    required this.profileId,
    required this.trayId,
    required this.paperConfigurationId,
    super.key,
  });

  /// The ID of the printer profile.
  final String profileId;

  /// The ID of the tray profile.
  final String trayId;

  /// The ID of the paper configuration.
  final String paperConfigurationId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          context.read<AppServiceLocator>().createCalibrationSessionCubit(
            profileId: profileId,
            trayId: trayId,
            paperConfigurationId: paperConfigurationId,
          )..loadSession(),
      child: const CalibrationWizardView(),
    );
  }
}

/// The actual presentation view for the Calibration Wizard.
class CalibrationWizardView extends StatefulWidget {
  /// Creates a [CalibrationWizardView] instance.
  const CalibrationWizardView({super.key});

  @override
  State<CalibrationWizardView> createState() => _CalibrationWizardViewState();
}

class _CalibrationWizardViewState extends State<CalibrationWizardView> {
  int _activeStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Calibration Wizard'),
      ),
      body: BlocConsumer<CalibrationSessionCubit, CalibrationSessionState>(
        listener: (context, state) {
          if (state.status == CalibrationSessionStatus.saved) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Calibration saved successfully!')),
            );
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          if (state.status == CalibrationSessionStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CalibrationSessionStatus.error &&
              _activeStep == 0) {
            return _buildErrorScreen(
              context,
              state.errorMessage ?? 'An error occurred.',
            );
          }

          return Column(
            children: [
              _buildStepIndicator(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(context, state),
                ),
              ),
              _buildNavigationButtons(context, state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepTitle(0, 'Print'),
          _buildDivider(),
          _buildStepTitle(1, 'Measure'),
          _buildDivider(),
          _buildStepTitle(2, 'Save'),
        ],
      ),
    );
  }

  Widget _buildStepTitle(int stepIndex, String title) {
    final theme = Theme.of(context);
    final isActive = _activeStep == stepIndex;
    final isDone = _activeStep > stepIndex;

    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone
              ? Colors.green
              : (isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text(
                  '${stepIndex + 1}',
                  style: const TextStyle(fontSize: 11, color: Colors.white),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 40,
      height: 1,
      color: Colors.grey[400],
      margin: const EdgeInsets.symmetric(horizontal: 16),
    );
  }

  Widget _buildStepContent(
    BuildContext context,
    CalibrationSessionState state,
  ) {
    switch (_activeStep) {
      case 0:
        return _buildPrintStep(context, state);
      case 1:
        return _buildMeasurementsStep(context, state);
      case 2:
        return _buildReviewStep(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPrintStep(BuildContext context, CalibrationSessionState state) {
    final theme = Theme.of(context);
    final isPrinting = state.status == CalibrationSessionStatus.printingSheet;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            const Icon(Icons.print_outlined, size: 72, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'Print Calibration Sheet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Load standard paper in the selected tray and click the print button below. '
              'The printed sheet will contain registration marks, rulers, and target crosshairs that you will need to measure with a caliper or ruler.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (isPrinting) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Sending job to printer...'),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () => context
                    .read<CalibrationSessionCubit>()
                    .printCalibrationSheet(),
                icon: const Icon(Icons.print),
                label: const Text('Print Calibration Sheet'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                ),
              ),
              if (state.status == CalibrationSessionStatus.sheetPrinted) ...[
                const SizedBox(height: 24),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Sheet printed successfully! Click Next to proceed.'),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementsStep(
    BuildContext context,
    CalibrationSessionState state,
  ) {
    final template = state.selectedTemplate;
    if (template == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter Physical Measurements',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Use a physical ruler or caliper to measure the exact coordinates of the center of each printed red crosshair from the page borders (Top and Left). Enter the measured values in millimeters.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ...template.points.map((point) {
              final measurement = state.measurements.firstWhere(
                (m) => m.point.id == point.id,
                orElse: () => CalibrationMeasurement(
                  point: point,
                  actualX: point.expectedX,
                  actualY: point.expectedY,
                ),
              );

              return MeasurementEntryForm(
                point: point,
                actualX: measurement.actualX,
                actualY: measurement.actualY,
                onChanged: (x, y) {
                  context.read<CalibrationSessionCubit>().addMeasurement(
                    CalibrationMeasurement(
                      point: point,
                      actualX: x,
                      actualY: y,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewStep(BuildContext context, CalibrationSessionState state) {
    final theme = Theme.of(context);
    final isSaving = state.status == CalibrationSessionStatus.saving;

    if (state.generatedRules.isEmpty) {
      return const Center(child: Text('No calibration rules generated yet.'));
    }

    final rule = state.generatedRules.first;
    final transform = rule.transformation;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            const Icon(
              Icons.assessment_outlined,
              size: 72,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            Text(
              'Review Calibration Rules',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The calibration wizard has compiled the following corrections for your printer tray:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildResultRow(
                      'X Offset Adjustment',
                      '${transform.offsetX > 0 ? '+' : ''}${transform.offsetX.toStringAsFixed(2)} mm',
                    ),
                    const Divider(),
                    _buildResultRow(
                      'Y Offset Adjustment',
                      '${transform.offsetY > 0 ? '+' : ''}${transform.offsetY.toStringAsFixed(2)} mm',
                    ),
                    const Divider(),
                    _buildResultRow(
                      'Horizontal Scaling',
                      '${(transform.scaleX * 100).toStringAsFixed(1)}%',
                    ),
                    const Divider(),
                    _buildResultRow(
                      'Vertical Scaling',
                      '${(transform.scaleY * 100).toStringAsFixed(1)}%',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (isSaving) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Saving calibration to profile...'),
            ] else if (state.status == CalibrationSessionStatus.error) ...[
              Text(
                state.errorMessage ?? 'Failed to save profile.',
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    context.read<CalibrationSessionCubit>().saveCalibration(),
                child: const Text('Try Saving Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen(BuildContext context, String message) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72, color: theme.colorScheme.error),
            const SizedBox(height: 24),
            Text(
              'An Error Occurred',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  context.read<CalibrationSessionCubit>().loadSession(),
              child: const Text('Retry Loading Session'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(
    BuildContext context,
    CalibrationSessionState state,
  ) {
    final canGoNext = _canGoNext(state);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeStep > 0)
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _activeStep--;
                });
              },
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: canGoNext
                ? () {
                    if (_activeStep == 1) {
                      context.read<CalibrationSessionCubit>().generateRules();
                    } else if (_activeStep == 2) {
                      context.read<CalibrationSessionCubit>().saveCalibration();
                      return;
                    }
                    setState(() {
                      _activeStep++;
                    });
                  }
                : null,
            child: Text(_activeStep == 2 ? 'Save & Close' : 'Next'),
          ),
        ],
      ),
    );
  }

  bool _canGoNext(CalibrationSessionState state) {
    if (_activeStep == 0) {
      return state.status == CalibrationSessionStatus.sheetPrinted;
    }
    if (_activeStep == 1) {
      return state.status == CalibrationSessionStatus.measurementsComplete;
    }
    if (_activeStep == 2) {
      return state.status == CalibrationSessionStatus.rulesGenerated;
    }
    return false;
  }
}
