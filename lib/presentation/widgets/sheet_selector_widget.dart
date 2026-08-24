import 'package:flutter/material.dart';

/// Standalone, reusable UI widget displaying an interactive grid of rounded
/// square page chips numbered 1 through [totalSheets] for arbitrary sheet selection.
class SheetSelectorWidget extends StatefulWidget {
  /// Creates a [SheetSelectorWidget] instance.
  const SheetSelectorWidget({
    required this.totalSheets,
    required this.onSelectionChanged,
    this.initialSelectedSheets,
    super.key,
  });

  /// Total physical sheets in the batch job.
  final int totalSheets;

  /// Optional set of initial 1-indexed selected sheet numbers.
  /// If null, defaults to selecting all sheets.
  final Set<int>? initialSelectedSheets;

  /// Callback fired whenever the user modifies sheet selections.
  final ValueChanged<Set<int>> onSelectionChanged;

  @override
  State<SheetSelectorWidget> createState() => _SheetSelectorWidgetState();
}

class _SheetSelectorWidgetState extends State<SheetSelectorWidget> {
  late Set<int> _selectedSheets;

  @override
  void initState() {
    super.initState();
    _selectedSheets = widget.initialSelectedSheets != null
        ? Set<int>.from(widget.initialSelectedSheets!)
        : Set<int>.from(List.generate(widget.totalSheets, (i) => i + 1));
  }

  void _toggleSheet(int sheetNumber) {
    setState(() {
      if (_selectedSheets.contains(sheetNumber)) {
        _selectedSheets.remove(sheetNumber);
      } else {
        _selectedSheets.add(sheetNumber);
      }
    });
    widget.onSelectionChanged(_selectedSheets);
  }

  void _selectAll() {
    setState(() {
      _selectedSheets = Set<int>.from(
        List.generate(widget.totalSheets, (i) => i + 1),
      );
    });
    widget.onSelectionChanged(_selectedSheets);
  }

  void _clearAll() {
    setState(() {
      _selectedSheets.clear();
    });
    widget.onSelectionChanged(_selectedSheets);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isAllSelected = _selectedSheets.length == widget.totalSheets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Sheets (${_selectedSheets.length} of ${widget.totalSheets})',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton.icon(
                  onPressed: isAllSelected ? null : _selectAll,
                  icon: const Icon(Icons.select_all_rounded, size: 16),
                  label: const Text('Select All'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _selectedSheets.isEmpty ? null : _clearAll,
                  icon: const Icon(Icons.deselect_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Grid of Page Chips
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(widget.totalSheets, (index) {
            final sheetNumber = index + 1;
            final isSelected = _selectedSheets.contains(sheetNumber);

            return Material(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => _toggleSheet(sheetNumber),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sheet',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: isSelected
                              ? colorScheme.onPrimary.withAlpha(200)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$sheetNumber',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
