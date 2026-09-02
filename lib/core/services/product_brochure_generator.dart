import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:stickify/domain/domain.dart';

/// Colour palette used throughout the catalogue PDF.
abstract final class _BrochureColors {
  static const PdfColor coverBg = PdfColor.fromInt(0xFF1A237E); // deep navy
  static const PdfColor coverText = PdfColors.white;
  static const PdfColor categoryHeader = PdfColor.fromInt(0xFF00695C); // teal
  static const PdfColor categoryHeaderText = PdfColors.white;
  static const PdfColor tableHeaderBg = PdfColor.fromInt(0xFFE8EAF6); // indigo-50
  static const PdfColor rowZebra = PdfColor.fromInt(0xFFF5F5F5); // grey-50
  static const PdfColor productNameText = PdfColor.fromInt(0xFF212121);
  static const PdfColor skuChipBg = PdfColor.fromInt(0xFFE0E0E0);
  static const PdfColor skuChipText = PdfColor.fromInt(0xFF616161);
  static const PdfColor metaText = PdfColor.fromInt(0xFF757575);
  static const PdfColor divider = PdfColor.fromInt(0xFFBDBDBD);
  static const PdfColor nutritionHeaderBg = PdfColor.fromInt(0xFFFFF8E1); // amber-50
  static const PdfColor accentGold = PdfColor.fromInt(0xFFF9A825);
}

/// Generates a styled, colour product-catalogue PDF brochure.
///
/// All products are grouped by category. Each product shows its SKU, shelf
/// life, storage conditions, ingredients, variant pricing (MRP only), and an
/// optional nutrition facts block. Product images are not included.
///
/// The generator is stateless and `const`-constructible.
class ProductBrochureGenerator {
  /// Creates a [ProductBrochureGenerator] instance.
  const ProductBrochureGenerator();

  static const String _brochureTitle = 'Product Catalogue';
  static const double _margin = 20.0 * PdfPageFormat.mm;
  static const PdfPageFormat _pageFormat = PdfPageFormat.a4;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Generates the brochure PDF bytes from [products] and saves/shares it
  /// to the platform-appropriate location.
  ///
  /// On desktop (Windows / macOS / Linux) the PDF is written to the system
  /// Downloads directory and the absolute file path is returned.
  ///
  /// On mobile (Android / iOS) the PDF is offered via the native share sheet
  /// so the user can save it to Files / Downloads; returns an empty string.
  Future<String> generateAndSave({required List<Product> products}) async {
    final bytes = await generatePdfBytes(products: products);
    final fileName =
        'product_catalogue_${DateTime.now().millisecondsSinceEpoch}.pdf';

    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      return _saveToDownloads(bytes: bytes, fileName: fileName);
    } else {
      await _shareOnMobile(bytes: bytes, fileName: fileName);
      return '';
    }
  }

  /// Generates and returns raw PDF bytes for [products].
  ///
  /// Exposed separately so callers can stream or preview without saving.
  Future<Uint8List> generatePdfBytes({required List<Product> products}) async {
    final doc = pw.Document(
      title: _brochureTitle,
      author: 'Label Grid',
      creator: 'Label Grid — Stickify',
    );

    // Group products by category (null → "General")
    final grouped = <String, List<Product>>{};
    for (final p in products) {
      final cat = (p.category?.trim().isNotEmpty ?? false)
          ? p.category!.trim()
          : 'General';
      (grouped[cat] ??= []).add(p);
    }
    final categories = grouped.keys.toList()..sort();

    // Count totals for cover page
    final totalProducts = products.length;
    final totalVariants =
        products.fold<int>(0, (sum, p) => sum + p.variants.length);

    // ── Cover page ────────────────────────────────────────────────────────
    doc.addPage(_buildCoverPage(
      categoryCount: categories.length,
      productCount: totalProducts,
      variantCount: totalVariants,
    ));

    // ── Content pages — one multi-widget page per category ────────────────
    for (final category in categories) {
      final categoryProducts = grouped[category]!;
      doc.addPage(_buildCategoryPage(
        category: category,
        products: categoryProducts,
      ));
    }

    return doc.save();
  }

  // ── Page builders ─────────────────────────────────────────────────────────

  pw.Page _buildCoverPage({
    required int categoryCount,
    required int productCount,
    required int variantCount,
  }) {
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')} '
        '${_monthName(now.month)} ${now.year}';

    return pw.Page(
      pageFormat: _pageFormat,
      margin: pw.EdgeInsets.zero,
      build: (ctx) => pw.Container(
        color: _BrochureColors.coverBg,
        child: pw.Stack(
          children: [
            // Decorative diagonal band (top-right corner)
            pw.Positioned(
              top: 0,
              right: 0,
              child: pw.CustomPaint(
                size: const PdfPoint(200, 200),
                painter: (canvas, size) {
                  canvas
                    ..setFillColor(
                      const PdfColor.fromInt(0xFF283593),
                    ) // slightly lighter navy
                    ..moveTo(200, 0)
                    ..lineTo(0, 0)
                    ..lineTo(200, 200)
                    ..fillPath();
                },
              ),
            ),

            // Accent gold bar at bottom
            pw.Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: pw.Container(
                height: 8,
                color: _BrochureColors.accentGold,
              ),
            ),

            // Main content
            pw.Padding(
              padding: const pw.EdgeInsets.all(60),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Spacer(),

                  // Company label chip
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: pw.BoxDecoration(
                      color: _BrochureColors.accentGold,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      'LABEL GRID',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _BrochureColors.coverBg,
                      ),
                    ),
                  ),
                  pw.SizedBox(height: 24),

                  // Title
                  pw.Text(
                    _brochureTitle.toUpperCase(),
                    style: const pw.TextStyle(
                      fontSize: 42,
                      fontWeight: pw.FontWeight.bold,
                      color: _BrochureColors.coverText,
                      letterSpacing: 2,
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // Divider line
                  pw.Container(
                    width: 80,
                    height: 3,
                    color: _BrochureColors.accentGold,
                  ),
                  pw.SizedBox(height: 24),

                  // Subtitle
                  pw.Text(
                    'Complete product reference with specifications,\n'
                    'variants, and pricing information.',
                    style: const pw.TextStyle(
                      fontSize: 14,
                      color: PdfColor.fromInt(0xFFB0BEC5),
                    ),
                  ),

                  pw.Spacer(),

                  // Stats row
                  pw.Row(
                    children: [
                      _coverStat(
                        value: '$categoryCount',
                        label: 'Categories',
                      ),
                      pw.SizedBox(width: 40),
                      _coverStat(
                        value: '$productCount',
                        label: 'Products',
                      ),
                      pw.SizedBox(width: 40),
                      _coverStat(
                        value: '$variantCount',
                        label: 'Variants',
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 32),

                  // Date footer
                  pw.Text(
                    'Generated on $dateStr',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColor.fromInt(0xFF78909C),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.MultiPage _buildCategoryPage({
    required String category,
    required List<Product> products,
  }) {
    return pw.MultiPage(
      pageFormat: _pageFormat,
      margin: const pw.EdgeInsets.all(_margin),
      header: (ctx) => _categoryHeader(category),
      footer: _pageFooter,
      build: (ctx) => [
        pw.SizedBox(height: 16),
        ...products.map(_buildProductCard),
      ],
    );
  }

  // ── Component builders ────────────────────────────────────────────────────

  pw.Widget _categoryHeader(String category) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const pw.BoxDecoration(
        color: _BrochureColors.categoryHeader,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Text(
        category.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: _BrochureColors.categoryHeaderText,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  pw.Widget _pageFooter(pw.Context ctx) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          _brochureTitle,
          style: const pw.TextStyle(
            fontSize: 8,
            color: _BrochureColors.metaText,
          ),
        ),
        pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: const pw.TextStyle(
            fontSize: 8,
            color: _BrochureColors.metaText,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildProductCard(Product product) {
    final sortedVariants = product.sortedVariants;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _BrochureColors.divider),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Product header ─────────────────────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF9FAFB),
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Product name
                    pw.Expanded(
                      child: pw.Text(
                        product.name,
                        style: const pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: _BrochureColors.productNameText,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    // SKU chip
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: pw.BoxDecoration(
                        color: _BrochureColors.skuChipBg,
                        borderRadius: pw.BorderRadius.circular(12),
                      ),
                      child: pw.Text(
                        'SKU: ${product.sku}',
                        style: const pw.TextStyle(
                          fontSize: 8,
                          color: _BrochureColors.skuChipText,
                        ),
                      ),
                    ),
                  ],
                ),

                // Meta row: shelf life + storage
                if (product.shelfLifeDays != null ||
                    product.storageConditions != null) ...[
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      if (product.shelfLifeDays != null)
                        _metaChip(
                          icon: '⏱',
                          text: 'Shelf life: ${product.shelfLifeDays} days',
                        ),
                      if (product.shelfLifeDays != null &&
                          product.storageConditions != null)
                        pw.SizedBox(width: 12),
                      if (product.storageConditions != null)
                        _metaChip(
                          icon: '❄',
                          text: product.storageConditions!,
                        ),
                    ],
                  ),
                ],

                // Ingredients
                if (product.ingredients.isNotEmpty) ...[
                  pw.SizedBox(height: 8),
                  pw.RichText(
                    text: pw.TextSpan(
                      children: [
                        const pw.TextSpan(
                          text: 'Ingredients: ',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: _BrochureColors.metaText,
                          ),
                        ),
                        pw.TextSpan(
                          text: product.ingredientsString,
                          style: const pw.TextStyle(
                            fontSize: 8,
                            color: _BrochureColors.metaText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Divider ────────────────────────────────────────────────────
          pw.Container(height: 1, color: _BrochureColors.divider),

          // ── Variants table ─────────────────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VARIANTS',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _BrochureColors.categoryHeader,
                    letterSpacing: 1,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildVariantsTable(sortedVariants),

                // ── Nutrition facts (optional) ─────────────────────────
                if (product.nutritionFacts != null) ...[
                  pw.SizedBox(height: 12),
                  _buildNutritionBlock(product.nutritionFacts!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildVariantsTable(List<ProductVariant> variants) {
    const headerStyle = pw.TextStyle(
      fontSize: 8,
      color: _BrochureColors.productNameText,
    );
    const cellStyle = pw.TextStyle(fontSize: 8);

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(3),
        1: pw.FlexColumnWidth(2),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(2),
      },
      border: pw.TableBorder.all(
        color: _BrochureColors.divider,
        width: 0.5,
      ),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(
            color: _BrochureColors.tableHeaderBg,
          ),
          children: [
            _tableCell('Variant Name', style: headerStyle, isHeader: true),
            _tableCell('Size', style: headerStyle, isHeader: true),
            _tableCell('SKU', style: headerStyle, isHeader: true),
            _tableCell('MRP (₹)', style: headerStyle, isHeader: true),
          ],
        ),

        // Data rows
        ...variants.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          final isZebra = i.isOdd;
          final bg = isZebra ? _BrochureColors.rowZebra : PdfColors.white;
          final sizeStr = v.quantity % 1 == 0
              ? '${v.quantity.toInt()} ${v.unit}'
              : '${v.quantity} ${v.unit}';
          final mrpStr = '₹ ${v.mrp.toStringAsFixed(2)}';

          return pw.TableRow(
            decoration: pw.BoxDecoration(color: bg),
            children: [
              _tableCell(v.name, style: cellStyle),
              _tableCell(sizeStr, style: cellStyle),
              _tableCell(v.sku, style: cellStyle),
              _tableCell(
                mrpStr,
                style: const pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: _BrochureColors.categoryHeader,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _buildNutritionBlock(NutritionFacts nf) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _BrochureColors.nutritionHeaderBg,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: _BrochureColors.accentGold, width: 0.5),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'NUTRITION FACTS (per 100g)',
            style: const pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _BrochureColors.accentGold,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _nutriCell('Calories', '${nf.calories.toStringAsFixed(0)} kcal'),
              _nutriCell('Protein', '${nf.protein.toStringAsFixed(1)} g'),
              _nutriCell('Total Fat', '${nf.totalFat.toStringAsFixed(1)} g'),
              _nutriCell(
                'Sat. Fat',
                '${nf.saturatedFat.toStringAsFixed(1)} g',
              ),
              _nutriCell(
                'Total Carbs',
                '${nf.totalCarbs.toStringAsFixed(1)} g',
              ),
              _nutriCell('Fiber', '${nf.fiber.toStringAsFixed(1)} g'),
            ],
          ),
        ],
      ),
    );
  }

  // ── Small helpers ─────────────────────────────────────────────────────────

  pw.Widget _coverStat({
    required String value,
    required String label,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: _BrochureColors.accentGold,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColor.fromInt(0xFFB0BEC5),
          ),
        ),
      ],
    );
  }

  pw.Widget _metaChip({required String icon, required String text}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFECEFF1),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Text(
        '$icon  $text',
        style: const pw.TextStyle(fontSize: 8, color: _BrochureColors.metaText),
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    pw.TextStyle? style,
    bool isHeader = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(
        text,
        style: style ??
            pw.TextStyle(
              fontSize: 8,
              fontWeight:
                  isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
      ),
    );
  }

  pw.Widget _nutriCell(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: const pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _BrochureColors.productNameText,
          ),
        ),
        pw.Text(
          label,
          style: const pw.TextStyle(
            fontSize: 7,
            color: _BrochureColors.metaText,
          ),
        ),
      ],
    );
  }

  // ── Platform-specific save helpers ────────────────────────────────────────

  Future<String> _saveToDownloads({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final downloadsDir = await getDownloadsDirectory();
    final dir = downloadsDir ?? await getApplicationDocumentsDirectory();
    if (!dir.existsSync()) await dir.create(recursive: true);

    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<void> _shareOnMobile({
    required Uint8List bytes,
    required String fileName,
  }) async {
    // Write to a temp file so share_plus can reference it
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/pdf')],
        subject: _brochureTitle,
        fileNameOverrides: [fileName],
      ),
    );
  }

  static String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
