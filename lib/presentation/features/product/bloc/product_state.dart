import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductPageLoading extends ProductState {
  const ProductPageLoading();
}

class ProductPageLoaded extends ProductState {
  const ProductPageLoaded({
    required this.items,
    required this.currentPage,
    required this.hasMore,
    this.searchQuery,
    this.categoryFilter,
    this.subView = const ProductCatalogView(),
  });

  final List<Product> items;
  final int currentPage;
  final bool hasMore;
  final String? searchQuery;
  final String? categoryFilter;
  final ProductSubView subView;

  @override
  List<Object?> get props => [
        items,
        currentPage,
        hasMore,
        searchQuery,
        categoryFilter,
        subView,
      ];

  ProductPageLoaded copyWith({
    List<Product>? items,
    int? currentPage,
    bool? hasMore,
    String? searchQuery,
    String? categoryFilter,
    ProductSubView? subView,
  }) {
    return ProductPageLoaded(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      categoryFilter: categoryFilter ?? this.categoryFilter,
      subView: subView ?? this.subView,
    );
  }
}

class ProductPageError extends ProductState {
  const ProductPageError(this.message);

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

class ProductFormError extends ProductState {
  const ProductFormError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
