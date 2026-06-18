import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
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
            final cubit = FrequentVariantsCubit(
              variantPrintStatsRepository: blocContext.read<VariantPrintStatsRepository>(),
            );
            unawaited(cubit.loadFrequentVariants());
            return cubit;
          },
        ),
        BlocProvider(
          create: (blocContext) => SyncCubit(
            productRepo: blocContext.read<SyncableProductRepository>(),
            templateRepo: blocContext.read<SyncableTemplateRepository>(),
            auth: blocContext.read<AuthService>(),
          ),
        ),
      ],
      child: const _AdaptiveDashboardLayout(),
    );
  }
}

class _AdaptiveDashboardLayout extends StatelessWidget {
  const _AdaptiveDashboardLayout();

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
