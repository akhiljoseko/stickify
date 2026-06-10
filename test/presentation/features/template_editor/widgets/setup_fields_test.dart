import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/features/template_editor/widgets/setup_fields.dart';

void main() {
  group('SetupNumberField Tests', () {
    testWidgets('renders initial integer value without trailing decimal', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupNumberField(
              value: 210,
              labelText: 'Width',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('210'), findsOneWidget);
    });

    testWidgets('renders initial decimal value with decimal representation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupNumberField(
              value: 12.5,
              labelText: 'Width',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('12.5'), findsOneWidget);
    });

    testWidgets('typing text triggers onChanged callback', (tester) async {
      double? changedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupNumberField(
              value: 10,
              labelText: 'Width',
              onChanged: (val) {
                changedVal = val;
              },
            ),
          ),
        ),
      );

      final finder = find.byType(TextFormField);
      await tester.enterText(finder, '15.5');
      expect(changedVal, 15.5);
    });

    testWidgets('losing focus restores value when text is empty/invalid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupNumberField(
              value: 10,
              labelText: 'Width',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final finder = find.byType(TextFormField);
      await tester.tap(finder);
      await tester.enterText(finder, '');
      await tester.pump();

      // Shift focus away
      FocusScope.of(tester.element(finder)).unfocus();
      await tester.pump();

      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('external value updates update text controller if unfocused', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupNumberField(
              value: 10,
              labelText: 'Width',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupNumberField(
              value: 15,
              labelText: 'Width',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('15'), findsOneWidget);
    });
  });

  group('SetupIntField Tests', () {
    testWidgets('renders initial value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupIntField(
              value: 5,
              labelText: 'Columns',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('typing integer text triggers onChanged callback', (tester) async {
      int? changedVal;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupIntField(
              value: 5,
              labelText: 'Columns',
              onChanged: (val) {
                changedVal = val;
              },
            ),
          ),
        ),
      );

      final finder = find.byType(TextFormField);
      await tester.enterText(finder, '12');
      expect(changedVal, 12);
    });

    testWidgets('losing focus restores value when empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SetupIntField(
              value: 5,
              labelText: 'Columns',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final finder = find.byType(TextFormField);
      await tester.tap(finder);
      await tester.enterText(finder, '');
      await tester.pump();

      FocusScope.of(tester.element(finder)).unfocus();
      await tester.pump();

      expect(find.text('5'), findsOneWidget);
    });
  });
}
