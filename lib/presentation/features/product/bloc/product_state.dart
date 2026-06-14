import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductCatalogInitial extends ProductState {
  const ProductCatalogInitial();
}

class ProductCatalogLoading extends ProductState {
  const ProductCatalogLoading();
}

class ProductCatalogSuccess extends ProductState {
  const ProductCatalogSuccess({
    required this.products,
    required this.filteredProducts,
    this.searchQuery = '',
    this.categoryFilter = '',
    this.subView = const ProductCatalogView(),
  });

  final List<Product> products;
  final List<Product> filteredProducts;
  final String searchQuery;
  final String categoryFilter;
  final ProductSubView subView;

  @override
  List<Object?> get props => [
        products,
        filteredProducts,
        searchQuery,
        categoryFilter,
        subView,
      ];

  ProductCatalogSuccess copyWith({
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    String? categoryFilter,
    ProductSubView? subView,
  }) {
    return ProductCatalogSuccess(
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      subView: subView ?? this.subView,
    );
  }
}

class ProductCatalogError extends ProductState {
  const ProductCatalogError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

class ProductFormSubmitting extends ProductState {
  const ProductFormSubmitting();
}

class ProductFormSuccess extends ProductState {
  const ProductFormSuccess();
}
