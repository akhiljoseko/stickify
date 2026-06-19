import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/data/models/firestore/product_firestore_model.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('ProductFirestoreModel', () {
    const variantWithTemplate = ProductVariant(
      name: '100g Pack',
      quantity: 100,
      unit: 'g',
      wholesale: 50,
      mrp: 60,
      sku: 'SKU-VAR-1',
      defaultTemplateId: 'temp-xyz',
    );

    const variantWithoutTemplate = ProductVariant(
      name: '500g Box',
      quantity: 500,
      unit: 'g',
      wholesale: 200,
      mrp: 250,
      sku: 'SKU-VAR-2',
    );

    final product = Product(
      id: 'prod-123',
      name: 'Gourmet Mustard',
      sku: 'SKU-MST-123',
      category: 'Condiments',
      shelfLifeDays: 180,
      storageConditions: 'Refrigerate after opening',
      imageUrl: 'path/to/image.png',
      ingredients: const [
        Ingredient(name: 'Mustard Seeds', percentage: 40),
        Ingredient(name: 'Vinegar', percentage: 30),
      ],
      nutritionFacts: const NutritionFacts(
        calories: 120,
        protein: 4,
        totalFat: 6,
        saturatedFat: 0.5,
        totalCarbs: 10,
        fiber: 2,
      ),
      variants: const [
        variantWithTemplate,
        variantWithoutTemplate,
      ],
      lastModified: DateTime(2026, 6, 19, 12),
    );

    test('correctly converts fromDomain and toDomain preserving defaultTemplateId', () {
      final firestoreModel = ProductFirestoreModel.fromDomain(product);
      final domainProduct = firestoreModel.toDomain();

      expect(domainProduct.id, product.id);
      expect(domainProduct.name, product.name);
      expect(domainProduct.sku, product.sku);
      expect(domainProduct.category, product.category);
      expect(domainProduct.shelfLifeDays, product.shelfLifeDays);
      expect(domainProduct.storageConditions, product.storageConditions);
      expect(domainProduct.imageUrl, product.imageUrl);
      expect(domainProduct.ingredients, product.ingredients);
      expect(domainProduct.nutritionFacts, product.nutritionFacts);
      expect(domainProduct.lastModified, product.lastModified);

      expect(domainProduct.variants.length, 2);
      
      final v1 = domainProduct.variants[0];
      expect(v1.name, variantWithTemplate.name);
      expect(v1.sku, variantWithTemplate.sku);
      expect(v1.defaultTemplateId, 'temp-xyz');

      final v2 = domainProduct.variants[1];
      expect(v2.name, variantWithoutTemplate.name);
      expect(v2.sku, variantWithoutTemplate.sku);
      expect(v2.defaultTemplateId, isNull);
    });

    test('correctly serializes toMap and fromMap preserving defaultTemplateId', () {
      final firestoreModel = ProductFirestoreModel.fromDomain(product);
      final map = firestoreModel.toMap();

      // Check map contents
      expect(map['id'], 'prod-123');
      final variantsList = map['variants'] as List<Map<String, dynamic>>;
      expect(variantsList.length, 2);
      expect(variantsList[0]['defaultTemplateId'], 'temp-xyz');
      expect(variantsList[1]['defaultTemplateId'], isNull);

      // Convert back fromMap
      final fromMapModel = ProductFirestoreModel.fromMap('prod-123', map);
      final mappedDomain = fromMapModel.toDomain();

      expect(mappedDomain.variants.length, 2);
      expect(mappedDomain.variants[0].defaultTemplateId, 'temp-xyz');
      expect(mappedDomain.variants[1].defaultTemplateId, isNull);
    });
  });
}
