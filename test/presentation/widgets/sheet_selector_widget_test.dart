import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/widgets/sheet_selector_widget.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SheetSelectorWidget Unit Tests', () {
    testWidgets('renders all sheet chips and handles toggling', (tester) async {
      Set<int>? emittedSelection;

      await tester.pumpApp(
        Scaffold(
          body: SheetSelectorWidget(
            totalSheets: 5,
            initialSelectedSheets: const {1, 2, 3, 4, 5},
            onSelectionChanged: (updated) {
              emittedSelection = updated;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Selected Sheets (5 of 5)'), findsOneWidget);
      expect(find.text('Sheet'), findsNWidgets(5));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);

      // Tap Sheet 4 to toggle off
      await tester.tap(find.text('4'));
      await tester.pumpAndSettle();

      expect(emittedSelection, equals({1, 2, 3, 5}));
      expect(find.text('Selected Sheets (4 of 5)'), findsOneWidget);

      // Tap Clear
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(emittedSelection, isEmpty);
      expect(find.text('Selected Sheets (0 of 5)'), findsOneWidget);

      // Tap Select All
      await tester.tap(find.text('Select All'));
      await tester.pumpAndSettle();

      expect(emittedSelection, equals({1, 2, 3, 4, 5}));
      expect(find.text('Selected Sheets (5 of 5)'), findsOneWidget);
    });
  });
}
