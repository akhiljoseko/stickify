import 'package:stickify/domain/entities/search_item.dart';

/// Abstract repository interface for Search operations.
///
/// Belongs to the global domain layer. Concrete implementations live in
/// `lib/data/repositories/`. Cubits depend only on this interface.
// ignore: one_member_abstracts
abstract interface class SearchRepository {
  /// Queries the repository for [SearchItem] matches based on [query].
  ///
  /// Supports optional filtering by [categories] and [tags], and custom
  /// sorting by relevance score vs alphabetical order.
  Future<List<SearchItem>> search(
    String query, {
    Set<String>? categories,
    Set<String>? tags,
    bool sortByRelevance = true,
  });
}
