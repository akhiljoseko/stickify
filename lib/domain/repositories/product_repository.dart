// The doc comments reference totalPrints, which is a property on Product entity and is not directly resolvable here.
// ignore_for_file: comment_references
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';

/// Abstract repository interface for product catalogue operations.
///
/// Belongs to the global domain layer. Concrete implementations live in
/// `lib/data/repositories/`. Cubits depend only on this interface,
/// never on the concrete implementation.
abstract interface class ProductRepository {
  /// Returns products sorted by [totalPrints] descending.
  ///
  /// [limit] controls how many products to return (default: 20).
  Future<Result<List<Product>, AppError>> getFrequentProducts({int limit = 20});

  /// Returns a single product by its unique [id], or `null` if not found.
  Future<Result<Product?, AppError>> getProductById(String id);

  /// Returns all products in the catalogue.
  Future<Result<List<Product>, AppError>> getAllProducts();

  /// Saves (creates or updates) a product in the catalogue.
  Future<Result<void, AppError>> saveProduct(Product product);

  /// Deletes a product by its unique [id].
  Future<Result<void, AppError>> deleteProduct(String id);
}
