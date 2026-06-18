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
import 'package:stickify/presentation/features/print/widgets/product_variant_selection_dialog.dart';
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
              onPressed: isLoading
                  ? null
                  : () => context.read<SyncCubit>().syncData(),
            );
          },
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static List<_QuickActionData> _actions(BuildContext context) => [
    _QuickActionData(
      icon: Icons.print_outlined,
      title: 'Start New Print',
      subtitle: 'Select product & template',
      isPrimary: true,
      onTap: () => ProductVariantSelectionDialog.show(context),
    ),
    _QuickActionData(
      icon: Icons.add_circle_outline,
      title: 'Add New Product',
      subtitle: 'Register SKU & Metadata',
      onTap: () => context.go('/products?subView=create'),
    ),
    _QuickActionData(
      icon: Icons.dashboard_customize_outlined,
      title: 'Create Template',
      subtitle: 'Visual designer tool',
      onTap: () => context.go('/templates?action=create'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final actions = _actions(context);
    return Row(
      children: [
        Expanded(
          child: QuickActionCard(
            icon: actions[0].icon,
            title: actions[0].title,
            subtitle: actions[0].subtitle,
            isPrimary: actions[0].isPrimary,
            onTap: actions[0].onTap,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: QuickActionCard(
            icon: actions[1].icon,
            title: actions[1].title,
            subtitle: actions[1].subtitle,
            isPrimary: actions[1].isPrimary,
            onTap: actions[1].onTap,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: QuickActionCard(
            icon: actions[2].icon,
            title: actions[2].title,
            subtitle: actions[2].subtitle,
            isPrimary: actions[2].isPrimary,
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
    required this.subtitle,
    required this.onTap,
    this.isPrimary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
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
                  onPressed: () =>
                      const PrintHistoryRoute().push<void>(context),
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
          _PrintTableColumnHeaders(
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          BlocBuilder<RecentPrintJobsCubit, RecentPrintJobsState>(
            builder: (context, state) => switch (state) {
              RecentPrintJobsInitial() ||
              RecentPrintJobsLoading() => const _SectionLoadingIndicator(),
              RecentPrintJobsLoaded(:final jobs) => _RecentPrintsTable(
                jobs: jobs,
              ),
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
        color: colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(color: colorScheme.outline),
          right: BorderSide(color: colorScheme.outline),
          bottom: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(
            label: 'Variant & SKU',
            flex: 3,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          _HeaderCell(
            label: 'Template',
            flex: 2,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          _HeaderCell(
            label: 'Count',
            flex: 1,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          _HeaderCell(
            label: 'Printed',
            flex: 2,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
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
              FrequentVariantsInitial() ||
              FrequentVariantsLoading() => const _SectionLoadingIndicator(),
              FrequentVariantsLoaded(:final variants) => _DesktopVariantsTable(
                variants: variants,
              ),
              FrequentVariantsError(:final message) => _SectionErrorView(
                message: message,
                onRetry: context
                    .read<FrequentVariantsCubit>()
                    .loadFrequentVariants,
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
        color: colorScheme.primaryContainer,
        border: Border(
          left: BorderSide(color: colorScheme.outline),
          right: BorderSide(color: colorScheme.outline),
          bottom: BorderSide(color: colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          _HeaderCell(
            label: 'Variant & Product',
            flex: 3,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          _HeaderCell(
            label: 'Last Printed',
            flex: 2,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
          _HeaderCell(
            label: 'Total Prints',
            flex: 2,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
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
            color: colorScheme.onPrimaryContainer,
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
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
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
