import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

part 'product_hive_model.g.dart';

@HiveType(typeId: 0)
class ProductHiveModel extends HiveObject {
  ProductHiveModel({
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

  /// Factory to convert a domain [Product] to a [ProductHiveModel].
  factory ProductHiveModel.fromDomain(Product p) {
    return ProductHiveModel(
      id: p.id,
      name: p.name,
      sku: p.sku,
      totalPrints: p.totalPrints,
      lastPrintedAt: p.lastPrintedAt,
      assignedStation: p.assignedStation,
      stationStatus: p.stationStatus.name,
      category: p.category,
      shelfLifeDays: p.shelfLifeDays,
      storageConditions: p.storageConditions,
      imageUrl: p.imageUrl,
      ingredients: p.ingredients.map(IngredientHiveModel.fromDomain).toList(),
      nutritionFacts: p.nutritionFacts == null
          ? null
          : NutritionFactsHiveModel.fromDomain(p.nutritionFacts!),
      variants: p.variants.map(ProductVariantHiveModel.fromDomain).toList(),
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String sku;

  @HiveField(3)
  final int totalPrints;

  @HiveField(4)
  final DateTime lastPrintedAt;

  @HiveField(5)
  final String assignedStation;

  @HiveField(6)
  final String stationStatus;

  @HiveField(7)
  final String? category;

  @HiveField(8)
  final int? shelfLifeDays;

  @HiveField(9)
  final String? storageConditions;

  @HiveField(10)
  final String? imageUrl;

  @HiveField(11)
  final List<IngredientHiveModel> ingredients;

  @HiveField(12)
  final NutritionFactsHiveModel? nutritionFacts;

  @HiveField(13)
  final List<ProductVariantHiveModel> variants;

  /// Converts this [ProductHiveModel] to a domain [Product].
  Product toDomain() {
    return Product(
      id: id,
      name: name,
      sku: sku,
      totalPrints: totalPrints,
      lastPrintedAt: lastPrintedAt,
      assignedStation: assignedStation,
      stationStatus: StationStatus.values.firstWhere(
        (e) => e.name == stationStatus,
        orElse: () => StationStatus.online,
      ),
      category: category,
      shelfLifeDays: shelfLifeDays,
      storageConditions: storageConditions,
      imageUrl: imageUrl,
      ingredients: ingredients.map((i) => i.toDomain()).toList(),
      nutritionFacts: nutritionFacts?.toDomain(),
      variants: variants.map((v) => v.toDomain()).toList(),
    );
  }
}

@HiveType(typeId: 1)
class IngredientHiveModel extends HiveObject {
  IngredientHiveModel({
    required this.name,
    required this.percentage,
  });

  factory IngredientHiveModel.fromDomain(Ingredient i) {
    return IngredientHiveModel(
      name: i.name,
      percentage: i.percentage,
    );
  }

  @HiveField(0)
  final String name;

  @HiveField(1)
  final double percentage;

  Ingredient toDomain() {
    return Ingredient(
      name: name,
      percentage: percentage,
    );
  }
}

@HiveType(typeId: 2)
class NutritionFactsHiveModel extends HiveObject {
  NutritionFactsHiveModel({
    required this.calories,
    required this.protein,
    required this.totalFat,
    required this.saturatedFat,
    required this.totalCarbs,
    required this.fiber,
  });

  factory NutritionFactsHiveModel.fromDomain(NutritionFacts nf) {
    return NutritionFactsHiveModel(
      calories: nf.calories,
      protein: nf.protein,
      totalFat: nf.totalFat,
      saturatedFat: nf.saturatedFat,
      totalCarbs: nf.totalCarbs,
      fiber: nf.fiber,
    );
  }

  @HiveField(0)
  final double calories;

  @HiveField(1)
  final double protein;

  @HiveField(2)
  final double totalFat;

  @HiveField(3)
  final double saturatedFat;

  @HiveField(4)
  final double totalCarbs;

  @HiveField(5)
  final double fiber;

  NutritionFacts toDomain() {
    return NutritionFacts(
      calories: calories,
      protein: protein,
      totalFat: totalFat,
      saturatedFat: saturatedFat,
      totalCarbs: totalCarbs,
      fiber: fiber,
    );
  }
}

@HiveType(typeId: 3)
class ProductVariantHiveModel extends HiveObject {
  ProductVariantHiveModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.wholesale,
    required this.mrp,
    required this.sku,
  });

  factory ProductVariantHiveModel.fromDomain(ProductVariant v) {
    return ProductVariantHiveModel(
      name: v.name,
      quantity: v.quantity,
      unit: v.unit,
      wholesale: v.wholesale,
      mrp: v.mrp,
      sku: v.sku,
    );
  }

  @HiveField(0)
  final String name;

  @HiveField(1)
  final double quantity;

  @HiveField(2)
  final String unit;

  @HiveField(3)
  final double wholesale;

  @HiveField(4)
  final double mrp;

  @HiveField(5)
  final String sku;

  ProductVariant toDomain() {
    return ProductVariant(
      name: name,
      quantity: quantity,
      unit: unit,
      wholesale: wholesale,
      mrp: mrp,
      sku: sku,
    );
  }
}
