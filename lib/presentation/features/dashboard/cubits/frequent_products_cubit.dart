import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/variant_print_stats.dart';
import 'package:stickify/domain/repositories/variant_print_stats_repository.dart';

part 'frequent_products_state.dart';

class FrequentProductsCubit extends Cubit<FrequentVariantsState> {
  FrequentProductsCubit({
    required VariantPrintStatsRepository variantPrintStatsRepository,
  }) : _repository = variantPrintStatsRepository,
       super(const FrequentVariantsInitial());

  final VariantPrintStatsRepository _repository;

  Future<void> loadFrequentVariants() async {
    emit(const FrequentVariantsLoading());
    final result = await _repository.getTopFrequent();
    switch (result) {
      case Success(value: final variants):
        emit(FrequentVariantsLoaded(variants: variants));
      case Failure(error: final err):
        emit(FrequentVariantsError(message: err.message));
    }
  }
}
