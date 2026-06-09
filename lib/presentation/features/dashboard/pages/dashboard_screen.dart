import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/data/repositories/mock_print_job_repository.dart';
import 'package:stickify/data/repositories/mock_product_repository.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_print_jobs_cubit.dart';
import 'package:stickify/presentation/features/dashboard/widgets/connectivity_status_chip.dart';
import 'package:stickify/presentation/features/dashboard/widgets/frequent_product_row.dart';
import 'package:stickify/presentation/features/dashboard/widgets/quick_action_card.dart';
import 'package:stickify/presentation/features/dashboard/widgets/recent_print_card.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: Route entry point
// The router always references DashboardPage, never _DashboardView.
// This class owns BlocProviders and injects repositories.
// ─────────────────────────────────────────────────────────────────────────────

/// Public entry point for the Dashboard route.
///
/// Responsibilities (DI only, zero layout code):
/// - Creates [RecentPrintJobsCubit] and [FrequentProductsCubit] via [BlocProvider].
/// - Injects the mock repositories (swap for real implementations later).
/// - Triggers initial data loads.
/// - Returns [_DashboardView] as the sole child.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = RecentPrintJobsCubit(
              printJobRepository: const MockPrintJobRepository(),
            );
            unawaited(cubit.loadRecentJobs());
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) {
            final cubit = FrequentProductsCubit(
              productRepository: const MockProductRepository(),
            );
            unawaited(cubit.loadFrequentProducts());
            return cubit;
          },
        ),
      ],
      child: const _DashboardView(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: Layout canvas
// Consumes Cubit state. Zero dependency injection. Zero business logic.
// Uses AdaptiveLayoutSwitcher — no inline breakpoint conditionals.
// ─────────────────────────────────────────────────────────────────────────────

class _DashboardView extends StatelessWidget {
  const _DashboardView();

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
              slivers: [
                SliverPadding(
                  padding: AdaptiveValue<EdgeInsets>(
                    context,
                    defaultValue: const EdgeInsets.all(16),
                    tablet: const EdgeInsets.all(24),
                    desktop: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 28,
                    ),
                  ).value,
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Hero Header ─────────────────────────────────────────
                      const _HeroHeader(),
                      const SizedBox(height: 32),
                      // ── Quick Actions Grid ──────────────────────────────────
                      const _QuickActionsSection(),
                      const SizedBox(height: 32),
                      // ── Recently Printed Labels ─────────────────────────────
                      const _RecentPrintsSection(),
                      const SizedBox(height: 32),
                      // ── Frequent Products Table ─────────────────────────────
                      const _FrequentProductsSection(),
                      const SizedBox(height: 32),
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

// ─────────────────────────────────────────────────────────────────────────────
// SECTION WIDGETS — each is a named, const-constructable sub-widget.
// Keeping them separate ensures isolated rebuild scopes.
// ─────────────────────────────────────────────────────────────────────────────

/// Hero header: page title, subtitle, and connectivity status chip.
/// On desktop the title and chip sit side by side; on mobile they stack.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;
        final titleFontSize = isCompact ? 24.0 : 32.0;

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TitleBlock(fontSize: titleFontSize),
              const SizedBox(height: 16),
              const ConnectivityStatusChip(isOnline: true),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _TitleBlock(fontSize: titleFontSize)),
            const SizedBox(width: 24),
            const ConnectivityStatusChip(isOnline: true),
          ],
        );
      },
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.fontSize});
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Operations Dashboard',
          style: (textTheme.displayLarge ?? const TextStyle()).copyWith(
            fontSize: fontSize,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time printer network status and rapid-access controls.',
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Quick-action cards: 4-col on desktop, 2-col on tablet, 1-col on mobile.
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

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
        final int crossAxisCount;
        final double targetHeight;

        if (w < 540) {
          crossAxisCount = 1;
          targetHeight = 150;
        } else if (w < 960) {
          crossAxisCount = 2;
          targetHeight = 160;
        } else {
          crossAxisCount = 4;
          targetHeight = 160;
        }

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
              onTap: () {/* navigation wired in Phase 2 */},
            );
          },
        );
      },
    );
  }
}

/// Immutable data class for quick action card configuration.
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

/// "Recently Printed Labels" section with its horizontal scrolling carousel.
class _RecentPrintsSection extends StatelessWidget {
  const _RecentPrintsSection();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
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
        // Cubit-driven carousel
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

/// Horizontal carousel of [RecentPrintCard] widgets.
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

/// "Frequent Products" section with its data table.
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 960;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table header
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
              // Column headers (desktop only — hidden on mobile to save space)
              if (!isCompact) ...[
                _TableColumnHeaders(colorScheme: colorScheme, textTheme: textTheme),
              ],
              // Cubit-driven rows
              BlocBuilder<FrequentProductsCubit, FrequentProductsState>(
                builder: (context, state) => switch (state) {
                  FrequentProductsInitial() || FrequentProductsLoading() =>
                    const _SectionLoadingIndicator(),
                  FrequentProductsLoaded(:final products) => isCompact
                      ? _MobileProductList(products: products)
                      : _DesktopProductTable(products: products),
                  FrequentProductsError(:final message) => _SectionErrorView(
                      message: message,
                      onRetry: context.read<FrequentProductsCubit>().loadFrequentProducts,
                    ),
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Column header row for the Frequent Products table (desktop-only).
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
          // Actions column (no header label)
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
        onQuickPrint: () {},
      ),
    );
  }
}

/// Mobile-friendly compact list card for frequent products.
class _MobileProductList extends StatelessWidget {
  const _MobileProductList({required this.products});
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: colorScheme.outlineVariant,
      ),
      itemBuilder: (context, i) {
        final p = products[i];
        final stationDotColor = switch (p.stationStatus) {
          StationStatus.online  => const Color(0xFF10B981),
          StationStatus.warning => const Color(0xFFF59E0B),
          StationStatus.offline => const Color(0xFFEF4444),
        };
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          title: Text(p.name, style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          subtitle: Text(p.sku, style: textTheme.labelSmall?.copyWith(fontSize: 11, color: colorScheme.onSurfaceVariant)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(color: stationDotColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('${p.totalPrints}', style: textTheme.labelMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SECTION-LEVEL UTILITY WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLoadingIndicator extends StatelessWidget {
  const _SectionLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Theme.of(context).colorScheme.primary,
        ),
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
