import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/paginated_result.dart';
import 'package:stickify/domain/entities/product.dart';

/// Abstract repository interface for product catalogue operations.
abstract interface class ProductRepository {
  /// Returns a single product by its unique [id], or `null` if not found.
  Future<Result<Product?, AppError>> getProductById(String id);

  /// Returns all products in the catalogue.
  Future<Result<List<Product>, AppError>> getAllProducts();

  /// Returns products matching [query] and/or [category] filters.
  @Deprecated('Use getProducts with pagination instead.')
  Future<Result<List<Product>, AppError>> getFilteredProducts({String query = '', String category = ''});

  /// Returns a paginated, filtered list of products.
  Future<Result<PaginatedResult<Product>, AppError>> getProducts({
    required int page,
    required int pageSize,
    String? query,
    String? category,
  });

  /// Saves (creates or updates) a product in the catalogue.
  Future<Result<void, AppError>> saveProduct(Product product);

  /// Deletes a product by its unique [id].
  Future<Result<void, AppError>> deleteProduct(String id);
}
