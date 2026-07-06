import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_cubit.dart';
import 'package:stickify/presentation/features/printer_management/widgets/compatibility_indicator.dart';
import 'package:stickify/presentation/features/printer_management/widgets/printer_status_badge.dart';

/// A card widget displaying the details, status, and compatibility of a [PrinterProfileMatchResult].
class PrinterCard extends StatelessWidget {
  /// Creates a [PrinterCard] instance.
  const PrinterCard({
    required this.matchResult,
    this.compatibility,
    super.key,
  });

  /// The match result for the printer profile.
  final PrinterProfileMatchResult matchResult;

  /// The compatibility analysis result, if available.
  final PrinterProfileCompatibility? compatibility;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final profile = matchResult.profile;
    final isMissing = matchResult.status == PrinterProfileMatchStatus.missing;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isMissing ? colorScheme.error.withValues(alpha: 0.5) : colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Profile Name & Action / Status Badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isMissing ? colorScheme.error : colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isMissing)
                        Text(
                          'Expected System Name: ${profile.printerIdentity.systemPrinterName}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      else ...[
                        Text(
                          'Discovered: ${matchResult.discoveredPrinter!.systemPrinterName}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (matchResult.discoveredPrinter!.manufacturer.isNotEmpty ||
                            matchResult.discoveredPrinter!.model.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${matchResult.discoveredPrinter!.manufacturer} ${matchResult.discoveredPrinter!.model}'.trim(),
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                // Match Status Indicator
                _buildMatchStatusBadge(context, matchResult.status),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Runtime Status & Compatibility Pill
            if (!isMissing) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PrinterStatusBadge(status: matchResult.discoveredPrinter!.status),
                  if (compatibility != null)
                    CompatibilityIndicator(status: compatibility!.status),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Row 3: Missing Details / Actions
            if (isMissing) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This printer is offline or has been disconnected from the system.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Action Placeholders
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Action Placeholder
                    },
                    icon: const Icon(Icons.settings_suggest_outlined, size: 16),
                    label: const Text('Reassign Printer'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              ),
            ],

            // Row 4: Compatibility Issues
            if (compatibility != null && compatibility!.issues.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                'Compatibility Issues (${compatibility!.issues.length}):',
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...compatibility!.issues.map((issue) => _buildIssueRow(context, issue)),
            ],

            // Actions Row — hidden when missing since profile cannot be edited
            if (!isMissing) ...[
              const Divider(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;

                  final candidates = <_PrinterAction>[
                    _PrinterAction(
                      id: 'delete',
                      width: 110,
                      button: TextButton.icon(
                        key: const ValueKey('delete_btn'),
                        onPressed: () => _confirmDelete(context, profile),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.error,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      menuEntry: PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: colorScheme.error)),
                          ],
                        ),
                      ),
                    ),
                    _PrinterAction(
                      id: 'edit',
                      width: 150,
                      button: TextButton.icon(
                        key: const ValueKey('edit_profile_btn'),
                        onPressed: () => PrinterConfigurationEditRoute(
                          profileId: profile.id,
                        ).push<void>(context),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit Profile'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                      menuEntry: PopupMenuItem<String>(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: colorScheme.onSurfaceVariant, size: 20),
                            const SizedBox(width: 8),
                            const Text('Edit Profile'),
                          ],
                        ),
                      ),
                    ),
                    if (profile.trays.isNotEmpty)
                      _PrinterAction(
                        id: 'calibrate',
                        width: 130,
                        button: _buildCalibrateMenu(context, profile),
                        menuEntry: PopupMenuItem<String>(
                          value: 'calibrate',
                          child: Row(
                            children: [
                              Icon(Icons.tune, color: colorScheme.onSurfaceVariant, size: 20),
                              const SizedBox(width: 8),
                              const Text('Calibrate'),
                            ],
                          ),
                        ),
                      ),
                  ];

                  int getPriority(String id) {
                    if (id == 'calibrate') return 2;
                    if (id == 'edit') return 1;
                    return 0;
                  }

                  final prioritySorted = List<_PrinterAction>.from(candidates)
                    ..sort((a, b) => getPriority(b.id).compareTo(getPriority(a.id)));

                  final visible = <_PrinterAction>[];
                  final overflow = <_PrinterAction>[];

                  double totalWidthAll = 0;
                  for (var i = 0; i < candidates.length; i++) {
                    totalWidthAll += candidates[i].width;
                    if (i > 0) totalWidthAll += 4.0;
                  }

                  if (totalWidthAll <= availableWidth) {
                    visible.addAll(candidates);
                  } else {
                    var currentWidth = 48.0;
                    var hasOverflowed = false;
                    for (final candidate in prioritySorted) {
                      if (hasOverflowed) {
                        overflow.add(candidate);
                        continue;
                      }
                      final needed = candidate.width + (visible.isEmpty ? 0 : 4.0);
                      if (currentWidth + needed <= availableWidth) {
                        visible.add(candidate);
                        currentWidth += needed;
                      } else {
                        overflow.add(candidate);
                        hasOverflowed = true;
                      }
                    }
                    visible.sort((a, b) => candidates.indexOf(a).compareTo(candidates.indexOf(b)));
                    overflow.sort((a, b) => candidates.indexOf(a).compareTo(candidates.indexOf(b)));
                  }

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ...List.generate(visible.length, (index) {
                        final button = visible[index].button;
                        if (index == 0) return button;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: button,
                        );
                      }),
                      if (overflow.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            tooltip: 'More actions',
                            onSelected: (value) {
                              if (value == 'calibrate') {
                                _handleCalibrate(context, profile);
                              } else if (value == 'edit') {
                                PrinterConfigurationEditRoute(
                                  profileId: profile.id,
                                ).push<void>(context);
                              } else if (value == 'delete') {
                                _confirmDelete(context, profile);
                              }
                            },
                            itemBuilder: (context) => overflow.map((action) => action.menuEntry).toList(),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchStatusBadge(BuildContext context, PrinterProfileMatchStatus status) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.labelSmall;

    final Color color;
    final String text;

    switch (status) {
      case PrinterProfileMatchStatus.matched:
        color = const Color(0xFF10B981); // Green
        text = 'Exact Match';
      case PrinterProfileMatchStatus.compatible:
        color = Colors.blue;
        text = 'Compatible Model';
      case PrinterProfileMatchStatus.incompatible:
        color = colorScheme.error;
        text = 'Incompatible Model';
      case PrinterProfileMatchStatus.missing:
        color = Colors.orange;
        text = 'Missing';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: textStyle?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, PrinterProfile profile) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Printer Profile'),
        content: Text(
          'Are you sure you want to delete "${profile.displayName}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              context.read<PrinterManagementCubit>().deleteProfile(profile.id);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _handleCalibrate(BuildContext context, PrinterProfile profile) {
    if (profile.trays.length == 1) {
      final tray = profile.trays.first;
      if (tray.supportedPaperConfigurations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Add a paper configuration to the tray before calibrating.'),
          ),
        );
        return;
      }
      CalibrationWizardRoute(
        profileId: profile.id,
        trayId: tray.trayIdentifier,
        paperConfigurationId: tray.supportedPaperConfigurations.first.id,
      ).push<void>(context);
    } else {
      _showCalibrateTrayDialog(context, profile);
    }
  }

  void _showCalibrateTrayDialog(BuildContext context, PrinterProfile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Tray to Calibrate'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: profile.trays.map((tray) {
              final isCalibrated = tray.calibration.enabled &&
                  tray.calibration.calibrationRules.isNotEmpty;
              return ListTile(
                leading: Icon(
                  isCalibrated ? Icons.tune : Icons.tune_outlined,
                  color: isCalibrated
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                title: Text(tray.displayName),
                onTap: () {
                  Navigator.of(ctx).pop();
                  if (tray.supportedPaperConfigurations.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add a paper configuration to the tray before calibrating.'),
                      ),
                    );
                    return;
                  }
                  CalibrationWizardRoute(
                    profileId: profile.id,
                    trayId: tray.trayIdentifier,
                    paperConfigurationId: tray.supportedPaperConfigurations.first.id,
                  ).push<void>(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrateMenu(BuildContext context, PrinterProfile profile) {
    return PopupMenuButton<String>(
      onSelected: (trayId) {
        final tray = profile.trays.firstWhere((t) => t.trayIdentifier == trayId);
        if (tray.supportedPaperConfigurations.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add a paper configuration to the tray before calibrating.'),
            ),
          );
          return;
        }
        CalibrationWizardRoute(
          profileId: profile.id,
          trayId: trayId,
          paperConfigurationId: tray.supportedPaperConfigurations.first.id,
        ).push<void>(context);
      },
      itemBuilder: (context) => profile.trays.map((tray) {
        final isCalibrated = tray.calibration.enabled &&
            tray.calibration.calibrationRules.isNotEmpty;
        return PopupMenuItem<String>(
          value: tray.trayIdentifier,
          child: Row(
            children: [
              Icon(
                isCalibrated ? Icons.tune : Icons.tune_outlined,
                size: 18,
                color: isCalibrated
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isCalibrated
                      ? 'Recalibrate ${tray.displayName}'
                      : 'Calibrate ${tray.displayName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: TextButton.icon(
        onPressed: null,
        icon: const Icon(Icons.tune, size: 16),
        label: const Text('Calibrate'),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }

  Widget _buildIssueRow(BuildContext context, PrinterCompatibilityIssue issue) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall;

    final IconData icon;
    final Color color;

    switch (issue.severity) {
      case PrinterCompatibilityStatus.compatible:
        icon = Icons.check_circle_outline;
        color = const Color(0xFF10B981);
      case PrinterCompatibilityStatus.warning:
        icon = Icons.warning_amber_rounded;
        color = Colors.orange;
      case PrinterCompatibilityStatus.incompatible:
        icon = Icons.error_outline_rounded;
        color = colorScheme.error;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              issue.message,
              style: textStyle?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrinterAction {
  const _PrinterAction({
    required this.id,
    required this.button,
    required this.width,
    required this.menuEntry,
  });

  final String id;
  final Widget button;
  final double width;
  final PopupMenuEntry<String> menuEntry;
}
