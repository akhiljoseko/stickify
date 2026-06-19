import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/utils/token_registry.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/renderers/text_element_renderer.dart';

void main() {
  group('ISO 8601 Week calculation (getWeekOfYear)', () {
    test('Jan 1st, 2026 (Thursday) is Week 1', () {
      expect(getWeekOfYear(DateTime(2026)), 1);
    });

    test('Jan 4th, 2026 (Sunday) is Week 1', () {
      expect(getWeekOfYear(DateTime(2026, 1, 4)), 1);
    });

    test('Jan 5th, 2026 (Monday) is Week 2', () {
      expect(getWeekOfYear(DateTime(2026, 1, 5)), 2);
    });

    test('June 20th, 2026 (Saturday) is Week 25', () {
      expect(getWeekOfYear(DateTime(2026, 6, 20)), 25);
    });

    test('Dec 31st, 2026 (Thursday) is Week 53', () {
      expect(getWeekOfYear(DateTime(2026, 12, 31)), 53);
    });
  });

  group('Token Registry & Resolution Tests', () {
    late Product product;
    late ProductVariant variant;

    setUp(() {
      product = const Product(
        id: 'p123',
        name: 'Organic Milk',
        sku: 'MILK-OG-01',
        category: 'Dairy',
        shelfLifeDays: 7,
        storageConditions: 'Keep Chilled',
        ingredients: [
          Ingredient(name: 'Pasteurized Milk', percentage: 99),
          Ingredient(name: 'Vitamin D3', percentage: 1),
        ],
        nutritionFacts: NutritionFacts(
          calories: 120,
          protein: 8,
          totalFat: 5,
          saturatedFat: 3,
          totalCarbs: 12,
          fiber: 0,
        ),
      );

      variant = const ProductVariant(
        name: '1 Liter Bottle',
        quantity: 1,
        unit: 'L',
        wholesale: 1.50,
        mrp: 2.99,
        sku: 'MILK-OG-1L',
      );
    });

    test('calculates Weekly Batch Number correctly', () {
      final now = DateTime.now();
      final week = getWeekOfYear(now);
      final expectedBatch = 'W${week}Y${now.year}';

      final token = tokenRegistry.firstWhere((t) => t.token == '{{system.batch_number}}');
      expect(token.getValue(product, variant), expectedBatch);
    });

    test('calculates Expiry Date correctly based on shelfLifeDays', () {
      final expiryDate = DateTime.now().add(const Duration(days: 7));
      final expected = '${expiryDate.day.toString().padLeft(2, '0')}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.year}';

      final token = tokenRegistry.firstWhere((t) => t.token == '{{system.expiry_date}}');
      expect(token.getValue(product, variant), expected);
    });

    test('resolves product and variant catalog properties', () {
      expect(
        TextElementRenderer.resolveToken('Name: {{product.name}}', product, variant),
        'Name: Organic Milk',
      );
      expect(
        TextElementRenderer.resolveToken('SKU: {{variant.sku}}', product, variant),
        'SKU: MILK-OG-1L',
      );
      expect(
        TextElementRenderer.resolveToken('MRP: {{variant.mrp}}', product, variant),
        'MRP: 2.99',
      );
      expect(
        TextElementRenderer.resolveToken('Cal: {{product.nutrition.calories}}', product, variant),
        'Cal: 120.0',
      );
    });

    test('supports fallback and legacy alias tokens for backward compatibility', () {
      // {{product.sku}} falls back to variant SKU if available, otherwise product SKU
      expect(
        TextElementRenderer.resolveToken('SKU: {{product.sku}}', product, variant),
        'SKU: MILK-OG-1L',
      );

      // Legacy MFG tokens
      final now = DateTime.now();
      final expectedMfg = '${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';

      expect(
        TextElementRenderer.resolveToken('MFG: {{mfg}}', product, variant),
        'MFG: $expectedMfg',
      );
      expect(
        TextElementRenderer.resolveToken('MFG: {{mfgDate}}', product, variant),
        'MFG: $expectedMfg',
      );
      expect(
        TextElementRenderer.resolveToken('MFG: {{product.mfgDate}}', product, variant),
        'MFG: $expectedMfg',
      );
    });
  });
}
