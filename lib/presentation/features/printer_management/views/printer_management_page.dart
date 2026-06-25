import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/app_service_locator.dart';
import 'package:stickify/app/routing/router.dart';
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Printer Management'),
        actions: [
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Printers',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reconcile physical hardware with configured label templates.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.matches.length,
                          itemBuilder: (context, index) {
                            final match = state.matches[index];
                            final compatibility = state.compatibilityResults[match.profile.id];
                            return PrinterCard(
                              matchResult: match,
                              compatibility: compatibility,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
          }
        },
      ),
    );
  }
}

Future<void> _addPrinterProfile(BuildContext context) async {
  final locator = context.read<AppServiceLocator>();
  final printers = await locator.printerDiscoveryService.getDiscoveredPrinters();
  if (!context.mounted) return;

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
      await context.read<PrinterManagementCubit>().loadPrintersAndProfiles();
    }
  }
}
