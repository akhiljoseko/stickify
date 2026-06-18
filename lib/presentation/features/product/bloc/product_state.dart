import 'package:equatable/equatable.dart';
import 'package:stickify/presentation/features/product/bloc/product_paging_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

sealed class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductPageLoaded extends ProductState {
  const ProductPageLoaded({
    required this.pagingState,
    this.subView = const ProductCatalogView(),
  });

  final ProductPagingState pagingState;
  final ProductSubView subView;

  @override
  List<Object?> get props => [pagingState, subView];

  ProductPageLoaded copyWith({
    ProductPagingState? pagingState,
    ProductSubView? subView,
  }) {
    return ProductPageLoaded(
      pagingState: pagingState ?? this.pagingState,
      subView: subView ?? this.subView,
    );
  }
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
