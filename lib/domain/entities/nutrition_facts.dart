import 'package:equatable/equatable.dart';

class NutritionFacts extends Equatable {
  const NutritionFacts({
    required this.calories,
    required this.protein,
    required this.totalFat,
    required this.saturatedFat,
    required this.totalCarbs,
    required this.fiber,
  });

  final double calories;     // kcal
  final double protein;      // g
  final double totalFat;     // g
  final double saturatedFat; // g
  final double totalCarbs;   // g
  final double fiber;        // g

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
