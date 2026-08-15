import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/features/print/presentation/shared/manufacturing_date_picker.dart';

void main() {
  Widget buildTestWidget({
    required ValueChanged<DateTime> onDateChanged,
    DateTime? selectedDate,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ManufacturingDatePicker(
          selectedDate: selectedDate,
          onDateChanged: onDateChanged,
        ),
      ),
    );
  }

  group('ManufacturingDatePicker Widget Tests', () {
    testWidgets('renders Manufacturing Date title and default today badge', (tester) async {
      final now = DateTime.now();
      final day = now.day.toString().padLeft(2, '0');
      final month = now.month.toString().padLeft(2, '0');
      final expectedDateStr = '$day-$month-${now.year}';

      await tester.pumpWidget(
        buildTestWidget(
          onDateChanged: (_) {},
        ),
      );

      expect(find.text('Manufacturing Date'), findsOneWidget);
      expect(find.text(expectedDateStr), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('renders custom selected date and reset icon button', (tester) async {
      final customDate = DateTime(2025);

      await tester.pumpWidget(
        buildTestWidget(
          selectedDate: customDate,
          onDateChanged: (_) {},
        ),
      );

      expect(find.text('Manufacturing Date'), findsOneWidget);
      expect(find.text('01-01-2025'), findsOneWidget);
      expect(find.text('Today'), findsNothing);
      expect(find.byIcon(Icons.restart_alt_rounded), findsOneWidget);
    });

    testWidgets('tapping reset button emits today date', (tester) async {
      DateTime? emittedDate;

      await tester.pumpWidget(
        buildTestWidget(
          selectedDate: DateTime(2026, 5, 20),
          onDateChanged: (date) {
            emittedDate = date;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.restart_alt_rounded));
      await tester.pump();

      expect(emittedDate, isNotNull);
      final now = DateTime.now();
      expect(emittedDate!.year, equals(now.year));
      expect(emittedDate!.month, equals(now.month));
      expect(emittedDate!.day, equals(now.day));
    });
  });
}
