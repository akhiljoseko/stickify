import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._productRepository) : super(const ProductInitial());

  final ProductRepository _productRepository;

  Future<void> fetchPage({
    required int pageKey,
    required int pageSize,
    String? query,
    String? category,
  }) async {
    if (pageKey == 0) {
      emit(const ProductPageLoading());
    }

    final result = await _productRepository.getProducts(
      page: pageKey,
      pageSize: pageSize,
      query: query,
      category: category,
    );

    switch (result) {
      case Success(value: final paginated):
        emit(ProductPageLoaded(
          items: paginated.items,
          currentPage: pageKey,
          hasMore: paginated.hasMore,
          searchQuery: query,
          categoryFilter: category,
          subView: _currentSubView(),
        ));
      case Failure(error: final err):
        emit(ProductPageError(err.message));
    }
  }

  void setSubView(ProductSubView subView) {
    final currentState = state;
    if (currentState is ProductPageLoaded) {
      emit(currentState.copyWith(subView: subView));
    }
  }

  Future<void> saveProduct(Product product) async {
    emit(const ProductFormSubmitting());
    final result = await _productRepository.saveProduct(product);
    switch (result) {
      case Success():
        emit(const ProductFormSuccess());
        await fetchPage(pageKey: 0, pageSize: 20);
      case Failure(error: final err):
        emit(ProductFormError(err.message));
    }
  }

  Future<void> deleteProduct(String id) async {
    final result = await _productRepository.deleteProduct(id);
    switch (result) {
      case Success():
        final currentState = state;
        if (currentState is ProductPageLoaded) {
          final updatedItems = currentState.items.where((p) => p.id != id).toList();
          emit(currentState.copyWith(items: updatedItems));
        } else {
          await fetchPage(pageKey: 0, pageSize: 20);
        }
      case Failure(error: final err):
        emit(ProductFormError(err.message));
    }
  }

  ProductSubView _currentSubView() {
    final currentState = state;
    if (currentState is ProductPageLoaded) {
      return currentState.subView;
    }
    return const ProductCatalogView();
  }
}
