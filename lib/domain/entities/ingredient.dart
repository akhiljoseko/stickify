import 'package:equatable/equatable.dart';

/// Represents a single ingredient content percentage in a product.
///
/// Used for industrial cataloging and automated Allergen Warnings.
class Ingredient extends Equatable {
  /// Creates an [Ingredient] record.
  const Ingredient({
    required this.name,
    required this.percentage,
  });

  /// Name of the ingredient (e.g. "Organic Honey").
  final String name;

  /// Percentage of the ingredient (0 to 100).
  final double percentage;

  @override
  List<Object?> get props => [name, percentage];
}
