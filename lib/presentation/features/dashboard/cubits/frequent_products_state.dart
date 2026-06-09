part of 'frequent_products_cubit.dart';

/// Sealed state hierarchy for [FrequentProductsCubit].
sealed class FrequentProductsState extends Equatable {
  const FrequentProductsState();

  @override
  List<Object?> get props => [];
}

/// Initial state — emitted before any load operation is triggered.
final class FrequentProductsInitial extends FrequentProductsState {
  const FrequentProductsInitial();
}

/// Loading state — emitted while the repository call is in flight.
final class FrequentProductsLoading extends FrequentProductsState {
  const FrequentProductsLoading();
}

/// Loaded state — emitted when products have been successfully fetched.
final class FrequentProductsLoaded extends FrequentProductsState {
  const FrequentProductsLoaded({required this.products});

  /// Products sorted by [Product.totalPrints] descending.
  final List<Product> products;

  @override
  List<Object?> get props => [products];
}

/// Error state — emitted when the repository call fails.
final class FrequentProductsError extends FrequentProductsState {
  const FrequentProductsError({required this.message});

  /// Human-readable error description for display in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}
