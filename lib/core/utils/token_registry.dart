import 'package:stickify/domain/domain.dart';

/// Helper to calculate ISO Week of the Year.
int getWeekOfYear(DateTime date) {
  // Find Thursday of the target week:
  // targetWeekThursday = date + (4 - weekday)
  final thursday = DateTime(date.year, date.month, date.day + (4 - date.weekday));

  // First Thursday of the year:
  // We start at Jan 1st of that same year. If Jan 1st is after Thursday, we go to next Thursday.
  final firstDayOfYear = DateTime(thursday.year);
  final firstThursday = DateTime(
    firstDayOfYear.year,
    1,
    1 + (4 - firstDayOfYear.weekday) + (firstDayOfYear.weekday > 4 ? 7 : 0),
  );

  // Difference in days divided by 7, plus 1:
  final diffDays = thursday.difference(firstThursday).inDays;
  return (diffDays / 7).floor() + 1;
}

String _formattedMfgDate([DateTime? date]) {
  final target = date ?? DateTime.now();
  final day = target.day.toString().padLeft(2, '0');
  final month = target.month.toString().padLeft(2, '0');
  final year = target.year.toString();
  return '$day-$month-$year';
}

/// Represents a dynamic token option in a sticker template.
class TemplateToken {
  const TemplateToken({
    required this.token,
    required this.displayName,
    required this.category,
    required this.getValue,
    this.visibleInDropdown = true,
  });

  /// The token placeholder tag, e.g., '{{system.batch_number}}'
  final String token;

  /// User-friendly name shown in the UI, e.g., 'Batch Number'
  final String displayName;

  /// Group category for organizing the dropdown (e.g., 'Product', 'System')
  final String category;

  /// The logic to resolve/calculate the token value at runtime
  final String Function(Product? product, ProductVariant? variant, [DateTime? manufacturingDate]) getValue;

  /// Whether this token should be displayed in the template builder dropdown
  final bool visibleInDropdown;
}

/// The centralized registry of all template tokens available in Label Grid.
final List<TemplateToken> tokenRegistry = [
  // ================= SYSTEM CALCULATED TOKENS =================
  TemplateToken(
    token: '{{system.mfg_date}}',
    displayName: 'MFG Date (Today)',
    category: 'System',
    getValue: (p, v, [mfgDate]) => _formattedMfgDate(mfgDate),
  ),
  TemplateToken(
    token: '{{system.batch_number}}',
    displayName: 'Batch Number (Weekly)',
    category: 'System',
    getValue: (p, v, [mfgDate]) {
      final date = mfgDate ?? DateTime.now();
      final week = getWeekOfYear(date);
      return 'W${week}Y${date.year}';
    },
  ),
  TemplateToken(
    token: '{{system.expiry_date}}',
    displayName: 'Expiry Date (Based on Shelf Life)',
    category: 'System',
    getValue: (p, v, [mfgDate]) {
      if (p == null || p.shelfLifeDays == null) return '';
      final baseDate = mfgDate ?? DateTime.now();
      final expiry = baseDate.add(Duration(days: p.shelfLifeDays!));
      final day = expiry.day.toString().padLeft(2, '0');
      final month = expiry.month.toString().padLeft(2, '0');
      final year = expiry.year.toString();
      return '$day-$month-$year';
    },
  ),

  // ================= PRODUCT CATALOG TOKENS =================
  TemplateToken(
    token: '{{product.name}}',
    displayName: 'Product Name',
    category: 'Product',
    getValue: (p, v, [_]) => p?.name ?? '',
  ),
  TemplateToken(
    token: '{{product.sku}}',
    displayName: 'Product SKU (Fallback)',
    category: 'Product',
    getValue: (p, v, [_]) => v?.sku ?? p?.sku ?? '',
  ),
  TemplateToken(
    token: '{{product.id}}',
    displayName: 'Product ID',
    category: 'Product',
    getValue: (p, v, [_]) => p?.id ?? '',
  ),
  TemplateToken(
    token: '{{product.category}}',
    displayName: 'Category',
    category: 'Product',
    getValue: (p, v, [_]) => p?.category ?? '',
  ),
  TemplateToken(
    token: '{{product.shelfLifeDays}}',
    displayName: 'Shelf Life (Days)',
    category: 'Product',
    getValue: (p, v, [_]) => p?.shelfLifeDays?.toString() ?? '',
  ),
  TemplateToken(
    token: '{{product.storageConditions}}',
    displayName: 'Storage Conditions',
    category: 'Product',
    getValue: (p, v, [_]) => p?.storageConditions ?? '',
  ),
  TemplateToken(
    token: '{{product.ingredients}}',
    displayName: 'Ingredients List',
    category: 'Product',
    getValue: (p, v, [_]) => p?.ingredientsString ?? '',
  ),
  TemplateToken(
    token: '{{product.imageUrl}}',
    displayName: 'Product Image URL',
    category: 'Product',
    getValue: (p, v, [_]) => p?.imageUrl ?? '',
  ),
  TemplateToken(
    token: '{{product.lastModified}}',
    displayName: 'Product Last Modified',
    category: 'Product',
    getValue: (p, v, [_]) => p?.lastModified?.toIso8601String() ?? '',
  ),

  // ================= NUTRITION FACTS TOKENS =================
  TemplateToken(
    token: '{{product.nutrition.calories}}',
    displayName: 'Calories (kcal)',
    category: 'Nutrition',
    getValue: (p, v, [_]) => p?.nutritionFacts?.calories.toString() ?? '',
  ),
  TemplateToken(
    token: '{{product.nutrition.protein}}',
    displayName: 'Protein (g)',
    category: 'Nutrition',
    getValue: (p, v, [_]) => p?.nutritionFacts?.protein.toString() ?? '',
  ),
  TemplateToken(
    token: '{{product.nutrition.totalFat}}',
    displayName: 'Total Fat (g)',
    category: 'Nutrition',
    getValue: (p, v, [_]) => p?.nutritionFacts?.totalFat.toString() ?? '',
  ),
  TemplateToken(
    token: '{{product.nutrition.saturatedFat}}',
    displayName: 'Saturated Fat (g)',
    category: 'Nutrition',
    getValue: (p, v, [_]) => p?.nutritionFacts?.saturatedFat.toString() ?? '',
  ),
  TemplateToken(
    token: '{{product.nutrition.totalCarbs}}',
    displayName: 'Total Carbs (g)',
    category: 'Nutrition',
    getValue: (p, v, [_]) => p?.nutritionFacts?.totalCarbs.toString() ?? '',
  ),
  TemplateToken(
    token: '{{product.nutrition.fiber}}',
    displayName: 'Fiber (g)',
    category: 'Nutrition',
    getValue: (p, v, [_]) => p?.nutritionFacts?.fiber.toString() ?? '',
  ),

  // ================= VARIANT TOKENS =================
  TemplateToken(
    token: '{{variant.name}}',
    displayName: 'Variant Name',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.name ?? '',
  ),
  TemplateToken(
    token: '{{variant.sku}}',
    displayName: 'Variant SKU',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.sku ?? '',
  ),
  TemplateToken(
    token: '{{variant.quantity}}',
    displayName: 'Variant Quantity',
    category: 'Variant',
    getValue: (p, v, [_]) => v != null
        ? (v.quantity % 1 == 0 ? v.quantity.toInt().toString() : v.quantity.toString())
        : '',
  ),
  TemplateToken(
    token: '{{variant.unit}}',
    displayName: 'Variant Unit',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.unit ?? '',
  ),
  TemplateToken(
    token: '{{variant.wholesale}}',
    displayName: 'Wholesale Price',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.wholesale.toStringAsFixed(2) ?? '',
  ),
  TemplateToken(
    token: '{{variant.mrp}}',
    displayName: 'MRP Price',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.mrp.toStringAsFixed(2) ?? '',
  ),
  TemplateToken(
    token: '{{variant.unitPrice}}',
    displayName: 'Unit Price',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.unitPrice.toStringAsFixed(2) ?? '',
  ),
  TemplateToken(
    token: '{{variant.defaultTemplateId}}',
    displayName: 'Variant Default Template ID',
    category: 'Variant',
    getValue: (p, v, [_]) => v?.defaultTemplateId ?? '',
  ),

  // ================= LEGACY / BACKWARD COMPATIBILITY ALIASES =================
  TemplateToken(
    token: '{{mfg}}',
    displayName: 'MFG Date (Legacy)',
    category: 'System',
    getValue: (p, v, [mfgDate]) => _formattedMfgDate(mfgDate),
    visibleInDropdown: false,
  ),
  TemplateToken(
    token: '{{mfgDate}}',
    displayName: 'MFG Date (Legacy 2)',
    category: 'System',
    getValue: (p, v, [mfgDate]) => _formattedMfgDate(mfgDate),
    visibleInDropdown: false,
  ),
  TemplateToken(
    token: '{{product.mfgDate}}',
    displayName: 'MFG Date (Legacy 3)',
    category: 'System',
    getValue: (p, v, [mfgDate]) => _formattedMfgDate(mfgDate),
    visibleInDropdown: false,
  ),
  TemplateToken(
    token: '{{product.mfg}}',
    displayName: 'MFG Date (Legacy 4)',
    category: 'System',
    getValue: (p, v, [mfgDate]) => _formattedMfgDate(mfgDate),
    visibleInDropdown: false,
  ),
];
