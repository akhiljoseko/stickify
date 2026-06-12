import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/cubits/search_state.dart';

/// Cubit responsible for search queries, suggestions, and facet filtering.
class SearchCubit extends Cubit<SearchState> {
  /// Creates a [SearchCubit] instance.
  SearchCubit({required SearchRepository searchRepository})
      : _repository = searchRepository,
        super(const SearchInitial(
          history: ['BEV-CB-ORG-12', 'Gaming Headset', 'Station #02'],
          trendingTags: ['organic', 'beverage', 'shipping', 'standard', 'barcode', 'hardware'],
        ));

  final SearchRepository _repository;
  Timer? _debounceTimer;

  /// Triggers a debounced search query changed event.
  void onQueryChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      await executeSearch(query);
    });
  }

  /// Executes the query and updates state.
  Future<void> executeSearch(String query) async {
    if (query.trim().isEmpty) {
      emit(const SearchInitial(
        history: ['BEV-CB-ORG-12', 'Gaming Headset', 'Station #02'],
        trendingTags: ['organic', 'beverage', 'shipping', 'standard', 'barcode', 'hardware'],
      ));
      return;
    }

    emit(const SearchLoading());

    final searchResult = await _repository.search(
      query,
      categories: const {},
      tags: const {},
    );

    switch (searchResult) {
      case Success(value: final results):
        if (results.isEmpty) {
          emit(SearchEmpty(query: query));
        } else {
          emit(SearchSuccess(
            query: query,
            results: results,
            selectedCategories: const {},
            selectedTags: const {},
            sortByRelevance: true,
          ));
        }
      case Failure(error: final err):
        emit(SearchError(message: err.message));
    }
  }

  /// Toggles a category filter state.
  Future<void> toggleCategory(String category) async {
    final currentState = state;
    if (currentState is! SearchSuccess) return;

    final updatedCategories = Set<String>.from(currentState.selectedCategories);
    if (updatedCategories.contains(category)) {
      updatedCategories.remove(category);
    } else {
      updatedCategories.add(category);
    }

    await _applyFilters(
      query: currentState.query,
      categories: updatedCategories,
      tags: currentState.selectedTags,
      sortByRelevance: currentState.sortByRelevance,
    );
  }

  /// Toggles a tag filter state.
  Future<void> toggleTag(String tag) async {
    final currentState = state;
    if (currentState is! SearchSuccess) return;

    final updatedTags = Set<String>.from(currentState.selectedTags);
    if (updatedTags.contains(tag)) {
      updatedTags.remove(tag);
    } else {
      updatedTags.add(tag);
    }

    await _applyFilters(
      query: currentState.query,
      categories: currentState.selectedCategories,
      tags: updatedTags,
      sortByRelevance: currentState.sortByRelevance,
    );
  }

  /// Toggles sorting state between Relevance score and alphabetical title.
  Future<void> toggleSortOrder() async {
    final currentState = state;
    if (currentState is! SearchSuccess) return;

    await _applyFilters(
      query: currentState.query,
      categories: currentState.selectedCategories,
      tags: currentState.selectedTags,
      sortByRelevance: !currentState.sortByRelevance,
    );
  }

  /// Clears all active filters.
  Future<void> clearAllFilters() async {
    final currentState = state;
    if (currentState is! SearchSuccess) return;

    await _applyFilters(
      query: currentState.query,
      categories: {},
      tags: {},
      sortByRelevance: true,
    );
  }

  Future<void> _applyFilters({
    required String query,
    required Set<String> categories,
    required Set<String> tags,
    required bool sortByRelevance,
  }) async {
    emit(const SearchLoading());
    final searchResult = await _repository.search(
      query,
      categories: categories,
      tags: tags,
      sortByRelevance: sortByRelevance,
    );

    switch (searchResult) {
      case Success(value: final results):
        if (results.isEmpty) {
          emit(SearchEmpty(query: query));
        } else {
          emit(SearchSuccess(
            query: query,
            results: results,
            selectedCategories: categories,
            selectedTags: tags,
            sortByRelevance: sortByRelevance,
          ));
        }
      case Failure(error: final err):
        emit(SearchError(message: err.message));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
