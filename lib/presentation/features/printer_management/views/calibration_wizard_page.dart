import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/calibration_session_state.dart';
import 'package:stickify/presentation/features/printer_management/widgets/measurement_entry_form.dart';

class CalibrationWizardPage extends StatelessWidget {
  const CalibrationWizardPage({
    required this.profileId,
    required this.trayId,
    required this.paperConfigurationId,
    super.key,
  });

  final String profileId;
  final String trayId;
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

class CalibrationWizardView extends StatefulWidget {
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
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          if (state.status == CalibrationSessionStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == CalibrationSessionStatus.error &&
              _activeStep == 0) {
            return _buildErrorScreen(context, state);
          }

          final totalSteps = state.isExistingTray ? 4 : 5;
          final stepTitles = state.isExistingTray
              ? ['Print', 'Margins', 'Crosshairs', 'Review']
              : ['Tray', 'Print', 'Margins', 'Crosshairs', 'Review'];

          return Column(
            children: [
              _buildStepIndicator(context, totalSteps, stepTitles, state),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _buildStepContent(context, state),
                ),
              ),
              _buildNavigationButtons(context, state, totalSteps),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    int totalSteps,
    List<String> stepTitles,
    CalibrationSessionState state,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (index) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index > 0) _buildStepDivider(),
              _buildStepDot(index, _activeStep, stepTitles[index], colorScheme),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStepDot(
      int index, int active, String title, ColorScheme colorScheme) {
    final isActive = index == active;
    final isDone = index < active;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: title,
        child: Container(
          width: isActive ? 32 : 24,
          height: isActive ? 32 : 24,
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green
                : (isActive ? colorScheme.primary : colorScheme.outline),
            shape: BoxShape.circle,
          ),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: isActive ? 13 : 11,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 24,
      height: 1,
      color: Colors.grey[400],
    );
  }

  Widget _buildStepContent(
      BuildContext context, CalibrationSessionState state) {
    final actualStep = state.isExistingTray ? _activeStep + 1 : _activeStep;

    switch (actualStep) {
      case 0:
        return _buildTrayDetailsStep(context, state);
      case 1:
        return _buildPrintStep(context, state);
      case 2:
        return _buildMarginStep(context, state);
      case 3:
        return _buildCrosshairStep(context, state);
      case 4:
        return _buildReviewStep(context, state);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 1: Tray Details ──────────────────────────────────────────────

  Widget _buildTrayDetailsStep(
      BuildContext context, CalibrationSessionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.inbox, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('Tray Details',
                style: textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Set up the tray you want to calibrate. '
              'You can change these later from the profile edit screen.',
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tray Name',
                hintText: 'e.g. Main Feed Tray',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              controller: TextEditingController(text: state.trayDisplayName)
                ..selection = TextSelection.collapsed(
                    offset: state.trayDisplayName.length),
              onChanged: (v) => context
                  .read<CalibrationSessionCubit>()
                  .setTrayDisplayName(v),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tray Identifier',
                hintText: 'e.g. tray-1',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.terminal),
              ),
              controller: TextEditingController(text: state.trayIdentifier)
                ..selection = TextSelection.collapsed(
                    offset: state.trayIdentifier.length),
              onChanged: (v) => context
                  .read<CalibrationSessionCubit>()
                  .setTrayIdentifier(v),
            ),
            const SizedBox(height: 24),
            Text('Supported Templates',
                style: textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Select which templates this tray can print.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            if (state.availableTemplates.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No templates available. Create templates first.',
                        style: textTheme.bodySmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...state.availableTemplates.map((t) {
                final selected = state.selectedTemplateIds.contains(t.id);
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(t.name, style: textTheme.bodyMedium),
                  subtitle: t.sheetConfig != null
                      ? Text(
                          '${t.sheetConfig!.pageWidth} x ${t.sheetConfig!.pageHeight} mm',
                          style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant))
                      : null,
                  value: selected,
                  onChanged: (_) => context
                      .read<CalibrationSessionCubit>()
                      .toggleTemplate(t.id),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Print Calibration Sheet ────────────────────────────────────

  Widget _buildPrintStep(
      BuildContext context, CalibrationSessionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;
    final isPrinting = state.status == CalibrationSessionStatus.printingSheet;
    final isPrinted = state.status == CalibrationSessionStatus.sheetPrinted;
    final profile = state.printerProfile;
    final tray = state.trayProfile;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Icon(Icons.print_outlined, size: 64, color: colorScheme.primary),
            const SizedBox(height: 20),
            Text('Print Calibration Sheet',
                style: textScheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            if (profile != null && tray != null)
              Card(
                color: colorScheme.surfaceContainerLowest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildInfoRow(
                          Icons.print, 'Printer', profile.displayName),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                          Icons.inbox, 'Tray', tray.displayName),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBullet(textScheme, colorScheme,
                      Icons.straighten, '12mm grey bands at each edge'),
                  const SizedBox(height: 8),
                  _buildBullet(textScheme, colorScheme,
                      Icons.my_location, 'Red crosshairs at 4 corners'),
                  const SizedBox(height: 8),
                  _buildBullet(textScheme, colorScheme,
                      Icons.horizontal_rule, 'Millimeter rulers (top and left edges)'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isPrinting)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Printing calibration sheet...'),
                ],
              )
            else ...[
              ElevatedButton.icon(
                onPressed: isPrinting
                    ? null
                    : () => context
                        .read<CalibrationSessionCubit>()
                        .printCalibrationSheet(),
                icon: const Icon(Icons.print),
                label: const Text('Print Calibration Sheet'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
              ),
              if (isPrinted) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600]),
                    const SizedBox(width: 8),
                    Text('Sheet printed.',
                        style: textScheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text('$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(
            child: Text(value,
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildBullet(TextTheme textTheme, ColorScheme colorScheme,
      IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(text, style: textTheme.bodySmall),
      ],
    );
  }

  // ─── Step 3: Measure Margins ────────────────────────────────────────────

  Widget _buildMarginStep(
      BuildContext context, CalibrationSessionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.straighten, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('Measure Non-Printable Margins',
                style: textScheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Look at your printed sheet. The grey bands around the edges '
              'mark the area where the printer could not place ink.\n\n'
              'Measure the distance from the paper edge to where the grey '
              'band starts. Enter each measurement in millimeters.',
              style: textScheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Measure from the paper edge, not from the grey band.',
                      style: textScheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildMarginField(
                    'Top (mm)',
                    state.nonPrintableMarginTop,
                    (v) => context
                        .read<CalibrationSessionCubit>()
                        .setMarginTop(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMarginField(
                    'Bottom (mm)',
                    state.nonPrintableMarginBottom,
                    (v) => context
                        .read<CalibrationSessionCubit>()
                        .setMarginBottom(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMarginField(
                    'Left (mm)',
                    state.nonPrintableMarginLeft,
                    (v) => context
                        .read<CalibrationSessionCubit>()
                        .setMarginLeft(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMarginField(
                    'Right (mm)',
                    state.nonPrintableMarginRight,
                    (v) => context
                        .read<CalibrationSessionCubit>()
                        .setMarginRight(v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarginField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: 'mm',
        isDense: true,
      ),
      controller: TextEditingController(text: value.toStringAsFixed(1))
        ..selection =
            TextSelection.collapsed(offset: value.toStringAsFixed(1).length),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  // ─── Step 4: Measure Crosshairs ────────────────────────────────────────

  Widget _buildCrosshairStep(
      BuildContext context, CalibrationSessionState state) {
    final template = state.selectedTemplate;
    if (template == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.my_location, size: 48, color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('Measure Crosshair Positions',
                style: textScheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'For each red crosshair on the printed sheet, measure its '
              'distance from the TOP and LEFT paper edges in millimeters. '
              'Enter the values below.',
              style: textScheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
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

  // ─── Step 5: Review & Save ────────────────────────────────────────────

  Widget _buildReviewStep(
      BuildContext context, CalibrationSessionState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;
    final isSaving = state.status == CalibrationSessionStatus.saving;

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          children: [
            Icon(Icons.assessment_outlined,
                size: 64, color: Colors.green[600]),
            const SizedBox(height: 20),
            Text('Calibration Complete',
                style: textScheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Tray + Margins Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tray',
                        style: textScheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text(
                      '${state.trayDisplayName.isNotEmpty ? state.trayDisplayName : state.trayProfile?.displayName ?? ""} '
                      '(${state.trayIdentifier.isNotEmpty ? state.trayIdentifier : state.trayProfile?.trayIdentifier ?? ""})',
                      style: textScheme.bodyMedium),
                    const SizedBox(height: 12),
                    Text('Non-Printable Margins',
                        style: textScheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(
                      'Top: ${state.nonPrintableMarginTop.toStringAsFixed(1)} mm  '
                      'Bottom: ${state.nonPrintableMarginBottom.toStringAsFixed(1)} mm  '
                      'Left: ${state.nonPrintableMarginLeft.toStringAsFixed(1)} mm  '
                      'Right: ${state.nonPrintableMarginRight.toStringAsFixed(1)} mm',
                      style: textScheme.bodySmall),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Calibration Results
            if (state.generatedRules.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text('Calibration Corrections',
                          style: textScheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary)),
                      const SizedBox(height: 12),
                      _buildResultRow('X Offset',
                          '${state.generatedRules.first.transformation.offsetX.toStringAsFixed(2)} mm'),
                      const Divider(),
                      _buildResultRow('Y Offset',
                          '${state.generatedRules.first.transformation.offsetY.toStringAsFixed(2)} mm'),
                      const Divider(),
                      _buildResultRow(
                        'X Scale',
                        '${(state.generatedRules.first.transformation.scaleX * 100).toStringAsFixed(1)}%',
                      ),
                      const Divider(),
                      _buildResultRow(
                        'Y Scale',
                        '${(state.generatedRules.first.transformation.scaleY * 100).toStringAsFixed(1)}%',
                      ),
                    ],
                  ),
                ),
              ),
            if (isSaving) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Saving calibration...'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  // ─── Error Screen ─────────────────────────────────────────────────────

  Widget _buildErrorScreen(
      BuildContext context, CalibrationSessionState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 72,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 24),
            Text('An Error Occurred',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(state.errorMessage ?? 'An unexpected error occurred.',
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () =>
                  context.read<CalibrationSessionCubit>().loadSession(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Navigation Buttons ────────────────────────────────────────────────

  Widget _buildNavigationButtons(
    BuildContext context,
    CalibrationSessionState state,
    int totalSteps,
  ) {
    final canGoNext = _canGoNext(state);
    final actualStep = state.isExistingTray ? _activeStep + 1 : _activeStep;
    final isLastStep = _activeStep == totalSteps - 1;

    return Container(
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_activeStep > (state.isExistingTray ? 0 : 0))
            OutlinedButton(
              onPressed: () => setState(() => _activeStep--),
              child: const Text('Back'),
            )
          else
            const SizedBox.shrink(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Skip Print button on print step
              if (actualStep == 1 &&
                  state.status != CalibrationSessionStatus.sheetPrinted)
                TextButton(
                  onPressed: () {
                    context.read<CalibrationSessionCubit>().skipPrint();
                    setState(() => _activeStep++);
                  },
                  child: const Text('Skip Print'),
                ),
              const SizedBox(width: 8),
              // Skip margins? No, margins are required. Just Next.
              ElevatedButton(
                onPressed: canGoNext
                    ? () {
                        if (actualStep == 0) {
                          context
                              .read<CalibrationSessionCubit>()
                              .saveTrayDetails();
                        } else if (actualStep == 1 &&
                            state.status ==
                                CalibrationSessionStatus.sheetPrinted) {
                          context
                              .read<CalibrationSessionCubit>()
                              .proceedToMargins();
                        } else if (actualStep == 2) {
                          context
                              .read<CalibrationSessionCubit>()
                              .saveMargins();
                        } else if (actualStep == 3) {
                          context
                              .read<CalibrationSessionCubit>()
                              .generateRules();
                        } else if (isLastStep) {
                          context
                              .read<CalibrationSessionCubit>()
                              .saveCalibration();
                          return;
                        }
                        setState(() => _activeStep++);
                      }
                    : null,
                child: Text(isLastStep ? 'Save Calibration' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canGoNext(CalibrationSessionState state) {
    final actualStep = state.isExistingTray ? _activeStep + 1 : _activeStep;

    switch (actualStep) {
      case 0:
        return state.trayDisplayName.isNotEmpty &&
            state.trayIdentifier.isNotEmpty;
      case 1:
        return state.status == CalibrationSessionStatus.sheetPrinted ||
            state.status == CalibrationSessionStatus.measuringMargins ||
            state.status == CalibrationSessionStatus.marginMeasurementDone;
      case 2:
        return true;
      case 3:
        return state.status == CalibrationSessionStatus.measurementsComplete;
      case 4:
        return state.status == CalibrationSessionStatus.rulesGenerated;
      default:
        return false;
    }
  }
}
