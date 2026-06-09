import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

/// Mock implementation of [ProductRepository].
///
/// Returns realistic hardcoded product data matching the Stitch dashboard
/// design's "Frequent Products" table. Replace this with a real
/// network/database implementation when the backend is ready.
class MockProductRepository implements ProductRepository {
  const MockProductRepository();

  /// Realistic mock data sourced from the Stitch "Frequent Products" table.
  static final List<Product> _mockProducts = [
    Product(
      id: 'prod-001',
      name: 'Organic Cold Brew 12oz',
      sku: 'BEV-CB-ORG-12',
      totalPrints: 1240,
      lastPrintedAt: DateTime(2023, 10, 24, 14, 30),
      assignedStation: 'Station #02',
      stationStatus: StationStatus.online,
      category: 'Beverages',
    ),
    Product(
      id: 'prod-002',
      name: 'Eco-Wrap Large 50m',
      sku: 'PKG-EW-LRG-50',
      totalPrints: 892,
      lastPrintedAt: DateTime(2023, 10, 24, 11, 15),
      assignedStation: 'Station #05',
      stationStatus: StationStatus.online,
      category: 'Packaging',
    ),
    Product(
      id: 'prod-003',
      name: 'Safety Warning Label (Multi)',
      sku: 'HAZ-WRN-GEN-M',
      totalPrints: 550,
      lastPrintedAt: DateTime(2023, 10, 23, 9, 45),
      assignedStation: 'Station #01',
      stationStatus: StationStatus.warning,
      category: 'Safety',
    ),
    Product(
      id: 'prod-004',
      name: 'Pro-X Gaming Headset',
      sku: 'GAM-2024-XP01',
      totalPrints: 310,
      lastPrintedAt: DateTime(2023, 10, 22, 16),
      assignedStation: 'Station #03',
      stationStatus: StationStatus.online,
      category: 'Electronics',
    ),
    Product(
      id: 'prod-005',
      name: 'Industrial Drill Bit Set',
      sku: 'TL-DR-9922',
      totalPrints: 275,
      lastPrintedAt: DateTime(2023, 10, 22, 11, 30),
      assignedStation: 'Station #01',
      stationStatus: StationStatus.online,
      category: 'Tools',
    ),
    Product(
      id: 'prod-006',
      name: 'LED Panel XL-400',
      sku: 'LT-LP-0400',
      totalPrints: 198,
      lastPrintedAt: DateTime(2023, 10, 21, 14),
      assignedStation: 'Station #04',
      stationStatus: StationStatus.offline,
      category: 'Lighting',
    ),
  ];

  @override
  Future<List<Product>> getFrequentProducts({int limit = 20}) async {
    // Simulate a 700ms network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    // Already sorted by totalPrints descending in the mock list.
    return _mockProducts.take(limit).toList();
  }

  @override
  Future<Product?> getProductById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    for (final product in _mockProducts) {
      if (product.id == id) {
        return product;
      }
    }
    return null;
  }

  @override
  Future<List<Product>> getAllProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return List.unmodifiable(_mockProducts);
  }
}
