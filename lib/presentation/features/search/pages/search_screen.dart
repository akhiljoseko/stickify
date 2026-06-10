import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/data/data.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/cubits/search_cubit.dart';
import 'package:stickify/presentation/features/search/cubits/search_state.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC: Page Entry Point (Clean Architecture Scoping)
// ─────────────────────────────────────────────────────────────────────────────

/// Public entry point for the Search feature screen.
///
/// Wraps [SearchCubit] and forwards the [initialQuery] query parameter.
class SearchPage extends StatelessWidget {
  const SearchPage({
    super.key,
    this.initialQuery,
    this.searchRepository,
  });

  /// The initial query parameter extracted from route.
  final String? initialQuery;
  
  /// The repository to query search items from.
  final SearchRepository? searchRepository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (blocContext) => SearchCubit(
        searchRepository: searchRepository ?? blocContext.read<SearchRepository>(),
      ),
      child: _SearchView(initialQuery: initialQuery),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE: View Scaffold (Handles Init & Route Parameter Binding)
// ─────────────────────────────────────────────────────────────────────────────

class _SearchView extends StatefulWidget {
  const _SearchView({this.initialQuery});

  final String? initialQuery;

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  @override
  void initState() {
    super.initState();
    _triggerSearch();
  }

  @override
  void didUpdateWidget(_SearchView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialQuery != oldWidget.initialQuery) {
      _triggerSearch();
    }
  }

  void _triggerSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final query = widget.initialQuery ?? '';
        context.read<SearchCubit>().onQueryChanged(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            return switch (state) {
              SearchInitial(:final history, :final trendingTags) =>
                _SearchInitialView(
                  history: history,
                  trendingTags: trendingTags,
                ),
              SearchLoading() => const _SearchShimmerGrid(),
              SearchSuccess(:final query, :final results) => _ResultsLayout(
                query: query,
                results: results,
              ),
              SearchEmpty(:final query) => _SearchEmptyView(query: query),
              SearchError(:final message) => _SearchErrorView(message: message),
            };
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VIEW SUB-TREES & LAYOUTS
// ─────────────────────────────────────────────────────────────────────────────

/// Initial Search landing screen with query suggestions and history chips.
class _SearchInitialView extends StatelessWidget {
  const _SearchInitialView({
    required this.history,
    required this.trendingTags,
  });

  final List<String> history;
  final List<String> trendingTags;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.search, size: 28, color: colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Search Stickify Catalogue',
                      style: textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Hanken Grotesk',
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Type above to search across physical products, printer templates, and active nodes.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              if (history.isNotEmpty) ...[
                Text(
                  'RECENT SEARCHES',
                  style: textTheme.labelSmall?.copyWith(
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: history
                      .map((q) => _SuggestionChip(query: q))
                      .toList(),
                ),
                const SizedBox(height: 24),
              ],
              Text(
                'TRENDING CATEGORIES & TAGS',
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trendingTags
                    .map((tag) => _SuggestionChip(query: tag, isTag: true))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shimmer placeholder grid during active queries.
class _SearchShimmerGrid extends StatelessWidget {
  const _SearchShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final crossAxisCount = AdaptiveValue<int>(
      context,
      defaultValue: 1,
      tablet: 2,
      desktop: 3,
      fourK: 4,
    ).value;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.82,
        ),
        itemCount: 8,
        itemBuilder: (context, _) => const _ShimmerCard(),
      ),
    );
  }
}

/// The responsive results pane dispatcher layout.
class _ResultsLayout extends StatelessWidget {
  const _ResultsLayout({
    required this.query,
    required this.results,
  });

  final String query;
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayoutSwitcher(
      mobile: _MobileSearchView(query: query, results: results),
      tablet: _TabletSearchView(query: query, results: results),
      desktop: _DesktopSearchView(query: query, results: results),
    );
  }
}

/// Desktop / 4K Split-pane Search UI.
class _DesktopSearchView extends StatelessWidget {
  const _DesktopSearchView({
    required this.query,
    required this.results,
  });

  final String query;
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Sticky Filters Pane (300px wide matching specs)
        SizedBox(
          width: 300,
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                right: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
            child: const _FiltersPane(),
          ),
        ),
        // Right Results Pane (Scrollable table)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ResultsHeader(query: query, count: results.length),
              Expanded(
                child: _ResultsTable(results: results),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tablet Search View (Top horizontal scrolling filters bar + Table).
class _TabletSearchView extends StatelessWidget {
  const _TabletSearchView({
    required this.query,
    required this.results,
  });

  final String query;
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HorizontalFiltersBar(),
        _ResultsHeader(query: query, count: results.length),
        Expanded(
          child: _ResultsTable(results: results),
        ),
      ],
    );
  }
}

/// Mobile Search View (Linear feed + Floating action button bottom sheet).
class _MobileSearchView extends StatelessWidget {
  const _MobileSearchView({
    required this.query,
    required this.results,
  });

  final String query;
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResultsHeader(query: query, count: results.length),
          Expanded(
            child: _ResultsGrid(results: results),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () => _showMobileFilterBottomSheet(context),
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  Future<void> _showMobileFilterBottomSheet(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            child: const _FiltersPane(isBottomSheet: true),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

/// Sticky vertical filters sidebar.
class _FiltersPane extends StatelessWidget {
  const _FiltersPane({this.isBottomSheet = false});

  final bool isBottomSheet;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is! SearchSuccess) return const SizedBox();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filters',
                    style: textTheme.titleSmall?.copyWith(
                      fontFamily: 'Hanken Grotesk',
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (state.selectedCategories.isNotEmpty ||
                      state.selectedTags.isNotEmpty)
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                      ),
                      onPressed: () {
                        unawaited(context.read<SearchCubit>().clearAllFilters());
                        if (isBottomSheet) Navigator.pop(context);
                      },
                      child: Text(
                        'Clear All',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Categories Section
              Text(
                'CATEGORIES',
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              _buildCategoryCheckbox(context, 'Products', state),
              _buildCategoryCheckbox(context, 'Templates', state),
              _buildCategoryCheckbox(context, 'Stations', state),
              const SizedBox(height: 24),
              // Sort Section
              Text(
                'ARRANGEMENT',
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => unawaited(context.read<SearchCubit>().toggleSortOrder()),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                icon: Icon(
                  state.sortByRelevance ? Icons.sort : Icons.sort_by_alpha,
                  size: 16,
                  color: colorScheme.primary,
                ),
                label: Text(
                  state.sortByRelevance
                      ? 'Sort by Relevance'
                      : 'Sort Alphabetically',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Tags Section
              Text(
                'FILTER BY TAGS',
                style: textTheme.labelSmall?.copyWith(
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children:
                    [
                      'organic',
                      'beverage',
                      'shipping',
                      'standard',
                      'barcode',
                      'hardware',
                      'safety',
                      'matte',
                    ].map((t) {
                      final isSelected = state.selectedTags.contains(t);
                      return _FilterTagChip(
                        label: t,
                        isSelected: isSelected,
                        onTap: () => unawaited(context.read<SearchCubit>().toggleTag(t)),
                      );
                    }).toList(),
              ),
              if (isBottomSheet) ...[
                const SizedBox(height: 40),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply Filters'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCheckbox(
    BuildContext context,
    String category,
    SearchSuccess state,
  ) {
    final isSelected = state.selectedCategories.contains(category);

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => unawaited(context.read<SearchCubit>().toggleCategory(category)),
      title: Text(
        category,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }
}

/// Horizontal scrollable chips bar for Tablet filters.
class _HorizontalFiltersBar extends StatelessWidget {
  const _HorizontalFiltersBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<SearchCubit, SearchState>(
      builder: (context, state) {
        if (state is! SearchSuccess) return const SizedBox();

        final activeFilters = [
          ...state.selectedCategories,
          ...state.selectedTags,
        ];

        return Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Category Toggles
              ...['Products', 'Templates', 'Stations'].map((c) {
                final isSelected = state.selectedCategories.contains(c);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      c,
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) =>
                        unawaited(context.read<SearchCubit>().toggleCategory(c)),
                    selectedColor: colorScheme.primary,
                    checkmarkColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
              // Tag Toggle
              ...[
                'organic',
                'beverage',
                'shipping',
                'standard',
                'barcode',
                'hardware',
              ].map((t) {
                final isSelected = state.selectedTags.contains(t);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      '#$t',
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => unawaited(context.read<SearchCubit>().toggleTag(t)),
                    selectedColor: colorScheme.primary,
                    checkmarkColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
              if (activeFilters.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      unawaited(context.read<SearchCubit>().clearAllFilters()),
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Reset'),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Summary header containing results count and query indicator.
class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.query,
    required this.count,
  });

  final String query;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                children: [
                  const TextSpan(text: 'Showing '),
                  TextSpan(
                    text: '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const TextSpan(text: ' results for '),
                  TextSpan(
                    text: '"$query"',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Managed list of results wrapped in scrollbars.
class _ResultsGrid extends StatelessWidget {
  const _ResultsGrid({required this.results});

  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final crossAxisCount = AdaptiveValue<int>(
      context,
      defaultValue: 1,
      tablet: 2,
      desktop: 3,
      fourK: 4,
    ).value;

    return AdaptiveScrollWrapper(
      builder: (context, controller) {
        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: bp.isMobile ? 3.4 : 0.82,
          ),
          itemCount: results.length,
          itemBuilder: (context, i) {
            final item = results[i];
            return _ResultCard(item: item);
          },
        );
      },
    );
  }
}

/// Result Card detailing search item fields.
class _ResultCard extends StatefulWidget {
  const _ResultCard({required this.item});

  final SearchItem item;

  @override
  State<_ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<_ResultCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bp = ResponsiveBreakpoints.of(context);

    // Primary border or soft outline based on hover
    final cardBorderColor = _isHovered
        ? colorScheme.primary
        : colorScheme.outlineVariant;
    final cardBg = _isHovered
        ? colorScheme.surfaceContainerLow
        : colorScheme.surfaceContainerLowest;

    Widget content = Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: cardBorderColor,
          width: _isHovered ? 1.5 : 1.0,
        ),
      ),
      child: bp.isMobile
          ? _buildMobileRow(context)
          : _buildDesktopColumn(context),
    );

    // Prevent hover on touch viewports (completely eliminates ghost states)
    if (!bp.isMobile) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: content,
      );
    }

    return content;
  }

  Widget _buildDesktopColumn(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder with tag
          Expanded(
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Icon(
                          widget.item.category == 'Templates'
                              ? Icons.description_outlined
                              : widget.item.category == 'Stations'
                              ? Icons.settings_input_component_outlined
                              : Icons.sticky_note_2_outlined,
                          size: 36,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.item.category,
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Technical title and scores
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.item.title,
                  style: textTheme.titleSmall?.copyWith(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(widget.item.relevanceScore * 100).toInt()}% match',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Description
          Text(
            widget.item.description,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Tags
          Wrap(
            spacing: 4,
            children: widget.item.tags.map((t) {
              return Text(
                '#$t',
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontFamily: 'JetBrains Mono',
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRow(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Left image container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                widget.item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  widget.item.category == 'Templates'
                      ? Icons.description_outlined
                      : widget.item.category == 'Stations'
                          ? Icons.settings_input_component_outlined
                          : Icons.sticky_note_2_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Right content details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        widget.item.category,
                        style: textTheme.bodySmall?.copyWith(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                    Text(
                      '${(widget.item.relevanceScore * 100).toInt()}% match',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  widget.item.title,
                  style: textTheme.bodyMedium?.copyWith(
                    fontFamily: 'Hanken Grotesk',
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (widget.item.sku != null)
                  Text(
                    'SKU: ${widget.item.sku}',
                    style: textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      fontFamily: 'JetBrains Mono',
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button as icon button on mobile
          _buildSearchActionButton(context, widget.item, isMini: true),
        ],
      ),
    );
  }
}

/// Shimmer card placeholder.
class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 16,
            width: 150,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            width: 200,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                height: 12,
                width: 40,
                color: colorScheme.surfaceContainer,
              ),
              const SizedBox(width: 8),
              Container(
                height: 12,
                width: 50,
                color: colorScheme.surfaceContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Generic chip for suggestion triggers.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.query,
    this.isTag = false,
  });

  final String query;
  final bool isTag;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => unawaited(context.read<SearchCubit>().executeSearch(query)),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            isTag ? '#$query' : query,
            style: textTheme.bodySmall?.copyWith(
              fontFamily: isTag ? 'JetBrains Mono' : null,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Customizable chip for tag selections.
class _FilterTagChip extends StatelessWidget {
  const _FilterTagChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bg = isSelected
        ? colorScheme.primary
        : colorScheme.surfaceContainerHigh;
    final fg = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;
    final border = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '#$label',
            style: textTheme.bodySmall?.copyWith(
              fontFamily: 'JetBrains Mono',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Generic empty state view.
class _SearchEmptyView extends StatelessWidget {
  const _SearchEmptyView({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: textTheme.titleMedium?.copyWith(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t find any matches for "$query". Try modifying your filters or check for spelling errors.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => context.read<SearchCubit>().clearAllFilters(),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                side: BorderSide(color: colorScheme.primary),
              ),
              child: Text(
                'Clear Filters',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error fallback view.
class _SearchErrorView extends StatelessWidget {
  const _SearchErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Search Failure',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.read<SearchCubit>().executeSearch(''),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Industrial Precision Data Table for Desktop/Tablet Search Results.
class _ResultsTable extends StatelessWidget {
  const _ResultsTable({required this.results});

  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        clipBehavior: Clip.antiAlias,
        child: AdaptiveScrollWrapper(
          builder: (context, controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Table(
                columnWidths: const {
                  0: FlexColumnWidth(4),
                  1: FlexColumnWidth(2),
                  2: FlexColumnWidth(2),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                children: [
                  // Table Header Row
                  TableRow(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainer,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'Product Variant',
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Text(
                          'SKU',
                          style: textTheme.bodySmall?.copyWith(
                            fontFamily: 'JetBrains Mono',
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Actions',
                            style: textTheme.bodySmall?.copyWith(
                              fontFamily: 'JetBrains Mono',
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Table Body Rows
                  ...List.generate(results.length, (index) {
                    final item = results[index];
                    final isEven = index.isEven;
                    return TableRow(
                      decoration: BoxDecoration(
                        color: isEven ? colorScheme.surfaceContainerLow : colorScheme.surfaceContainerLowest,
                        border: Border(
                          bottom: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                      children: [
                        // Product Variant
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainer,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: colorScheme.outlineVariant),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      item.category == 'Templates'
                                          ? Icons.description_outlined
                                          : item.category == 'Stations'
                                              ? Icons.settings_input_component_outlined
                                              : Icons.sticky_note_2_outlined,
                                      size: 20,
                                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.title,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // SKU
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Text(
                            item.sku ?? 'N/A',
                            style: textTheme.bodyMedium?.copyWith(
                              fontFamily: 'JetBrains Mono',
                              color: colorScheme.primary,
                            ),
                          ),
                        ),
                        // Actions
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: _buildSearchActionButton(
                              context,
                              item,
                              isMini: !ResponsiveBreakpoints.of(context).isDesktop,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget _buildSearchActionButton(BuildContext context, SearchItem item, {bool isMini = false}) {
  final colorScheme = Theme.of(context).colorScheme;

  if (isMini) {
    // Mini (Icon Button) mode for smaller viewports

    // Disabled Case (Smoked Honey Almonds - ALM-SH-250P)
    if (item.sku == 'ALM-SH-250P') {
      return const Opacity(
        opacity: 0.5,
        child: IconButton(
          onPressed: null,
          icon: Icon(Icons.print_outlined),
          tooltip: 'Print Label (Disabled)',
        ),
      );
    }

    // Queue New Case (Bulk Raw Almonds - ALM-RW-5KG)
    if (item.sku == 'ALM-RW-5KG') {
      return IconButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: colorScheme.inverseSurface,
              content: Row(
                children: [
                  Icon(Icons.sync, color: colorScheme.primaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Queued new print job for ${item.title}'),
                  ),
                ],
              ),
            ),
          );
        },
        icon: const Icon(Icons.sync),
        color: colorScheme.secondary,
        tooltip: 'Queue New',
      );
    }

    // Active Print Case (All others)
    return IconButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.inverseSurface,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.tertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Print job sent: 15 labels queued for ${item.title}'),
                ),
              ],
            ),
          ),
        );
      },
      icon: const Icon(Icons.print_outlined),
      color: colorScheme.primary,
      tooltip: 'Print Label',
    );
  }

  Widget button;

  // Disabled Case (Smoked Honey Almonds - ALM-SH-250P)
  if (item.sku == 'ALM-SH-250P') {
    button = Opacity(
      opacity: 0.5,
      child: FilledButton.icon(
        onPressed: null,
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.outlineVariant,
          disabledBackgroundColor: colorScheme.outlineVariant,
          disabledForegroundColor: colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        icon: const Icon(Icons.print, size: 18),
        label: const Text('Print Label', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  // Queue New Case (Bulk Raw Almonds - ALM-RW-5KG)
  else if (item.sku == 'ALM-RW-5KG') {
    button = FilledButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.inverseSurface,
            content: Row(
              children: [
                Icon(Icons.sync, color: colorScheme.primaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Queued new print job for ${item.title}'),
                ),
              ],
            ),
          ),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: const Icon(Icons.sync, size: 18),
      label: const Text('Queue New', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Active Print Case (All others)
  else {
    button = FilledButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: colorScheme.inverseSurface,
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.tertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Print job sent: 15 labels queued for ${item.title}'),
                ),
              ],
            ),
          ),
        );
      },
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      icon: const Icon(Icons.print, size: 18),
      label: const Text('Print Label', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerRight,
    child: button,
  );
}
