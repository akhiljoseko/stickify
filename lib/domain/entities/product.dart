import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product_variant.dart';

/// A pure business entity representing a product in the Label Grid catalogue.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    this.category,
    this.shelfLifeDays,
    this.storageConditions,
    this.imageUrl,
    this.ingredients = const [],
    this.nutritionFacts,
    this.variants = const [],
    this.keywords = const [],
    this.lastModified,
  });

  final String id;
  final String name;
  final String sku;
  final String? category;
  final int? shelfLifeDays;
  final String? storageConditions;
  final String? imageUrl;
  final List<Ingredient> ingredients;
  final NutritionFacts? nutritionFacts;
  final List<ProductVariant> variants;
  final List<String> keywords;
  final DateTime? lastModified;

  String get ingredientsString {
    final sorted = List<Ingredient>.from(ingredients)
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    return sorted.map((i) => i.name).join(', ');
  }

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        category,
        shelfLifeDays,
        storageConditions,
        imageUrl,
        ingredients,
        nutritionFacts,
        variants,
        keywords,
        lastModified,
      ];

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    int? shelfLifeDays,
    String? storageConditions,
    String? imageUrl,
    List<Ingredient>? ingredients,
    NutritionFacts? nutritionFacts,
    List<ProductVariant>? variants,
    List<String>? keywords,
    DateTime? lastModified,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      storageConditions: storageConditions ?? this.storageConditions,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      variants: variants ?? this.variants,
      keywords: keywords ?? this.keywords,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
