import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/presentation/search_entry.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Desktop / 4K Split-pane Search UI.
class DesktopSearchView extends StatelessWidget {
  /// Creates a [DesktopSearchView].
  const DesktopSearchView({
    required this.query,
    required this.results,
    super.key,
  });

  /// The active search query.
  final String query;

  /// The active list of search results.
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
            child: const FiltersPane(),
          ),
        ),
        // Right Results Pane (Scrollable table)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResultsHeader(query: query, count: results.length),
              Expanded(
                child: ResultsTable(results: results),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tablet Search View (Top horizontal scrolling filters bar + Table).
class TabletSearchView extends StatelessWidget {
  /// Creates a [TabletSearchView].
  const TabletSearchView({
    required this.query,
    required this.results,
    super.key,
  });

  /// The active search query.
  final String query;

  /// The active list of search results.
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HorizontalFiltersBar(),
        ResultsHeader(query: query, count: results.length),
        Expanded(
          child: ResultsTable(results: results),
        ),
      ],
    );
  }
}

/// Industrial Precision Data Table for Desktop/Tablet Search Results.
class ResultsTable extends StatelessWidget {
  /// Creates a [ResultsTable].
  const ResultsTable({required this.results, super.key});

  /// The search results to display.
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
                            child: buildSearchActionButton(
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
