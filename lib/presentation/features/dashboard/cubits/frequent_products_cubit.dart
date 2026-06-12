import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

part 'frequent_products_state.dart';


/// Manages the state for the "Frequent Products" table section
/// of the Dashboard screen.
///
/// ## State Lifecycle
/// ```text
/// Initial ──(loadFrequentProducts)──▶ Loading ──(success)──▶ Loaded
///                                              └──(failure)──▶ Error
///          Error ──(loadFrequentProducts retry)──▶ Loading
/// ```
class FrequentProductsCubit extends Cubit<FrequentProductsState> {
  /// Creates a [FrequentProductsCubit] instance.
  FrequentProductsCubit({required ProductRepository productRepository})
      : _repository = productRepository,
        super(const FrequentProductsInitial());

  final ProductRepository _repository;

  /// Fetches the most frequently printed products and emits the
  /// appropriate state.
  Future<void> loadFrequentProducts() async {
    emit(const FrequentProductsLoading());
    final result = await _repository.getFrequentProducts(limit: 6);
    switch (result) {
      case Success(value: final products):
        emit(FrequentProductsLoaded(products: products));
      case Failure(error: final err):
        emit(FrequentProductsError(message: err.message));
    }
  }
}
