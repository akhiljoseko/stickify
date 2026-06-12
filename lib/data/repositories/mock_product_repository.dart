import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/ingredient.dart';
import 'package:stickify/domain/entities/nutrition_facts.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/entities/product_variant.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

/// Mock implementation of [ProductRepository].
///
/// Returns realistic hardcoded product data matching the Stitch dashboard
/// design's "Frequent Products" table and the "Product Management - List" page.
class MockProductRepository implements ProductRepository {
  /// Creates a [MockProductRepository] instance.
  const MockProductRepository();

  /// Realistic mock data sourced from the Stitch "Frequent Products" table.
  static final List<Product> _mockProducts = [
    Product(
      id: 'prod-001',
      name: 'ChronoMaster Elite',
      sku: 'WTCH-293-882-EL',
      totalPrints: 1240,
      lastPrintedAt: DateTime(2023, 10, 24, 14, 30),
      assignedStation: 'Station #02',
      stationStatus: StationStatus.online,
      category: 'Electronics',
      shelfLifeDays: 365,
      storageConditions: 'Store in a dry cool place',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuC3T1bImjiXAIJUPhusdi1ReuRvEkp2m0VtnQ9W8EU1SIxc0TFF6JmX6Mx3D76bhAhutQeqZ9F4192PsY7lWN-_J3B7X3CINrq3fsvsigKjs6FCdhg45Bw2lVTQb24dwaz3UMY9Md4MoI7x_dNUuszxXLk580Sc8PnR0bLkDR0pYUJyuvKvylWKpE4gutI5Q963558NowrpmVuB7FsywjgpwdQ1btKX8kLcEPBnF2OenY5lq5Whdq8RH7J26yV6L1avt5NFVg-L3GA',
      ingredients: const [
        Ingredient(name: 'Steel Alloy', percentage: 70),
        Ingredient(name: 'Sapphire Glass', percentage: 20),
        Ingredient(name: 'Lithium Battery', percentage: 10),
      ],
      variants: const [
        ProductVariant(name: 'Silver Edition', quantity: 1, unit: 'pcs', wholesale: 150, mrp: 299, sku: 'WTCH-293-882-EL-SLV'),
        ProductVariant(name: 'Black Edition', quantity: 1, unit: 'pcs', wholesale: 180, mrp: 349, sku: 'WTCH-293-882-EL-BLK'),
      ],
    ),
    Product(
      id: 'prod-002',
      name: 'OmniAudio Pro-X',
      sku: 'AUD-HX0-912-PR',
      totalPrints: 892,
      lastPrintedAt: DateTime(2023, 10, 24, 11, 15),
      assignedStation: 'Station #05',
      stationStatus: StationStatus.online,
      category: 'Peripherals',
      shelfLifeDays: 730,
      storageConditions: 'Keep away from moisture',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBdwpY5R7-R9EuiJZ7Teo4xBDrd-K5bSvJpiwyy-c7GPzatq5SQ_5YKvctKbUgJa4H9yOJXLYw2sGG3qe6b5HX_mS3t3u4SDJPGu-mLQJYfcd0T6WXF7zPBgr9rZM53-SSEVv-7faev4ndpUPlDbHBXRI8lj1yBHRE2IFW2ILxFYkkj54ewh8XNxvqXhf2HcVrU9iyINRs3SZOXK6eXso5P3MD-r9XyabfJHnh9crZSCPz77upXyX5hViYF63e405PZmP_cF7PBg0Y',
      ingredients: const [
        Ingredient(name: 'Polycarbonate', percentage: 50),
        Ingredient(name: 'Copper Wiring', percentage: 30),
        Ingredient(name: 'Memory Foam', percentage: 20),
      ],
      variants: const [
        ProductVariant(name: 'Standard Black', quantity: 1, unit: 'pcs', wholesale: 85, mrp: 149, sku: 'AUD-HX0-912-PR-BLK'),
      ],
    ),
    Product(
      id: 'prod-003',
      name: 'SwiftRunner Apex',
      sku: 'FWR-SH-442-AP',
      totalPrints: 550,
      lastPrintedAt: DateTime(2023, 10, 23, 9, 45),
      assignedStation: 'Station #01',
      stationStatus: StationStatus.warning,
      category: 'Apparel',
      shelfLifeDays: 1095,
      storageConditions: 'Store in dry ventilation',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCix4ihNcXAP17_XOvGMW8un6M-kmr_PtCu2KjCRKiX9z7AnkE2qTYRFhQoQ7bVWkavZvrgdkL6SWin-U3fO8TOwdknwaDuy9OuXJI36AQp5wfxPz193qK4QU_YUBJcJaeRA-1-f1n07XxpvzG-0oMDnqTpzl9CP2zFm24Us72RQeTiJVf_KghQiVZEk3IR1wH3gTFYpcv5YR8vDe82AABcxofFdPhT6PuiXAvlXHB_1RXoXF9aYk5uGW6JEeXTNuDGDbD_jq8r1eU',
      ingredients: const [
        Ingredient(name: 'Technical Mesh Poly', percentage: 60),
        Ingredient(name: 'Rubber Sole', percentage: 40),
      ],
      variants: const [
        ProductVariant(name: 'Size 9', quantity: 1, unit: 'pcs', wholesale: 45, mrp: 89, sku: 'FWR-SH-442-AP-09'),
        ProductVariant(name: 'Size 10', quantity: 1, unit: 'pcs', wholesale: 45, mrp: 89, sku: 'FWR-SH-442-AP-10'),
      ],
    ),
    Product(
      id: 'prod-004',
      name: 'Lumina Lens 35mm',
      sku: 'OPT-CAM-001-LM',
      totalPrints: 310,
      lastPrintedAt: DateTime(2023, 10, 22, 16),
      assignedStation: 'Station #03',
      stationStatus: StationStatus.online,
      category: 'Optics',
      shelfLifeDays: 1825,
      storageConditions: 'Store in a cool dust-free cabinet',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBawxukA-5o9MvMWYQIAZQXEQxlPhQOcwc_HoWiUbh26HqvzOKW6oE8QoAyGNIrCy4vaJ6XRtgUi2h0svmeKDlBR_RvZixFXzL7F9qr6u7ItAiGjOuHGLEmcXhsux21ICM3jCZdTefJgEzFrzQPC9UgjzbvtuwIGvlU0Yw97d7NzowUfJKj9B4KB0gdPSfLZHzs8ApSDZbkSnUWWpDh_277_i9vqCA1C3njy69GqzXcxQ3px0zIeQRccNWtMNKhRaeSfJ2x9Q8lb50',
      ingredients: const [
        Ingredient(name: 'Optical Glass', percentage: 50),
        Ingredient(name: 'Aluminum Alloy Body', percentage: 50),
      ],
      variants: const [
        ProductVariant(name: 'Standard 35mm', quantity: 35, unit: 'ml', wholesale: 450, mrp: 899, sku: 'OPT-CAM-001-LM-35'),
      ],
    ),
    Product(
      id: 'prod-005',
      name: 'Artisanal Toasted Almonds',
      sku: 'ALM-ORG-2024',
      totalPrints: 428,
      lastPrintedAt: DateTime(2023, 10, 24, 15, 45),
      assignedStation: 'Station #04',
      stationStatus: StationStatus.online,
      category: 'Dry Goods',
      shelfLifeDays: 365,
      storageConditions: 'Store in a cool, dry place away from direct sunlight. Once opened, keep in an airtight container to maintain crunchiness.',
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuDBCwu6kjXkC74hhN53Gq0e9paePBFwYT2XP9uIquLWdD_HG_ZIeD3z6C_ya1GcstHenEypaatw6DQilZOumQmJqO8XXIceIp_jRh4h5diPJmc-kh0GSADG6uaVZEYxJd1qrdW73KGaDTQBILADwYMk9zn5SFw6_b3fPaD3AVEvabkHFGIlNAj2VpTlrpEtfIvoTrlhCyVjCmUde5B0UZnQuZZiZAxtripCqiG0c0VK-QHnjkL2BxzAWN3M7tHSpY7KobyKclQ1vow',
      ingredients: const [
        Ingredient(name: 'Roasted Almonds', percentage: 80),
        Ingredient(name: 'Organic Honey', percentage: 10),
        Ingredient(name: 'Sea Salt', percentage: 5),
        Ingredient(name: 'Vegetable Oil', percentage: 3),
        Ingredient(name: 'Natural Flavoring', percentage: 2),
      ],
      nutritionFacts: const NutritionFacts(
        calories: 579,
        protein: 21,
        totalFat: 49,
        saturatedFat: 3.7,
        totalCarbs: 22,
        fiber: 12,
      ),
      variants: const [
        ProductVariant(name: '150g Pouch', quantity: 150, unit: 'gm', wholesale: 8.50, mrp: 12.50, sku: 'ALM-150P-001'),
        ProductVariant(name: '500g Jar', quantity: 500, unit: 'gm', wholesale: 24.99, mrp: 34.99, sku: 'ALM-500J-002'),
        ProductVariant(name: '1kg Bulk Box', quantity: 1, unit: 'kg', wholesale: 42, mrp: 59, sku: 'ALM-1000B-003'),
      ],
    ),
  ];

  @override
  Future<Result<List<Product>, AppError>> getFrequentProducts({int limit = 20}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return Result.success(_mockProducts.take(limit).toList());
  }

  @override
  Future<Result<Product?, AppError>> getProductById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    for (final product in _mockProducts) {
      if (product.id == id) {
        return Result.success(product);
      }
    }
    return const Result.success(null);
  }

  @override
  Future<Result<List<Product>, AppError>> getAllProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return Result.success(List.unmodifiable(_mockProducts));
  }

  @override
  Future<Result<void, AppError>> saveProduct(Product product) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final index = _mockProducts.indexWhere((p) => p.id == product.id);
    if (index != -1) {
      _mockProducts[index] = product;
    } else {
      _mockProducts.add(product);
    }
    return const Result.success(null);
  }

  @override
  Future<Result<void, AppError>> deleteProduct(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockProducts.removeWhere((p) => p.id == id);
    return const Result.success(null);
  }
}
