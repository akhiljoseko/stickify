import 'package:equatable/equatable.dart';

class Ingredient extends Equatable {
  const Ingredient({
    required this.name,
    required this.percentage,
  });

  final String name;
  final double percentage;

  @override
  List<Object?> get props => [name, percentage];
}
