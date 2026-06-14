import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._productRepository) : super(const ProductCatalogInitial());

  final ProductRepository _productRepository;

  Future<void> loadProducts({String? initialSubView}) async {
    final currentState = state;
    var query = '';
    var category = '';
    ProductSubView subView = const ProductCatalogView();
    
    if (currentState is ProductCatalogSuccess) {
      query = currentState.searchQuery;
      category = currentState.categoryFilter;
      if (initialSubView == null) {
        subView = currentState.subView;
      } else {
        if (initialSubView == 'create') {
          subView = const ProductCreateView();
        } else {
          subView = const ProductCatalogView();
        }
      }
    } else {
      emit(const ProductCatalogLoading());
      if (initialSubView == 'create') {
        subView = const ProductCreateView();
      }
    }

    final result = await _productRepository.getAllProducts();
    switch (result) {
      case Success(value: final products):
        final filtered = products.where((product) {
          final matchesQuery = query.isEmpty ||
              product.name.toLowerCase().contains(query.toLowerCase()) ||
              product.sku.toLowerCase().contains(query.toLowerCase());
          final matchesCategory = category.isEmpty ||
              (product.category ?? '').toLowerCase() == category.toLowerCase();
          return matchesQuery && matchesCategory;
        }).toList();

        emit(ProductCatalogSuccess(
          products: products,
          filteredProducts: filtered,
          searchQuery: query,
          categoryFilter: category,
          subView: subView,
        ));
      case Failure(error: final err):
        emit(ProductCatalogError(err.message));
    }
  }

  void applyFilter({String? query, String? category}) {
    final currentState = state;
    if (currentState is! ProductCatalogSuccess) return;

    final newQuery = query ?? currentState.searchQuery;
    final newCategory = category ?? currentState.categoryFilter;

    final filtered = currentState.products.where((product) {
      final matchesQuery = newQuery.isEmpty ||
          product.name.toLowerCase().contains(newQuery.toLowerCase()) ||
          product.sku.toLowerCase().contains(newQuery.toLowerCase());
      final matchesCategory = newCategory.isEmpty ||
          (product.category ?? '').toLowerCase() == newCategory.toLowerCase();
      return matchesQuery && matchesCategory;
    }).toList();

    emit(currentState.copyWith(
      searchQuery: newQuery,
      categoryFilter: newCategory,
      filteredProducts: filtered,
    ));
  }

  void setSubView(ProductSubView subView) {
    final currentState = state;
    if (currentState is! ProductCatalogSuccess) return;
    emit(currentState.copyWith(
      subView: subView,
    ));
  }

  Future<void> saveProduct(Product product) async {
    emit(const ProductFormSubmitting());
    final result = await _productRepository.saveProduct(product);
    switch (result) {
      case Success():
        emit(const ProductFormSuccess());
        await loadProducts();
      case Failure(error: final err):
        emit(ProductCatalogError(err.message));
    }
  }

  Future<void> deleteProduct(String id) async {
    final currentState = state;
    final result = await _productRepository.deleteProduct(id);
    switch (result) {
      case Success():
        if (currentState is ProductCatalogSuccess) {
          final updatedProducts = currentState.products.where((p) => p.id != id).toList();
          final updatedFiltered = currentState.filteredProducts.where((p) => p.id != id).toList();
          emit(currentState.copyWith(
            products: updatedProducts,
            filteredProducts: updatedFiltered,
          ));
        } else {
          await loadProducts();
        }
      case Failure(error: final err):
        emit(ProductCatalogError(err.message));
    }
  }
}
