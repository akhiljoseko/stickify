import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_print_jobs_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';
import 'package:stickify/presentation/features/dashboard/widgets/recent_print_row.dart';
import 'package:stickify/presentation/features/print/widgets/product_variant_selection_dialog.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Mobile-specific dashboard viewport layout.
class MobileDashboardScreen extends StatelessWidget {
  /// Creates a [MobileDashboardScreen].
  const MobileDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: BlocListener<SyncCubit, SyncState>(
        listener: (context, state) {
          if (state is SyncSuccess) {
            context.read<NotificationService>().showSuccess(
              'Synchronization complete! All templates and products updated.',
            );
            // Refresh data
            context.read<RecentPrintJobsCubit>().loadRecentJobs();
            context.read<FrequentVariantsCubit>().loadFrequentVariants();
          } else if (state is SyncFailure) {
            context.read<NotificationService>().showError(
              'Sync failed: ${state.error}',
            );
          }
        },
        child: Center(
          child: AdaptiveScrollWrapper(
            builder: (context, controller) => CustomScrollView(
              controller: controller,
              slivers: const [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _HeroHeader(),
                      SizedBox(height: 16),
                      _SyncBanner(),
                      SizedBox(height: 24),
                      _QuickActionsList(),
                      SizedBox(height: 24),
                      _RecentPrintsSection(),
                      SizedBox(height: 24),
                      _FrequentProductsSection(),
                      SizedBox(height: 24),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations',
          style: textTheme.displayLarge?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          'Mobile printer operations & details.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return BlocBuilder<SyncCubit, SyncState>(
      builder: (context, state) {
        final isLoading = state is SyncLoading;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colorScheme.primary.withValues(alpha: 0.08),
                colorScheme.primary.withValues(alpha: 0.03),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.sync_outlined,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Synchronization',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sync templates & products.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isLoading)
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton.filledTonal(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => context.read<SyncCubit>().syncData(),
                  tooltip: 'Sync Now',
                ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionsList extends StatelessWidget {
  const _QuickActionsList();

  static List<_QuickActionData> _actions(BuildContext context) => [
    _QuickActionData(
      icon: Icons.print_outlined,
      title: 'Start New Print',
      isPrimary: true,
      onTap: () => ProductVariantSelectionDialog.show(context),
    ),
    _QuickActionData(
      icon: Icons.add_circle_outline,
      title: 'Add Product',
      onTap: () => context.go('/products?subView=create'),
    ),
    _QuickActionData(
      icon: Icons.dashboard_customize_outlined,
      title: 'Create Template',
      onTap: () => context.go('/templates?action=create'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    return Row(
      children: [
        Expanded(
          child: _IconActionButton(
            icon: actions[0].icon,
            label: actions[0].title,
            isPrimary: true,
            onTap: actions[0].onTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IconActionButton(
            icon: actions[1].icon,
            label: actions[1].title,
            onTap: actions[1].onTap,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _IconActionButton(
            icon: actions[2].icon,
            label: actions[2].title,
            onTap: actions[2].onTap,
          ),
        ),
      ],
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isPrimary;
}

class _IconActionButton extends StatelessWidget {
  const _IconActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: isPrimary
          ? IconButton.filled(
            icon: Icon(icon),
            onPressed: onTap,
            tooltip: label,
          )
          : IconButton.outlined(
            icon: Icon(icon),
            onPressed: onTap,
            tooltip: label,
          ),
    );
  }
}

class _RecentPrintsSection extends StatelessWidget {
  const _RecentPrintsSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.update, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Recently Printed',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => const PrintHistoryRoute().push<void>(context),
              child: Text(
                'View All',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        BlocBuilder<RecentPrintJobsCubit, RecentPrintJobsState>(
          builder: (context, state) => switch (state) {
            RecentPrintJobsInitial() || RecentPrintJobsLoading() =>
              const _SectionLoadingIndicator(),
            RecentPrintJobsLoaded(:final jobs) => _RecentPrintsList(jobs: jobs),
            RecentPrintJobsError(:final message) => _SectionErrorView(
                message: message,
                onRetry: context.read<RecentPrintJobsCubit>().loadRecentJobs,
              ),
          },
        ),
      ],
    );
  }
}

class _RecentPrintsList extends StatelessWidget {
  const _RecentPrintsList({required this.jobs});
  final List<PrintJob> jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: jobs.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) {
        final job = jobs[i];
        return RecentPrintRow(
          job: job,
          onRepeatPrint: () => PrintSetupRoute(
            productId: job.productId,
            variantSku: job.variantSku,
            templateId: job.templateId,
            quantity: job.labelCount,
          ).go(context),
        );
      },
    );
  }
}

class _FrequentProductsSection extends StatelessWidget {
  const _FrequentProductsSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Frequent Used Products',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<FrequentVariantsCubit, FrequentVariantsState>(
          builder: (context, state) => switch (state) {
            FrequentVariantsInitial() || FrequentVariantsLoading() =>
              const _SectionLoadingIndicator(),
            FrequentVariantsLoaded(:final variants) =>
              _MobileVariantList(variants: variants),
            FrequentVariantsError(:final message) => _SectionErrorView(
                message: message,
                onRetry: context.read<FrequentVariantsCubit>().loadFrequentVariants,
              ),
          },
        ),
      ],
    );
  }
}

class _MobileVariantList extends StatelessWidget {
  const _MobileVariantList({required this.variants});
  final List<VariantPrintStats> variants;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: variants.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final v = variants[i];
        return _FrequentVariantCard(
          stats: v,
          onPrint: () {
            PrintTemplateSelectRoute(
              productId: v.productId,
              variantSku: v.variantSku,
            ).go(context);
          },
        );
      },
    );
  }
}

class _FrequentVariantCard extends StatelessWidget {
  const _FrequentVariantCard({
    required this.stats,
    required this.onPrint,
  });

  final VariantPrintStats stats;
  final VoidCallback onPrint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.label_important_outline,
                color: colorScheme.secondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stats.variantName,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      stats.variantSku,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${stats.totalPrints} prints',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  stats.productName,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            icon: const Icon(Icons.print_outlined, size: 20),
            onPressed: onPrint,
            tooltip: 'Quick Print',
          ),
        ],
      ),
    );
  }
}

class _SectionLoadingIndicator extends StatelessWidget {
  const _SectionLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _SectionErrorView extends StatelessWidget {
  const _SectionErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 28),
          const SizedBox(height: 8),
          Text(
            'Could not load data',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
