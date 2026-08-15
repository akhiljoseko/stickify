import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_batch_summaries_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_print_jobs_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_cubit.dart';
import 'package:stickify/presentation/features/dashboard/presentation/desktop/desktop_dashboard_screen.dart';
import 'package:stickify/presentation/features/dashboard/presentation/mobile/mobile_dashboard_screen.dart';

/// Entry point wrapper for the Dashboard route.
///
/// Handles Dependency Injection (DI) and dynamically routes to the layout matching the form factor experience.
class DashboardPage extends StatelessWidget {
  /// Creates a [DashboardPage].
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (blocContext) {
            final cubit = RecentPrintJobsCubit(
              printJobRepository: blocContext.read<PrintJobRepository>(),
            );
            unawaited(cubit.loadRecentJobs());
            return cubit;
          },
        ),
        BlocProvider(
          create: (blocContext) {
            final cubit = FrequentProductsCubit(
              variantPrintStatsRepository: blocContext
                  .read<VariantPrintStatsRepository>(),
            );
            unawaited(cubit.loadFrequentVariants());
            return cubit;
          },
        ),
        BlocProvider<RecentBatchSummariesCubit>(
          create: (blocContext) {
            final cubit = RecentBatchSummariesCubit(
              batchPrintSummaryRepository:
                  blocContext.read<BatchPrintSummaryRepository>(),
            );
            unawaited(cubit.loadSummaries());
            return cubit;
          },
        ),
        BlocProvider(
          create: (blocContext) => SyncCubit(
            productRepo: blocContext.read<SyncableProductRepository>(),
            templateRepo: blocContext.read<SyncableTemplateRepository>(),
            printerProfileRepo: blocContext.read<SyncablePrinterProfileRepository>(),
            auth: blocContext.read<AuthService>(),
          ),
        ),
      ],
      child: const _AdaptiveDashboardLayout(),
    );
  }
}

class _AdaptiveDashboardLayout extends StatefulWidget {
  const _AdaptiveDashboardLayout();

  @override
  State<_AdaptiveDashboardLayout> createState() => _AdaptiveDashboardLayoutState();
}

class _AdaptiveDashboardLayoutState extends State<_AdaptiveDashboardLayout> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    super.dispose();
  }

  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return false;

    final isCtrl = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;

    // Ctrl + O / Cmd + O: Open Order/Batch Print Wizard
    if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyO) {
      context.push('/order-label-print');
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();

    switch (env.experience) {
      case AppExperience.mobile:
        return const MobileDashboardScreen();
      case AppExperience.tablet:
      case AppExperience.desktop:
        return const DesktopDashboardScreen();
    }
  }
}
