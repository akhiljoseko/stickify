import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_cubit.dart';
import 'package:stickify/presentation/features/printer_management/cubit/printer_management_state.dart';
import 'package:stickify/presentation/features/printer_management/widgets/empty_printer_state.dart';
import 'package:stickify/presentation/features/printer_management/widgets/printer_card.dart';
import 'package:stickify/presentation/features/printer_management/widgets/printer_selection_sheet.dart';

class PrinterManagementPage extends StatelessWidget {
  const PrinterManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => context.read<AppServiceLocator>().createPrinterManagementCubit()
        ..loadPrintersAndProfiles(),
      child: const PrinterManagementView(),
    );
  }
}

class PrinterManagementView extends StatelessWidget {
  const PrinterManagementView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.breakpoint.name == AppBreakpoints.desktop ||
        bp.breakpoint.name == AppBreakpoints.fourK;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Printers'),
        actions: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => unawaited(_addPrinterProfile(context)),
              tooltip: 'Add Printer Profile',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PrinterManagementCubit>().loadPrintersAndProfiles(),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: BlocBuilder<PrinterManagementCubit, PrinterManagementState>(
        builder: (context, state) {
          switch (state.status) {
            case PrinterManagementStatus.initial:
            case PrinterManagementStatus.loading:
              return const Center(
                child: CircularProgressIndicator(),
              );

            case PrinterManagementStatus.failure:
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 48,
                        color: colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load printers',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage ?? 'An unexpected error occurred.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () =>
                            context.read<PrinterManagementCubit>().loadPrintersAndProfiles(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              );

            case PrinterManagementStatus.loaded:
              if (state.matches.isEmpty) {
                return EmptyPrinterState(
                  title: 'No printer profiles configured',
                  message: 'Add a printer profile to begin configuring label formats.',
                  icon: Icons.print_disabled_outlined,
                  actionText: 'Add Printer Profile',
                  onAction: () => unawaited(_addPrinterProfile(context)),
                );
              }

              if (state.discoveredPrinterCount == 0) {
                return EmptyPrinterState(
                  title: 'Printers Unavailable',
                  message: 'Your configured printers are currently unavailable. Check connections or power status.',
                  icon: Icons.portable_wifi_off_outlined,
                  actionText: 'Scan for Printers',
                  onAction: () =>
                      context.read<PrinterManagementCubit>().loadPrintersAndProfiles(),
                );
              }

              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with title + add button (desktop)
                    if (isDesktop)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${state.matches.length} Printer(s)',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => unawaited(_addPrinterProfile(context)),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Printer Profile'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Subtitle
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                      child: Text(
                        'Configure printers, trays and calibration profiles.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Grid (desktop) or List (mobile)
                    Expanded(
                      child: isDesktop
                          ? _buildGridView(context, state)
                          : _buildListView(context, state),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  Widget _buildListView(BuildContext context, PrinterManagementState state) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: state.matches.length,
      itemBuilder: (context, index) {
        final match = state.matches[index];
        final compatibility = state.compatibilityResults[match.profile.id];
        return PrinterCard(
          matchResult: match,
          compatibility: compatibility,
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, PrinterManagementState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 3 : 2;
        final cardWidth = (constraints.maxWidth - (crossAxisCount + 1) * 16) / crossAxisCount;
        // Estimated card height based on content
        final childAspectRatio = cardWidth / 240;

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: state.matches.length,
          itemBuilder: (context, index) {
            final match = state.matches[index];
            final compatibility = state.compatibilityResults[match.profile.id];
            return PrinterCard(
              matchResult: match,
              compatibility: compatibility,
            );
          },
        );
      },
    );
  }
}

Future<void> _addPrinterProfile(BuildContext context) async {
  final locator = context.read<AppServiceLocator>();

  try {
    final printers = await locator.printerDiscoveryService.getDiscoveredPrinters();
    if (!context.mounted) return;

    if (printers.isEmpty) {
      context.read<NotificationService>().showWarning(
        'No printers discovered. Ensure a printer is connected and powered on.',
      );
      return;
    }

    final selected = await PrinterSelectionSheet.show(
      context: context,
      printers: printers,
    );

    if (selected != null && context.mounted) {
      final saved = await PrinterConfigurationRoute(
        systemPrinterName: selected.systemPrinterName,
        manufacturer: selected.manufacturer,
        model: selected.model,
        driverName: selected.driverName,
      ).push<bool>(context);

      if (saved == true && context.mounted) {
        context.read<NotificationService>().showSuccess(
          'Printer profile "${selected.systemPrinterName}" created successfully.',
        );
        await context.read<PrinterManagementCubit>().loadPrintersAndProfiles();
      }
    }
  } catch (e) {
    if (!context.mounted) return;
    await BlockingErrorDialog.show(
      context,
      title: 'Failed to Add Printer',
      message: 'An unexpected error occurred while discovering printers: $e',
      onRetry: () => unawaited(_addPrinterProfile(context)),
      onClose: () {},
    );
  }
}
