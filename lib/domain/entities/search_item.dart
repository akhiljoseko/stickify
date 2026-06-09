import 'package:equatable/equatable.dart';

/// A pure business domain entity representing a search result item.
///
/// Encapsulates metadata, classification category, and relevance score for
/// catalog search results. Extended with [Equatable] for pure state comparisons.
class SearchItem extends Equatable {
  const SearchItem({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.imageUrl,
    required this.relevanceScore,
    required this.tags,
    this.sku,
  });

  /// Unique identifier of the search item.
  final String id;

  /// Main title of the search item (e.g. product name or template title).
  final String title;

  /// The category classification (e.g. 'Products', 'Templates', 'Stations').
  final String category;

  /// A descriptive snippet summarizing the item.
  final String description;

  /// Remote image URL placeholder for visual cards.
  final String imageUrl;

  /// Scoring metric to rank relevance (0.0 to 1.0).
  final double relevanceScore;

  /// Associated search tags and keywords.
  final List<String> tags;

  /// Optional stock keeping unit (SKU) code.
  final String? sku;

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        description,
        imageUrl,
        relevanceScore,
        tags,
        sku,
      ];

  /// Creates a copy of this [SearchItem] with fields replaced.
  SearchItem copyWith({
    String? id,
    String? title,
    String? category,
    String? description,
    String? imageUrl,
    double? relevanceScore,
    List<String>? tags,
    String? sku,
  }) {
    return SearchItem(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      tags: tags ?? this.tags,
      sku: sku ?? this.sku,
    );
  }
}
