// Ignore for testing purposes
// ignore_for_file: prefer_const_constructors

import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/presentation/dashboard/dashboard_page.dart';

void main() {
  group('App', () {
    testWidgets('renders CounterPage', (tester) async {
      await tester.pumpWidget(App());
      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
