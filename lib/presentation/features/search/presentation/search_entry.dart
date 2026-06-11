import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/cubits/search_cubit.dart';
import 'package:stickify/presentation/features/search/cubits/search_state.dart';
import 'package:stickify/presentation/features/search/presentation/desktop/desktop_search_screen.dart';
import 'package:stickify/presentation/features/search/presentation/mobile/mobile_search_screen.dart';

/// Public entry point for the Search feature screen.
///
/// Wraps [SearchCubit] and forwards the [initialQuery] query parameter.
class SearchPage extends StatelessWidget {
  /// Creates a [SearchPage].
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
              SearchEmpty(:final query) => SearchEmptyView(query: query),
              SearchError(:final message) => SearchErrorView(message: message),
            };
          },
        ),
      ),
    );
  }
}

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

class _SearchShimmerGrid extends StatelessWidget {
  const _SearchShimmerGrid();

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();
    final crossAxisCount = env.experience == AppExperience.mobile
        ? 1
        : env.experience == AppExperience.tablet
            ? 2
            : 3;

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

class _ResultsLayout extends StatelessWidget {
  const _ResultsLayout({
    required this.query,
    required this.results,
  });

  final String query;
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();

    switch (env.experience) {
      case AppExperience.mobile:
        return MobileSearchView(query: query, results: results);
      case AppExperience.tablet:
        return TabletSearchView(query: query, results: results);
      case AppExperience.desktop:
        return DesktopSearchView(query: query, results: results);
    }
  }
}

/// Sticky vertical filters sidebar.
class FiltersPane extends StatelessWidget {
  /// Creates a [FiltersPane].
  const FiltersPane({super.key, this.isBottomSheet = false});

  /// True when rendered in a bottom sheet context.
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
class HorizontalFiltersBar extends StatelessWidget {
  /// Creates a [HorizontalFiltersBar].
  const HorizontalFiltersBar({super.key});

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
class ResultsHeader extends StatelessWidget {
  /// Creates a [ResultsHeader].
  const ResultsHeader({
    required this.query,
    required this.count,
    super.key,
  });

  /// The query term.
  final String query;

  /// The results count.
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

/// Generic empty state view.
class SearchEmptyView extends StatelessWidget {
  /// Creates a [SearchEmptyView].
  const SearchEmptyView({required this.query, super.key});

  /// The search query which yielded no results.
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
class SearchErrorView extends StatelessWidget {
  /// Creates a [SearchErrorView].
  const SearchErrorView({required this.message, super.key});

  /// The error message.
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

/// Helper function to build dynamic search action buttons.
Widget buildSearchActionButton(BuildContext context, SearchItem item, {bool isMini = false}) {
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
