import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/presentation/features/dashboard/pages/dashboard_screen.dart';
import 'package:stickify/presentation/login/login_screen.dart';

void main() {
  group('App', () {
    testWidgets('renders LoginScreen initially, and DashboardPage after signing in', (tester) async {
      await tester.pumpWidget(const App());
      expect(find.byType(LoginScreen), findsOneWidget);

      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
