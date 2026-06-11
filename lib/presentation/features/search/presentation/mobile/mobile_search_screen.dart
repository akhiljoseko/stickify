import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/presentation/search_entry.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Mobile Search View (Linear feed + Floating action button bottom sheet).
class MobileSearchView extends StatelessWidget {
  /// Creates a [MobileSearchView].
  const MobileSearchView({
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

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResultsHeader(query: query, count: results.length),
          Expanded(
            child: ResultsGrid(results: results),
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
            child: const FiltersPane(isBottomSheet: true),
          );
        },
      ),
    );
  }
}

/// Managed list of results wrapped in scrollbars.
class ResultsGrid extends StatelessWidget {
  /// Creates a [ResultsGrid].
  const ResultsGrid({required this.results, super.key});

  /// The search results to display.
  final List<SearchItem> results;

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final crossAxisCount = bp.isMobile ? 1 : 2;

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
            return ResultCard(item: item);
          },
        );
      },
    );
  }
}

/// Result Card detailing search item fields.
class ResultCard extends StatefulWidget {
  /// Creates a [ResultCard].
  const ResultCard({required this.item, super.key});

  /// The search item to display.
  final SearchItem item;

  @override
  State<ResultCard> createState() => _ResultCardState();
}

class _ResultCardState extends State<ResultCard> {
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
          buildSearchActionButton(context, widget.item, isMini: true),
        ],
      ),
    );
  }
}
