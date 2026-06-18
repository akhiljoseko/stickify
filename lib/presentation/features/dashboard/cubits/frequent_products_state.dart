part of 'frequent_products_cubit.dart';

sealed class FrequentVariantsState extends Equatable {
  const FrequentVariantsState();

  @override
  List<Object?> get props => [];
}

final class FrequentVariantsInitial extends FrequentVariantsState {
  const FrequentVariantsInitial();
}

final class FrequentVariantsLoading extends FrequentVariantsState {
  const FrequentVariantsLoading();
}

final class FrequentVariantsLoaded extends FrequentVariantsState {
  const FrequentVariantsLoaded({required this.variants});

  final List<VariantPrintStats> variants;

  @override
  List<Object?> get props => [variants];
}

final class FrequentVariantsError extends FrequentVariantsState {
  const FrequentVariantsError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
