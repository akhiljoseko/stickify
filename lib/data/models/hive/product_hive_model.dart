import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

class ProductHiveModel extends HiveObject {
  ProductHiveModel({
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

  factory ProductHiveModel.fromDomain(Product p) {
    return ProductHiveModel(
      id: p.id,
      name: p.name,
      sku: p.sku,
      category: p.category,
      shelfLifeDays: p.shelfLifeDays,
      storageConditions: p.storageConditions,
      imageUrl: p.imageUrl,
      ingredients: p.ingredients.map(IngredientHiveModel.fromDomain).toList(),
      nutritionFacts: p.nutritionFacts == null
          ? null
          : NutritionFactsHiveModel.fromDomain(p.nutritionFacts!),
      variants: p.variants.map(ProductVariantHiveModel.fromDomain).toList(),
      keywords: p.keywords,
      lastModified: p.lastModified,
    );
  }

  final String id;
  final String name;
  final String sku;
  final String? category;
  final int? shelfLifeDays;
  final String? storageConditions;
  final String? imageUrl;
  final List<IngredientHiveModel> ingredients;
  final NutritionFactsHiveModel? nutritionFacts;
  final List<ProductVariantHiveModel> variants;
  final List<String> keywords;
  final DateTime? lastModified;

  Product toDomain() {
    return Product(
      id: id,
      name: name,
      sku: sku,
      category: category,
      shelfLifeDays: shelfLifeDays,
      storageConditions: storageConditions,
      imageUrl: imageUrl,
      ingredients: ingredients.map((i) => i.toDomain()).toList(),
      nutritionFacts: nutritionFacts?.toDomain(),
      variants: variants.map((v) => v.toDomain()).toList(),
      keywords: keywords,
      lastModified: lastModified,
    );
  }
}

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

  final String name;
  final double percentage;

  Ingredient toDomain() {
    return Ingredient(
      name: name,
      percentage: percentage,
    );
  }
}

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

  final double calories;
  final double protein;
  final double totalFat;
  final double saturatedFat;
  final double totalCarbs;
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

class ProductVariantHiveModel extends HiveObject {
  ProductVariantHiveModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.wholesale,
    required this.mrp,
    required this.sku,
    this.defaultTemplateId,
  });

  factory ProductVariantHiveModel.fromDomain(ProductVariant v) {
    return ProductVariantHiveModel(
      name: v.name,
      quantity: v.quantity,
      unit: v.unit,
      wholesale: v.wholesale,
      mrp: v.mrp,
      sku: v.sku,
      defaultTemplateId: v.defaultTemplateId,
    );
  }

  final String name;
  final double quantity;
  final String unit;
  final double wholesale;
  final double mrp;
  final String sku;
  final String? defaultTemplateId;

  ProductVariant toDomain() {
    return ProductVariant(
      name: name,
      quantity: quantity,
      unit: unit,
      wholesale: wholesale,
      mrp: mrp,
      sku: sku,
      defaultTemplateId: defaultTemplateId,
    );
  }
}
