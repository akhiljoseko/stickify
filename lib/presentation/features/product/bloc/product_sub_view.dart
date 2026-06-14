import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/product.dart';

sealed class ProductSubView extends Equatable {
  const ProductSubView();

  @override
  List<Object?> get props => [];
}

class ProductCatalogView extends ProductSubView {
  const ProductCatalogView();
}

class ProductCreateView extends ProductSubView {
  const ProductCreateView();
}

class ProductEditView extends ProductSubView {
  const ProductEditView(this.product);
  
  final Product product;

  @override
  List<Object?> get props => [product];
}

class ProductDetailView extends ProductSubView {
  const ProductDetailView(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}
