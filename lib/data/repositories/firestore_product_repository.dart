import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

/// Firestore-based implementation of [ProductRepository] partitioned by user.
class FirestoreProductRepository implements ProductRepository {
  /// Creates a [FirestoreProductRepository] instance.
  FirestoreProductRepository({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('users').doc(_userId).collection('products');

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    final snapshot = await _productsRef
        .orderBy('totalPrints', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => _productFromFirestore(doc.id, doc.data())).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    final doc = await _productsRef.doc(id).get();
    final data = doc.data();
    if (data == null) return null;
    return _productFromFirestore(doc.id, data);
  }

  @override
  Future<List<Product>> getAllProducts() async {
    final snapshot = await _productsRef.get();
    return snapshot.docs.map((doc) => _productFromFirestore(doc.id, doc.data())).toList();
  }

  @override
  Future<void> saveProduct(Product product) async {
    await _productsRef.doc(product.id).set(_productToJson(product));
  }

  @override
  Future<void> deleteProduct(String id) async {
    await _productsRef.doc(id).delete();
  }

  Map<String, dynamic> _productToJson(Product p) {
    return {
      'id': p.id,
      'name': p.name,
      'sku': p.sku,
      'totalPrints': p.totalPrints,
      'lastPrintedAt': Timestamp.fromDate(p.lastPrintedAt),
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

  Product _productFromFirestore(String id, Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return Product(
      id: id,
      name: json['name'] as String,
      sku: json['sku'] as String,
      totalPrints: json['totalPrints'] as int? ?? 0,
      lastPrintedAt: parseDateTime(json['lastPrintedAt']),
      assignedStation: json['assignedStation'] as String? ?? '',
      stationStatus: StationStatus.values.firstWhere(
        (e) => e.name == json['stationStatus'],
        orElse: () => StationStatus.online,
      ),
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
          unit: m['unit'] as String? ?? '',
          wholesale: (m['wholesale'] as num).toDouble(),
          mrp: (m['mrp'] as num).toDouble(),
          sku: m['sku'] as String? ?? '',
        );
      }).toList(),
    );
  }
}
