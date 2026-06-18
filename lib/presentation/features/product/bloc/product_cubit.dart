import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/bloc/product_paging_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

class ProductCubit extends Cubit<ProductState> {
  ProductCubit(this._productRepository)
      : super(ProductPageLoaded(
          pagingState: ProductPagingState(isLoading: true),
        ));

  final ProductRepository _productRepository;

  Future<void> fetchPage({
    required int pageKey,
    required int pageSize,
    String? query,
    String? category,
  }) async {
    final currentState = state;
    final previousPaging = currentState is ProductPageLoaded ? currentState.pagingState : null;

    if (pageKey == 0) {
      emit(ProductPageLoaded(
        pagingState: ProductPagingState(
          isLoading: true,
          searchQuery: query,
          categoryFilter: category,
        ),
        subView: currentState is ProductPageLoaded ? currentState.subView : const ProductCatalogView(),
      ));
    } else {
      emit(ProductPageLoaded(
        pagingState: previousPaging!.copyWith(isLoading: true),
        subView: (currentState as ProductPageLoaded).subView,
      ));
    }

    final result = await _productRepository.getProducts(
      page: pageKey,
      pageSize: pageSize,
      query: query,
      category: category,
    );

    switch (result) {
      case Success(value: final paginated):
        final loadedState = state;
        if (loadedState is! ProductPageLoaded) return;

        final isFirstPage = pageKey == 0;
        final newPages = isFirstPage
            ? [paginated.items]
            : [...?loadedState.pagingState.pages, paginated.items];
        final newKeys = isFirstPage
            ? [pageKey]
            : [...?loadedState.pagingState.keys, pageKey];

        emit(loadedState.copyWith(
          pagingState: loadedState.pagingState.copyWith(
            pages: newPages,
            keys: newKeys,
            hasNextPage: paginated.hasMore,
            isLoading: false,
            error: null,
            searchQuery: query,
            categoryFilter: category,
          ),
        ));
      case Failure(error: final err):
        final failedState = state;
        if (failedState is! ProductPageLoaded) return;
        emit(failedState.copyWith(
          pagingState: failedState.pagingState.copyWith(
            isLoading: false,
            error: err.message,
          ),
        ));
    }
  }

  void fetchNextPage() {
    final currentState = state;
    if (currentState is! ProductPageLoaded) return;
    final pagingState = currentState.pagingState;
    if (!pagingState.hasNextPage || pagingState.isLoading || pagingState.error != null) return;

    final nextPageKey = (pagingState.keys?.last ?? 0) + 1;
    fetchPage(
      pageKey: nextPageKey,
      pageSize: 20,
      query: pagingState.searchQuery,
      category: pagingState.categoryFilter,
    );
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
          final newPages = currentState.pagingState.pages
              ?.map((page) => page.where((p) => p.id != id).toList())
              .toList();
          emit(currentState.copyWith(
            pagingState: currentState.pagingState.copyWith(pages: newPages),
          ));
        } else {
          await fetchPage(pageKey: 0, pageSize: 20);
        }
      case Failure(error: final err):
        emit(ProductFormError(err.message));
    }
  }
}
