import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

/// Local JSON-based storage implementation of [ProductRepository].
///
/// Interfaces directly with [DocumentDatabase] to fetch, create, update, or delete [Product] entities.
class DatabaseProductRepository implements ProductRepository {
  /// Creates a [DatabaseProductRepository] instance backed by [database].
  DatabaseProductRepository({required DocumentDatabase database}) : _db = database;

  final DocumentDatabase _db;
  static const String _collection = 'products';

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    final all = await getAllProducts();
    all.sort((a, b) => b.totalPrints.compareTo(a.totalPrints));
    return all.take(limit).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final data = await _db.get(_collection, id);
    if (data == null) return null;
    return _productFromJson(data);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final allData = await _db.getAll(_collection);
    return allData.map(_productFromJson).toList();
  }

  @override
  Future<void> saveProduct(Product product) async {
    await _db.save(_collection, product.id, _productToJson(product));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _db.delete(_collection, id);
  }

  Map<String, dynamic> _productToJson(Product p) {
    return {
      'id': p.id,
      'name': p.name,
      'sku': p.sku,
      'totalPrints': p.totalPrints,
      'lastPrintedAt': p.lastPrintedAt.toIso8601String(),
      'assignedStation': p.assignedStation,
      'stationStatus': p.stationStatus.name,
      'category': p.category,
      'shelfLifeDays': p.shelfLifeDays,
      'storageConditions': p.storageConditions,
      'imageUrl': p.imageUrl,
      'ingredients': p.ingredients.map((i) => {'name': i.name, 'percentage': i.percentage}).toList(),
      'nutritionFacts': p.nutritionFacts == null ? null : {
        'calories': p.nutritionFacts!.calories,
        'protein': p.nutritionFacts!.protein,
        'totalFat': p.nutritionFacts!.totalFat,
        'saturatedFat': p.nutritionFacts!.saturatedFat,
        'totalCarbs': p.nutritionFacts!.totalCarbs,
        'fiber': p.nutritionFacts!.fiber,
      },
      'variants': p.variants.map((v) => {
        'name': v.name,
        'quantity': v.quantity,
        'unit': v.unit,
        'wholesale': v.wholesale,
        'mrp': v.mrp,
        'sku': v.sku,
      }).toList(),
    };
  }

  Product _productFromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      totalPrints: json['totalPrints'] as int,
      lastPrintedAt: DateTime.parse(json['lastPrintedAt'] as String),
      assignedStation: json['assignedStation'] as String,
      stationStatus: StationStatus.values.firstWhere((e) => e.name == json['stationStatus']),
      category: json['category'] as String?,
      shelfLifeDays: json['shelfLifeDays'] as int?,
      storageConditions: json['storageConditions'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ingredients: (json['ingredients'] as List? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return Ingredient(name: m['name'] as String, percentage: (m['percentage'] as num).toDouble());
      }).toList(),
      nutritionFacts: json['nutritionFacts'] == null ? null : () {
        final nf = json['nutritionFacts'] as Map<String, dynamic>;
        return NutritionFacts(
          calories: (nf['calories'] as num).toDouble(),
          protein: (nf['protein'] as num).toDouble(),
          totalFat: (nf['totalFat'] as num).toDouble(),
          saturatedFat: (nf['saturatedFat'] as num).toDouble(),
          totalCarbs: (nf['totalCarbs'] as num).toDouble(),
          fiber: (nf['fiber'] as num).toDouble(),
        );
      }(),
      variants: (json['variants'] as List? ?? []).map((item) {
        final m = item as Map<String, dynamic>;
        return ProductVariant(
          name: m['name'] as String? ?? '',
          quantity: (m['quantity'] as num).toDouble(),
          unit: m['unit'] as String,
          wholesale: (m['wholesale'] as num).toDouble(),
          mrp: (m['mrp'] as num).toDouble(),
          sku: m['sku'] as String,
        );
      }).toList(),
    );
  }
}
