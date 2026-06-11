import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/domain.dart';

/// Firestore persistence model for Products.
class ProductFirestoreModel {
  ProductFirestoreModel({
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

  factory ProductFirestoreModel.fromDomain(Product p) {
    return ProductFirestoreModel(
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
      ingredients: p.ingredients.map(IngredientFirestoreModel.fromDomain).toList(),
      nutritionFacts: p.nutritionFacts == null
          ? null
          : NutritionFactsFirestoreModel.fromDomain(p.nutritionFacts!),
      variants: p.variants.map(ProductVariantFirestoreModel.fromDomain).toList(),
    );
  }

  factory ProductFirestoreModel.fromMap(String id, Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return ProductFirestoreModel(
      id: id,
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      totalPrints: json['totalPrints'] as int? ?? 0,
      lastPrintedAt: parseDateTime(json['lastPrintedAt']),
      assignedStation: json['assignedStation'] as String? ?? '',
      stationStatus: json['stationStatus'] as String? ?? 'online',
      category: json['category'] as String?,
      shelfLifeDays: json['shelfLifeDays'] as int?,
      storageConditions: json['storageConditions'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ingredients: (json['ingredients'] as List? ?? [])
          .map((item) => IngredientFirestoreModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      nutritionFacts: json['nutritionFacts'] == null
          ? null
          : NutritionFactsFirestoreModel.fromMap(json['nutritionFacts'] as Map<String, dynamic>),
      variants: (json['variants'] as List? ?? [])
          .map((item) => ProductVariantFirestoreModel.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String sku;
  final int totalPrints;
  final DateTime lastPrintedAt;
  final String assignedStation;
  final String stationStatus;
  final String? category;
  final int? shelfLifeDays;
  final String? storageConditions;
  final String? imageUrl;
  final List<IngredientFirestoreModel> ingredients;
  final NutritionFactsFirestoreModel? nutritionFacts;
  final List<ProductVariantFirestoreModel> variants;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'totalPrints': totalPrints,
      'lastPrintedAt': Timestamp.fromDate(lastPrintedAt),
      'assignedStation': assignedStation,
      'stationStatus': stationStatus,
      'category': category,
      'shelfLifeDays': shelfLifeDays,
      'storageConditions': storageConditions,
      'imageUrl': imageUrl,
      'ingredients': ingredients.map((i) => i.toMap()).toList(),
      'nutritionFacts': nutritionFacts?.toMap(),
      'variants': variants.map((v) => v.toMap()).toList(),
    };
  }

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

class IngredientFirestoreModel {
  IngredientFirestoreModel({
    required this.name,
    required this.percentage,
  });

  factory IngredientFirestoreModel.fromDomain(Ingredient i) {
    return IngredientFirestoreModel(
      name: i.name,
      percentage: i.percentage,
    );
  }

  factory IngredientFirestoreModel.fromMap(Map<String, dynamic> m) {
    return IngredientFirestoreModel(
      name: m['name'] as String? ?? '',
      percentage: (m['percentage'] as num? ?? 0.0).toDouble(),
    );
  }

  final String name;
  final double percentage;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'percentage': percentage,
    };
  }

  Ingredient toDomain() {
    return Ingredient(name: name, percentage: percentage);
  }
}

class NutritionFactsFirestoreModel {
  NutritionFactsFirestoreModel({
    required this.calories,
    required this.protein,
    required this.totalFat,
    required this.saturatedFat,
    required this.totalCarbs,
    required this.fiber,
  });

  factory NutritionFactsFirestoreModel.fromDomain(NutritionFacts nf) {
    return NutritionFactsFirestoreModel(
      calories: nf.calories,
      protein: nf.protein,
      totalFat: nf.totalFat,
      saturatedFat: nf.saturatedFat,
      totalCarbs: nf.totalCarbs,
      fiber: nf.fiber,
    );
  }

  factory NutritionFactsFirestoreModel.fromMap(Map<String, dynamic> nf) {
    return NutritionFactsFirestoreModel(
      calories: (nf['calories'] as num? ?? 0.0).toDouble(),
      protein: (nf['protein'] as num? ?? 0.0).toDouble(),
      totalFat: (nf['totalFat'] as num? ?? 0.0).toDouble(),
      saturatedFat: (nf['saturatedFat'] as num? ?? 0.0).toDouble(),
      totalCarbs: (nf['totalCarbs'] as num? ?? 0.0).toDouble(),
      fiber: (nf['fiber'] as num? ?? 0.0).toDouble(),
    );
  }

  final double calories;
  final double protein;
  final double totalFat;
  final double saturatedFat;
  final double totalCarbs;
  final double fiber;

  Map<String, dynamic> toMap() {
    return {
      'calories': calories,
      'protein': protein,
      'totalFat': totalFat,
      'saturatedFat': saturatedFat,
      'totalCarbs': totalCarbs,
      'fiber': fiber,
    };
  }

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

class ProductVariantFirestoreModel {
  ProductVariantFirestoreModel({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.wholesale,
    required this.mrp,
    required this.sku,
  });

  factory ProductVariantFirestoreModel.fromDomain(ProductVariant v) {
    return ProductVariantFirestoreModel(
      name: v.name,
      quantity: v.quantity,
      unit: v.unit,
      wholesale: v.wholesale,
      mrp: v.mrp,
      sku: v.sku,
    );
  }

  factory ProductVariantFirestoreModel.fromMap(Map<String, dynamic> m) {
    return ProductVariantFirestoreModel(
      name: m['name'] as String? ?? '',
      quantity: (m['quantity'] as num? ?? 0.0).toDouble(),
      unit: m['unit'] as String? ?? '',
      wholesale: (m['wholesale'] as num? ?? 0.0).toDouble(),
      mrp: (m['mrp'] as num? ?? 0.0).toDouble(),
      sku: m['sku'] as String? ?? '',
    );
  }

  final String name;
  final double quantity;
  final String unit;
  final double wholesale;
  final double mrp;
  final String sku;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'wholesale': wholesale,
      'mrp': mrp,
      'sku': sku,
    };
  }

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
