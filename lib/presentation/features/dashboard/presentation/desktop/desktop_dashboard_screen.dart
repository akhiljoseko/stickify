import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_print_jobs_cubit.dart';
import 'package:stickify/presentation/features/dashboard/widgets/connectivity_status_chip.dart';
import 'package:stickify/presentation/features/dashboard/widgets/frequent_product_row.dart';
import 'package:stickify/presentation/features/dashboard/widgets/quick_action_card.dart';
import 'package:stickify/presentation/features/dashboard/widgets/recent_print_card.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Desktop-specific dashboard viewport layout.
class DesktopDashboardScreen extends StatelessWidget {
  /// Creates a [DesktopDashboardScreen].
  const DesktopDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
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
        const ConnectivityStatusChip(isOnline: true),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  static const List<_QuickActionData> _actions = [
    _QuickActionData(
      icon: Icons.add_circle_outline,
      title: 'Add New Product',
      subtitle: 'Register SKU & Metadata',
      isPrimary: true,
    ),
    _QuickActionData(
      icon: Icons.dashboard_customize_outlined,
      title: 'Create Template',
      subtitle: 'Visual designer tool',
    ),
    _QuickActionData(
      icon: Icons.layers_outlined,
      title: 'Batch Print',
      subtitle: 'Process CSV or Excel lists',
    ),
    _QuickActionData(
      icon: Icons.settings_input_component_outlined,
      title: 'Printer Config',
      subtitle: 'Manage hardware nodes',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w < 960 ? 2 : 4;
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
              onTap: () {},
            );
          },
        );
      },
    );
  }
}

class _QuickActionData {
  const _QuickActionData({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isPrimary = false,
  });

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
              onPressed: () {},
              child: Text(
                'View History',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<RecentPrintJobsCubit, RecentPrintJobsState>(
          builder: (context, state) => switch (state) {
            RecentPrintJobsInitial() || RecentPrintJobsLoading() =>
              const _SectionLoadingIndicator(),
            RecentPrintJobsLoaded(:final jobs) => _RecentPrintsCarousel(jobs: jobs),
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

class _RecentPrintsCarousel extends StatelessWidget {
  const _RecentPrintsCarousel({required this.jobs});
  final List<PrintJob> jobs;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 340,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, i) => RecentPrintCard(
          job: jobs[i],
          onRepeatPrint: () {},
        ),
      ),
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
                    'Frequent Products',
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
          BlocBuilder<FrequentProductsCubit, FrequentProductsState>(
            builder: (context, state) => switch (state) {
              FrequentProductsInitial() || FrequentProductsLoading() =>
                const _SectionLoadingIndicator(),
              FrequentProductsLoaded(:final products) =>
                _DesktopProductTable(products: products),
              FrequentProductsError(:final message) => _SectionErrorView(
                  message: message,
                  onRetry: context.read<FrequentProductsCubit>().loadFrequentProducts,
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
    return ColoredBox(
      color: colorScheme.surfaceContainerLow,
      child: Row(
        children: [
          _HeaderCell(label: 'Product Name & SKU', flex: 3, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Last Printed', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Total Prints', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          _HeaderCell(label: 'Printer Assignment', flex: 2, textTheme: textTheme, colorScheme: colorScheme),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: SizedBox(width: 80),
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

class _DesktopProductTable extends StatelessWidget {
  const _DesktopProductTable({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) => FrequentProductRow(
        product: products[i],
        isEvenRow: i.isEven,
        onQuickPrint: () {
          final colorScheme = Theme.of(context).colorScheme;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.inverseSurface,
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: colorScheme.tertiaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Print job sent: 15 labels queued for ${products[i].name}'),
                  ),
                ],
              ),
            ),
          );
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
