// Doc-comment code blocks reference framework types outside doc scope.
// ignore_for_file: missing_code_block_language_in_doc_comment
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';

part 'frequent_products_state.dart';

/// Manages the state for the "Frequent Products" table section
/// of the Dashboard screen.
///
/// ## State Lifecycle
/// ```
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
    try {
      final products = await _repository.getFrequentProducts(limit: 6);
      emit(FrequentProductsLoaded(products: products));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(FrequentProductsError(message: e.toString()));
    }
  }
}
