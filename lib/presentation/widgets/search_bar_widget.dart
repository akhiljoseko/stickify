import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/cubits/search_cubit.dart';
import 'package:stickify/presentation/features/search/cubits/search_state.dart';

/// A responsive search bar component matching the Stitch design specifications.
///
/// On Desktop and Tablet viewports, it displays a fluid input field constrained
/// to a maximum width of 400px.
///
/// On Mobile viewports, it collapses into a single search icon button. Tapping
/// the icon opens a full-screen search overlay.
class SearchBarWidget extends StatefulWidget {
  const SearchBarWidget({super.key});

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncQueryFromUrl();
  }

  void _syncQueryFromUrl() {
    try {
      final router = GoRouter.of(context);
      final currentUri = router.routerDelegate.currentConfiguration.uri;
      final queryParam = currentUri.queryParameters['q'] ?? '';
      
      // Only sync if field is not focused, preventing cursor reset during typing
      if (!_focusNode.hasFocus && _controller.text != queryParam) {
        _controller.text = queryParam;
      }
    } on Object catch (_) {
      // Graceful fallback if GoRouter is not yet available in context
    }
  }

  void _submitSearch(String query) {
    final cleanQuery = query.trim();
    try {
      if (cleanQuery.isNotEmpty) {
        context.go('/dashboard/search?q=${Uri.encodeQueryComponent(cleanQuery)}');
      } else {
        context.go('/dashboard/search');
      }
    } on Object catch (_) {
      // Graceful fallback if GoRouter is not yet available in context (e.g. in widget tests)
    }
  }

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final isMobile = bp.isMobile;

    if (isMobile) {
      return IconButton(
        icon: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        tooltip: 'Search',
        onPressed: () => unawaited(_showMobileSearchOverlay(context)),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search, size: 20),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: Theme.of(context).textTheme.bodyMedium,
                onSubmitted: _submitSearch,
                onChanged: _submitSearch,
                decoration: InputDecoration(
                  hintText: 'Search products, SKUs, or templates...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMobileSearchOverlay(BuildContext context) async {
    final mobileController = TextEditingController(text: _controller.text);
    final searchRepository = context.read<SearchRepository>();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return BlocProvider(
          create: (_) => SearchCubit(searchRepository: searchRepository)
            ..onQueryChanged(mobileController.text),
          child: Builder(
            builder: (blocContext) {
              return Scaffold(
                backgroundColor: Theme.of(dialogContext).colorScheme.surface,
                appBar: AppBar(
                  backgroundColor: Theme.of(dialogContext).colorScheme.surface,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(dialogContext).colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(dialogContext),
                  ),
                  title: TextField(
                    controller: mobileController,
                    autofocus: true,
                    style: Theme.of(dialogContext).textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: 'Search products, SKUs, or templates...',
                      hintStyle: Theme.of(dialogContext).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(dialogContext).colorScheme.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                    ),
                    onChanged: (val) {
                      blocContext.read<SearchCubit>().onQueryChanged(val);
                    },
                    onSubmitted: (val) {
                      Navigator.pop(dialogContext);
                      _submitSearch(val);
                    },
                  ),
                  shape: Border(
                    bottom: BorderSide(
                      color: Theme.of(dialogContext).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                body: Padding(
                  padding: const EdgeInsets.all(24),
                  child: BlocBuilder<SearchCubit, SearchState>(
                    builder: (context, state) {
                      return switch (state) {
                        SearchInitial(:final history) =>
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recent Searches',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ...history.map((q) => _buildRecentSearchItem(
                                dialogContext,
                                q,
                                mobileController,
                              )),
                            ],
                          ),
                        SearchLoading() => const Center(
                            child: CircularProgressIndicator(),
                          ),
                        SearchSuccess(:final results) => ListView.builder(
                            itemCount: results.length,
                            itemBuilder: (context, i) {
                              final item = results[i];
                              return ListTile(
                                leading: const Icon(Icons.search),
                                title: Text(item.title),
                                subtitle: Text(
                                  item.sku ?? item.category,
                                  style: const TextStyle(fontFamily: 'JetBrains Mono'),
                                ),
                                trailing: Text(
                                  '${(item.relevanceScore * 100).toInt()}% match',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.tertiary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(dialogContext);
                                  _submitSearch(item.title);
                                },
                              );
                            },
                          ),
                        SearchEmpty(:final query) => Center(
                            child: Text('No results for "$query"'),
                          ),
                        SearchError(:final message) => Center(
                            child: Text('Error: $message'),
                          ),
                      };
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRecentSearchItem(
    BuildContext context,
    String query,
    TextEditingController controller,
  ) {
    return ListTile(
      leading: const Icon(Icons.history, size: 20),
      title: Text(query),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        Navigator.pop(context);
        _submitSearch(query);
      },
    );
  }
}
