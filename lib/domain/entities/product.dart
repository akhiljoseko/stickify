import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product_variant.dart';

/// Represents the online/connectivity status of a printer station.
enum StationStatus {
  /// The station is online and ready to accept jobs.
  online,

  /// The station is experiencing low ink, media, or a warning state.
  warning,

  /// The station is offline or unreachable.
  offline,
}

/// A pure business entity representing a product in the Stickify catalogue.
///
/// This entity belongs to the global domain layer and must contain no
/// Flutter or framework imports. It surfaces in multiple features:
/// - Dashboard: "Frequent Products" table
/// - Product Management: product list and detail screens
///
/// ## Fields
/// - [id] — Unique product identifier.
/// - [name] — Human-readable product name.
/// - [sku] — Stock-keeping unit code (monospaced in the UI).
/// - [totalPrints] — Lifetime count of labels printed for this product.
/// - [lastPrintedAt] — Timestamp of the most recent print job.
/// - [assignedStation] — The printer station currently assigned to this product.
/// - [stationStatus] — Online/warning/offline state of the assigned station.
/// - [category] — Optional product category for filtering.
/// - [shelfLifeDays] — Optional shelf life in days.
/// - [storageConditions] — Optional storage conditions description.
/// - [imageUrl] — Optional product image URL or path.
/// - [ingredients] — Ingredients list.
/// - [nutritionFacts] — Optional nutrition facts.
/// - [variants] — Variant-level products.
class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.totalPrints,
    required this.lastPrintedAt,
    required this.assignedStation,
    required this.stationStatus,
    this.category,
    this.shelfLifeDays,
    this.storageConditions,
    this.imageUrl,
    this.ingredients = const [],
    this.nutritionFacts,
    this.variants = const [],
  });

  /// Unique identifier for this product.
  final String id;

  /// Human-readable product name (e.g., `'Organic Cold Brew 12oz'`).
  final String name;

  /// SKU code (e.g., `'BEV-CB-ORG-12'`). Rendered in JetBrains Mono.
  final String sku;

  /// Total number of labels ever printed for this product.
  final int totalPrints;

  /// Timestamp of the most recent print operation for this product.
  final DateTime lastPrintedAt;

  /// Printer station currently assigned (e.g., `'Station #02'`).
  final String assignedStation;

  /// Current connectivity status of the assigned printer station.
  final StationStatus stationStatus;

  /// Optional product category (e.g., `'Beverages'`, `'Industrial'`).
  final String? category;

  /// Optional shelf life in days.
  final int? shelfLifeDays;

  /// Optional storage conditions.
  final String? storageConditions;

  /// Optional image URL or asset path.
  final String? imageUrl;

  /// List of ingredients.
  final List<Ingredient> ingredients;

  /// Optional nutrition facts.
  final NutritionFacts? nutritionFacts;

  /// List of variants.
  final List<ProductVariant> variants;

  @override
  List<Object?> get props => [
        id,
        name,
        sku,
        totalPrints,
        lastPrintedAt,
        assignedStation,
        stationStatus,
        category,
        shelfLifeDays,
        storageConditions,
        imageUrl,
        ingredients,
        nutritionFacts,
        variants,
      ];

  /// Creates a copy of this [Product] with the given fields replaced.
  Product copyWith({
    String? id,
    String? name,
    String? sku,
    int? totalPrints,
    DateTime? lastPrintedAt,
    String? assignedStation,
    StationStatus? stationStatus,
    String? category,
    int? shelfLifeDays,
    String? storageConditions,
    String? imageUrl,
    List<Ingredient>? ingredients,
    NutritionFacts? nutritionFacts,
    List<ProductVariant>? variants,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      totalPrints: totalPrints ?? this.totalPrints,
      lastPrintedAt: lastPrintedAt ?? this.lastPrintedAt,
      assignedStation: assignedStation ?? this.assignedStation,
      stationStatus: stationStatus ?? this.stationStatus,
      category: category ?? this.category,
      shelfLifeDays: shelfLifeDays ?? this.shelfLifeDays,
      storageConditions: storageConditions ?? this.storageConditions,
      imageUrl: imageUrl ?? this.imageUrl,
      ingredients: ingredients ?? this.ingredients,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      variants: variants ?? this.variants,
    );
  }
}
