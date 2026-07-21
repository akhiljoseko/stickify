import 'package:flutter/material.dart';

/// A reusable dropdown widget for selecting a product/variant quantity unit.
class QuantityUnitDropdown extends StatelessWidget {
  const QuantityUnitDropdown({
    required this.initialValue,
    required this.onChanged,
    this.isExpanded = false,
    super.key,
  });

  /// The initially selected value (optional).
  final String? initialValue;

  /// Callback triggered when a new unit is selected.
  final ValueChanged<String?> onChanged;

  /// Whether the dropdown should occupy all available horizontal space.
  final bool isExpanded;

  /// The list of supported quantity units.
  static const List<String> units = ['pcs', 'ml', 'gm', 'kg', 'L'];

  @override
  Widget build(BuildContext context) {
    final selectedValue = units.contains(initialValue) ? initialValue : 'gm';
    return DropdownButtonFormField<String>(
      isExpanded: isExpanded,
      initialValue: selectedValue,
      decoration: const InputDecoration(labelText: 'Unit'),
      items: units
          .map(
            (unit) => DropdownMenuItem<String>(
              value: unit,
              child: Text(unit),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}
