import 'package:equatable/equatable.dart';

/// Represents the nutritional information facts of a product.
///
/// Holds basic values like calories, protein, fats, and carbohydrates,
/// typically displayed on label templates.
class NutritionFacts extends Equatable {
  /// Creates a [NutritionFacts] configuration.
  const NutritionFacts({
    required this.calories,
    required this.protein,
    required this.totalFat,
    required this.saturatedFat,
    required this.totalCarbs,
    required this.fiber,
  });

  /// Calories count in kilocalories (kcal).
  final double calories;

  /// Protein content in grams (g).
  final double protein;

  /// Total fat content in grams (g).
  final double totalFat;

  /// Saturated fat content in grams (g).
  final double saturatedFat;

  /// Total carbohydrate content in grams (g).
  final double totalCarbs;

  /// Dietary fiber content in grams (g).
  final double fiber;

  @override
  List<Object?> get props => [
        calories,
        protein,
        totalFat,
        saturatedFat,
        totalCarbs,
        fiber,
      ];
}
