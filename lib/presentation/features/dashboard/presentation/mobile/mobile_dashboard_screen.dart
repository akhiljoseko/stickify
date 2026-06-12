import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_print_jobs_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';
import 'package:stickify/presentation/features/dashboard/widgets/recent_print_card.dart';
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Synchronization complete! All templates and products updated.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            // Refresh data
            context.read<RecentPrintJobsCubit>().loadRecentJobs();
            context.read<FrequentProductsCubit>().loadFrequentProducts();
          } else if (state is SyncFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sync failed: ${state.error}'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
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
    _QuickActionData(
      id: FeatureId.printSetup,
      icon: Icons.layers_outlined,
      title: 'Batch Print',
      subtitle: 'Process CSV or Excel lists',
      requiresBulkOps: true,
    ),
    _QuickActionData(
      id: FeatureId.dashboard,
      icon: Icons.settings_input_component_outlined,
      title: 'Printer Config',
      subtitle: 'Manage hardware nodes',
    ),
  ];

  void _handleAction(BuildContext context, _QuickActionData action, AppEnvironment env) {
    final featureAccess = context.read<FeatureAccessService>();
    final availability = featureAccess.availabilityOf(action.id, env);

    final isRestricted = availability == FeatureAvailability.desktopOnly ||
        (action.requiresBulkOps && !env.supportsBulkOperations);

    if (isRestricted) {
      _showDesktopOnlySheet(context, action.title);
    } else {
      if (action.id == FeatureId.productCatalogAdmin) {
        context.go('/products?subView=create');
      } else if (action.id == FeatureId.templateCreation) {
        context.go('/templates?action=create');
      }
    }
  }

  void _showDesktopOnlySheet(BuildContext context, String actionName) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Icon(
              Icons.computer_outlined,
              size: 48,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Desktop Feature Only',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The "$actionName" feature requires a desktop or tablet viewport. '
              'Please log in on a computer to access this workspace and controls.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(sheetContext),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Understood'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();
    final featureAccess = context.read<FeatureAccessService>();

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final crossAxisCount = w < 480 ? 1 : 2;
        final targetHeight = w < 480 ? 90.0 : 100.0;

        final itemWidth = (w - (crossAxisCount - 1) * 12) / crossAxisCount;
        final childAspectRatio = itemWidth / targetHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: _actions.length,
          itemBuilder: (context, i) {
            final action = _actions[i];
            final availability = featureAccess.availabilityOf(action.id, env);
            final isRestricted = availability == FeatureAvailability.desktopOnly ||
                (action.requiresBulkOps && !env.supportsBulkOperations);

            return _MobileQuickActionCard(
              icon: action.icon,
              title: action.title,
              subtitle: action.subtitle,
              isPrimary: action.isPrimary && !isRestricted,
              isRestricted: isRestricted,
              onTap: () => _handleAction(context, action, env),
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
    this.requiresBulkOps = false,
  });

  final FeatureId id;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final bool requiresBulkOps;
}

class _MobileQuickActionCard extends StatelessWidget {
  const _MobileQuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isPrimary,
    required this.isRestricted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isPrimary;
  final bool isRestricted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final baseBg = isPrimary
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerLow;

    final titleColor = isRestricted
        ? colorScheme.onSurface.withValues(alpha: 0.38)
        : isPrimary
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface;

    final subtitleColor = isRestricted
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.38)
        : isPrimary
            ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
            : colorScheme.onSurfaceVariant;

    final iconColor = isRestricted
        ? colorScheme.primary.withValues(alpha: 0.38)
        : isPrimary
            ? colorScheme.onPrimaryContainer
            : colorScheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: baseBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRestricted
                ? colorScheme.outlineVariant.withValues(alpha: 0.38)
                : colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isRestricted
                    ? colorScheme.onSurface.withValues(alpha: 0.05)
                    : isPrimary
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.15)
                        : colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRestricted) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.lock_outline,
                          size: 14,
                          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
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
              onPressed: () {},
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
      height: 280,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: jobs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => SizedBox(
          width: 260,
          child: RecentPrintCard(
            job: jobs[i],
            width: 260,
            onRepeatPrint: () {},
          ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star_outline, color: colorScheme.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Frequent Products',
                style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        BlocBuilder<FrequentProductsCubit, FrequentProductsState>(
          builder: (context, state) => switch (state) {
            FrequentProductsInitial() || FrequentProductsLoading() =>
              const _SectionLoadingIndicator(),
            FrequentProductsLoaded(:final products) =>
              _MobileProductList(products: products),
            FrequentProductsError(:final message) => _SectionErrorView(
                message: message,
                onRetry: context.read<FrequentProductsCubit>().loadFrequentProducts,
              ),
          },
        ),
      ],
    );
  }
}

class _MobileProductList extends StatelessWidget {
  const _MobileProductList({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final p = products[i];
        return _FrequentProductCard(
          product: p,
          onPrint: () {
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
                      child: Text('Print job sent: 15 labels queued for ${p.name}'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FrequentProductCard extends StatelessWidget {
  const _FrequentProductCard({
    required this.product,
    required this.onPrint,
  });

  final Product product;
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
                  product.name,
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
                      product.sku,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•  ${product.totalPrints} prints',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
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
