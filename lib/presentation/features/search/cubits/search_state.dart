import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/search_item.dart';

/// The sealed base class for all search states.
sealed class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

/// The initial search state, displaying historical queries and trending suggestion chips.
final class SearchInitial extends SearchState {
  const SearchInitial({
    required this.history,
    required this.trendingTags,
  });

  /// Previous queries typed by the user.
  final List<String> history;

  /// Suggestion chips for trending searches.
  final List<String> trendingTags;

  @override
  List<Object?> get props => [history, trendingTags];
}

/// The loading state when searching is active, displaying shimmer skeletons.
final class SearchLoading extends SearchState {
  const SearchLoading();
}

/// The success state containing the queried results and applied filter configurations.
final class SearchSuccess extends SearchState {
  const SearchSuccess({
    required this.query,
    required this.results,
    required this.selectedCategories,
    required this.selectedTags,
    required this.sortByRelevance,
  });

  /// The active query string.
  final String query;

  /// The filtered list of results.
  final List<SearchItem> results;

  /// Set of categories currently selected for filtering.
  final Set<String> selectedCategories;

  /// Set of tags currently selected for filtering.
  final Set<String> selectedTags;

  /// Whether sorted by relevance score or alphabetically.
  final bool sortByRelevance;

  @override
  List<Object?> get props => [
        query,
        results,
        selectedCategories,
        selectedTags,
        sortByRelevance,
      ];
}

/// The empty state when no results match the query.
final class SearchEmpty extends SearchState {
  const SearchEmpty({required this.query});

  /// The active query that yielded no results.
  final String query;

  @override
  List<Object?> get props => [query];
}

/// The error state representing a search failure.
final class SearchError extends SearchState {
  const SearchError({required this.message});

  /// Description of the error.
  final String message;

  @override
  List<Object?> get props => [message];
}
