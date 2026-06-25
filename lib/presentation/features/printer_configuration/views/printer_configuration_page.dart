import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_configuration/cubit/printer_configuration_cubit.dart';
import 'package:stickify/presentation/features/printer_configuration/cubit/printer_configuration_state.dart';
import 'package:stickify/presentation/features/printer_configuration/widgets/tray_configuration_sheet.dart';

class PrinterConfigurationPage extends StatelessWidget {
  const PrinterConfigurationPage({
    this.profileId,
    this.systemPrinterName,
    this.manufacturer,
    this.model,
    this.driverName,
    super.key,
  });

  final String? profileId;
  final String? systemPrinterName;
  final String? manufacturer;
  final String? model;
  final String? driverName;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = context
            .read<AppServiceLocator>()
            .createPrinterConfigurationCubit();
        if (profileId != null) {
          cubit.loadProfile(profileId!);
        }
        if (systemPrinterName != null && systemPrinterName!.isNotEmpty) {
          cubit
            ..setSystemPrinterName(systemPrinterName!)
            ..setDisplayName(systemPrinterName!)
            ..setManufacturer(manufacturer ?? '')
            ..setModel(model ?? '')
            ..setDriverName(driverName ?? '');
        }
        return cubit;
      },
      child: const _PrinterConfigurationView(),
    );
  }
}

class _PrinterConfigurationView extends StatelessWidget {
  const _PrinterConfigurationView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<PrinterConfigurationCubit, PrinterConfigurationState>(
      listener: (context, state) {
        if (state.status == PrinterConfigurationStatus.saved) {
          context.read<NotificationService>().showSuccess(
            state.isEditing
                ? 'Printer profile updated successfully!'
                : 'Printer profile created successfully!',
          );
          Navigator.of(context).pop(true);
        }
        if (state.status == PrinterConfigurationStatus.error &&
            state.errorMessage != null) {
          context.read<NotificationService>().showError(state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(state.isEditing ? 'Edit Printer' : 'New Printer'),
            actions: [
              TextButton(
                onPressed: state.status == PrinterConfigurationStatus.saving
                    ? null
                    : () => context
                          .read<PrinterConfigurationCubit>()
                          .save()
                          .then((_) {}),
                child: state.status == PrinterConfigurationStatus.saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfo(context, state),
                const SizedBox(height: 24),
                _buildCapabilities(context, state),
                const SizedBox(height: 24),
                _buildOptimizationPrefs(context, state),
                const SizedBox(height: 24),
                _buildTrayConfigurations(context, state),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: state.status == PrinterConfigurationStatus.saving
                        ? null
                        : () => context
                              .read<PrinterConfigurationCubit>()
                              .save()
                              .then((_) {}),
                    icon: state.status == PrinterConfigurationStatus.saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      state.isEditing
                          ? 'Save Changes'
                          : 'Create Printer Profile',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBasicInfo(
    BuildContext context,
    PrinterConfigurationState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Basic Info',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'READ-ONLY',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildReadOnlyField(
              context,
              icon: Icons.badge,
              label: 'System Printer Name',
              value: state.systemPrinterName.isNotEmpty
                  ? state.systemPrinterName
                  : '(not set)',
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              context,
              icon: Icons.settings_input_component,
              label: 'Model',
              value: state.model.isNotEmpty ? state.model : '(not set)',
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              context,
              icon: Icons.terminal,
              label: 'Driver',
              value: state.driverName.isNotEmpty
                  ? '${state.driverName} ${state.driverVersion}'
                  : '(not set)',
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Display Name',
                hintText: 'e.g. Warehouse Main Printer',
                border: OutlineInputBorder(),
              ),
              controller: TextEditingController(text: state.displayName)
                ..selection = TextSelection.collapsed(
                  offset: state.displayName.length,
                ),
              onChanged: (value) => context
                  .read<PrinterConfigurationCubit>()
                  .setDisplayName(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCapabilities(
    BuildContext context,
    PrinterConfigurationState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.biotech, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Capabilities',
                  style: textScheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hardware capabilities and constraints.',
              style: textScheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggle(
              context,
              label: 'Custom Paper Size',
              value: state.supportsCustomPaperSize,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setSupportsCustomPaperSize(v),
            ),
            _buildToggle(
              context,
              label: 'Portrait Custom Paper',
              value: state.supportsPortraitCustomPaper,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setSupportsPortraitCustomPaper(v),
            ),
            _buildToggle(
              context,
              label: 'Landscape Custom Paper',
              value: state.supportsLandscapeCustomPaper,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setSupportsLandscapeCustomPaper(v),
            ),
            _buildToggle(
              context,
              label: 'Manual Feed',
              value: state.supportsManualFeed,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setSupportsManualFeed(v),
            ),
            _buildToggle(
              context,
              label: 'Borderless Printing',
              value: state.supportsBorderlessPrinting,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setSupportsBorderlessPrinting(v),
            ),
            _buildToggle(
              context,
              label: 'Tray Selection',
              value: state.supportsTraySelection,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setSupportsTraySelection(v),
            ),
            const SizedBox(height: 16),
            Text(
              'Non-Printable Margins (mm)',
              style: textScheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMarginField(
                    context,
                    label: 'Top',
                    value: state.nonPrintableMarginTop,
                    onChanged: (v) => context
                        .read<PrinterConfigurationCubit>()
                        .setNonPrintableMarginTop(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMarginField(
                    context,
                    label: 'Bottom',
                    value: state.nonPrintableMarginBottom,
                    onChanged: (v) => context
                        .read<PrinterConfigurationCubit>()
                        .setNonPrintableMarginBottom(v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMarginField(
                    context,
                    label: 'Left',
                    value: state.nonPrintableMarginLeft,
                    onChanged: (v) => context
                        .read<PrinterConfigurationCubit>()
                        .setNonPrintableMarginLeft(v),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMarginField(
                    context,
                    label: 'Right',
                    value: state.nonPrintableMarginRight,
                    onChanged: (v) => context
                        .read<PrinterConfigurationCubit>()
                        .setNonPrintableMarginRight(v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle(
    BuildContext context, {
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }

  Widget _buildMarginField(
    BuildContext context, {
    required String label,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return TextField(
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixText: 'mm',
        isDense: true,
      ),
      controller: TextEditingController(text: value.toStringAsFixed(1))
        ..selection = TextSelection.collapsed(
          offset: value.toStringAsFixed(1).length,
        ),
      onChanged: (v) {
        final parsed = double.tryParse(v);
        if (parsed != null) onChanged(parsed);
      },
    );
  }

  Widget _buildOptimizationPrefs(
    BuildContext context,
    PrinterConfigurationState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Optimization Preferences',
                  style: textScheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Layout engine correction preferences.',
              style: textScheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            _buildToggle(
              context,
              label: 'Allow Scaling',
              value: state.allowScaling,
              onChanged: (v) =>
                  context.read<PrinterConfigurationCubit>().setAllowScaling(v),
            ),
            _buildToggle(
              context,
              label: 'Allow Translation',
              value: state.allowTranslation,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setAllowTranslation(v),
            ),
            _buildToggle(
              context,
              label: 'Prefer Shrink Over Shift',
              value: state.preferShrinkOverShift,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setPreferShrinkOverShift(v),
            ),
            _buildToggle(
              context,
              label: 'Allow Sticker-Specific Adjustment',
              value: state.allowStickerSpecificAdjustment,
              onChanged: (v) => context
                  .read<PrinterConfigurationCubit>()
                  .setAllowStickerSpecificAdjustment(v),
            ),
            const SizedBox(height: 12),
            TextField(
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minimum Acceptable Scale',
                border: OutlineInputBorder(),
                suffixText: '%',
                isDense: true,
              ),
              controller:
                  TextEditingController(
                      text: (state.minimumAcceptableScale * 100)
                          .toStringAsFixed(0),
                    )
                    ..selection = TextSelection.collapsed(
                      offset: (state.minimumAcceptableScale * 100)
                          .toStringAsFixed(0)
                          .length,
                    ),
              onChanged: (v) {
                final parsed = double.tryParse(v);
                if (parsed != null) {
                  context
                      .read<PrinterConfigurationCubit>()
                      .setMinimumAcceptableScale(parsed / 100);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrayConfigurations(
    BuildContext context,
    PrinterConfigurationState state,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inbox, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Tray Configurations',
                  style: textScheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.trays.length} ${state.trays.length == 1 ? 'tray' : 'trays'}',
                    style: textScheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...state.trays.asMap().entries.map((entry) {
              final index = entry.key;
              final tray = entry.value;
              return _buildTrayCard(context, tray, index);
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _addTray(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Tray'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrayCard(
    BuildContext context,
    PrinterTrayProfile tray,
    int index,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textScheme = theme.textTheme;

    final isCalibrated =
        tray.calibration.enabled &&
        tray.calibration.calibrationRules.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tray.displayName,
                      style: textScheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isCalibrated
                          ? colorScheme.tertiaryContainer
                          : colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCalibrated ? 'CALIBRATED' : 'UNCALIBRATED',
                      style: textScheme.labelSmall?.copyWith(
                        color: isCalibrated
                            ? colorScheme.tertiary
                            : colorScheme.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Identifier: ${tray.trayIdentifier}',
                style: textScheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildTrayAction(
                    context,
                    icon: Icons.tune,
                    label: 'Calibrate',
                    onTap: () => _calibrateTray(context, tray, index),
                    disabled: !isCalibrated,
                  ),
                  const SizedBox(width: 8),
                  _buildTrayAction(
                    context,
                    icon: Icons.edit,
                    label: 'Edit',
                    onTap: () => _editTray(context, tray, index),
                  ),
                  const SizedBox(width: 8),
                  _buildTrayAction(
                    context,
                    icon: Icons.delete,
                    label: 'Remove',
                    onTap: () => _removeTray(context, index),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrayAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextButton.icon(
      onPressed: disabled ? null : onTap,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  Future<void> _addTray(BuildContext context) async {
    final tray = await TrayConfigurationSheet.show(context: context);
    if (tray != null && context.mounted) {
      context.read<PrinterConfigurationCubit>().addTray(tray);
    }
  }

  Future<void> _editTray(
    BuildContext context,
    PrinterTrayProfile tray,
    int index,
  ) async {
    final updated = await TrayConfigurationSheet.show(
      context: context,
      existingTray: tray,
    );
    if (updated != null && context.mounted) {
      context.read<PrinterConfigurationCubit>().updateTray(index, updated);
    }
  }

  void _removeTray(BuildContext context, int index) {
    context.read<PrinterConfigurationCubit>().removeTray(index);
  }

  void _calibrateTray(
    BuildContext context,
    PrinterTrayProfile tray,
    int index,
  ) {
    final state = context.read<PrinterConfigurationCubit>().state;
    final profile = state.existingProfile;
    if (profile == null) {
      context.read<NotificationService>().showWarning(
        'Save the profile first before calibrating a tray.',
      );
      return;
    }

    if (tray.supportedPaperConfigurations.isEmpty) {
      context.read<NotificationService>().showWarning(
        'Add a paper configuration to the tray before calibrating.',
      );
      return;
    }

    unawaited(
      CalibrationWizardRoute(
        profileId: profile.id,
        trayId: tray.trayIdentifier,
        paperConfigurationId: tray.supportedPaperConfigurations.first.id,
      ).push<void>(context),
    );
  }
}
