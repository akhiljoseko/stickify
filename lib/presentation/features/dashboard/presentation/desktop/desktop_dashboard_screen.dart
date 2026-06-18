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
import 'package:stickify/presentation/features/dashboard/widgets/frequent_product_row.dart';
import 'package:stickify/presentation/features/dashboard/widgets/quick_action_card.dart';
import 'package:stickify/presentation/features/dashboard/widgets/recent_print_row.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Desktop-specific dashboard viewport layout.
class DesktopDashboardScreen extends StatelessWidget {
  /// Creates a [DesktopDashboardScreen].
  const DesktopDashboardScreen({super.key});

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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: AdaptiveScrollWrapper(
              builder: (context, controller) => CustomScrollView(
                controller: controller,
                slivers: const [
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      _HeroHeader(),
                      SizedBox(height: 32),
                      _QuickActionsGrid(),
                      SizedBox(height: 32),
                      _RecentPrintsSection(),
                      SizedBox(height: 32),
                      _FrequentProductsSection(),
                      SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Operations Dashboard',
                style: textTheme.displayLarge?.copyWith(fontSize: 32),
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time printer network status and rapid-access controls.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        BlocBuilder<SyncCubit, SyncState>(
          builder: (context, state) {
            final isLoading = state is SyncLoading;
            return FilledButton.icon(
              icon: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.sync, size: 16),
              label: Text(isLoading ? 'Syncing...' : 'Sync Data'),
              onPressed: isLoading ? null : () => context.read<SyncCubit>().syncData(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const List<_QuickActionData> _actions = [
    _QuickActionData(
      id: FeatureId.productCatalogAdmin,
      icon: Icons.add_circle_outline,
      title: 'Add New Product',
      subtitle: 'Register SKU & Metadata',
      isPrimary: true,
    ),
    _QuickActionData(
      id: FeatureId.templateCreation,
      icon: Icons.dashboard_customize_outlined,
      title: 'Create Template',
      subtitle: 'Visual designer tool',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w < 480 ? 1 : 2;
        const targetHeight = 160.0;

        final itemWidth = (w - (crossAxisCount - 1) * 16) / crossAxisCount;
        final childAspectRatio = itemWidth / targetHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _actions.length,
          itemBuilder: (context, i) {
            final action = _actions[i];
            return QuickActionCard(
              icon: action.icon,
              title: action.title,
              subtitle: action.subtitle,
              isPrimary: action.isPrimary,
              onTap: () {
                if (action.id == FeatureId.productCatalogAdmin) {
                  context.go('/products?subView=create');
                } else if (action.id == FeatureId.templateCreation) {
                  context.go('/templates?action=create');
                }
              },
            );
          },
        );
      },
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPrimary = false,
  });

  final FeatureId id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
}

class _RecentPrintsSection extends StatelessWidget {
  const _RecentPrintsSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.update, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recently Printed Labels',
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => const PrintHistoryRoute().push<void>(context),
                  child: Text(
                    'View History',
                    style: textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _PrintTableColumnHeaders(colorScheme: colorScheme, textTheme: textTheme),
          BlocBuilder<RecentPrintJobsCubit, RecentPrintJobsState>(
            builder: (context, state) => switch (state) {
              RecentPrintJobsInitial() || RecentPrintJobsLoading() =>
                const _SectionLoadingIndicator(),
              RecentPrintJobsLoaded(:final jobs) =>
                _RecentPrintsTable(jobs: jobs),
              RecentPrintJobsError(:final message) => _SectionErrorView(
                  message: message,
                  onRetry: context.read<RecentPrintJobsCubit>().loadRecentJobs,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _PrintTableColumnHeaders extends StatelessWidget {
  const _PrintTableColumnHeaders({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _HeaderCell(label: 'Variant & SKU', flex: 3, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Template', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Count', flex: 1, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Printed', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(width: 36),
          ),
        ],
      ),
    );
  }
}

class _RecentPrintsTable extends StatelessWidget {
  const _RecentPrintsTable({required this.jobs});
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
          isEvenRow: i.isEven,
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.star_outline, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Frequent Used Products',
                    style: textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          _TableColumnHeaders(colorScheme: colorScheme, textTheme: textTheme),
          BlocBuilder<FrequentVariantsCubit, FrequentVariantsState>(
            builder: (context, state) => switch (state) {
              FrequentVariantsInitial() || FrequentVariantsLoading() =>
                const _SectionLoadingIndicator(),
              FrequentVariantsLoaded(:final variants) =>
                _DesktopVariantsTable(variants: variants),
              FrequentVariantsError(:final message) => _SectionErrorView(
                  message: message,
                  onRetry: context.read<FrequentVariantsCubit>().loadFrequentVariants,
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _TableColumnHeaders extends StatelessWidget {
  const _TableColumnHeaders({
    required this.colorScheme,
    required this.textTheme,
  });

  final ColorScheme colorScheme;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _HeaderCell(label: 'Variant & Product', flex: 3, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Last Printed', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Total Prints', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SizedBox(width: 48),
          ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final int flex;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DesktopVariantsTable extends StatelessWidget {
  const _DesktopVariantsTable({required this.variants});
  final List<VariantPrintStats> variants;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: variants.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) => FrequentVariantRow(
        stats: variants[i],
        isEvenRow: i.isEven,
        onQuickPrint: () {
          final v = variants[i];
          PrintTemplateSelectRoute(
            productId: v.productId,
            variantSku: v.variantSku,
          ).go(context);
        },
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
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 32),
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
