import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/properties_panel.dart';

void main() {
  group('RealTimeNumberField Tests', () {
    testWidgets('renders initial value formatted to 1 decimal place', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RealTimeNumberField(
              label: 'X Position',
              value: 45,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('45.0'), findsOneWidget);
    });

    testWidgets('calls onChanged when focus is lost after typing valid number', (tester) async {
      double? changedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RealTimeNumberField(
                  label: 'X Position',
                  value: 45,
                  onChanged: (val) {
                    changedVal = val;
                  },
                ),
                const SizedBox(height: 100),
                TextFormField(),
              ],
            ),
          ),
        ),
      );

      final finder = find.byType(TextFormField).first;
      await tester.enterText(finder, '52.3');
      // Tap another focusable field to remove focus
      final otherFinder = find.byType(TextFormField).last;
      await tester.tap(otherFinder);
      await tester.pumpAndSettle();
      expect(changedVal, 52.3);
    });

    testWidgets('typing invalid number does not trigger onChanged', (tester) async {
      double? changedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RealTimeNumberField(
                  label: 'X Position',
                  value: 45,
                  onChanged: (val) {
                    changedVal = val;
                  },
                ),
                const SizedBox(height: 100),
                TextFormField(),
              ],
            ),
          ),
        ),
      );

      final finder = find.byType(TextFormField).first;
      await tester.enterText(finder, 'abc');
      final otherFinder = find.byType(TextFormField).last;
      await tester.tap(otherFinder);
      await tester.pumpAndSettle();
      expect(changedVal, isNull);
    });

    testWidgets('external value updates change text controller when different', (tester) async {
      var currentValue = 45.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RealTimeNumberField(
                  label: 'X Position',
                  value: currentValue,
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('45.0'), findsOneWidget);

      currentValue = 60.5;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return RealTimeNumberField(
                  label: 'X Position',
                  value: currentValue,
                  onChanged: (_) {},
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('60.5'), findsOneWidget);
    });
  });
}
