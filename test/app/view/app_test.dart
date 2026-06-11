import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/local_database.dart';
import 'package:stickify/core/services/remote_database_service.dart';
import 'package:stickify/presentation/features/dashboard/presentation/dashboard_entry.dart';
import 'package:stickify/presentation/login/login_screen.dart';

class MockAuthService extends Mock implements AuthService {}
class MockRemoteDatabaseService extends Mock implements RemoteDatabaseService {}
class MockLocalDatabase extends Mock implements LocalDatabase {}

void main() {
  late MockAuthService mockAuth;
  late MockRemoteDatabaseService mockRemoteDb;
  late MockLocalDatabase mockLocalDb;

  setUp(() {
    mockAuth = MockAuthService();
    mockRemoteDb = MockRemoteDatabaseService();
    mockLocalDb = MockLocalDatabase();

    // Stub initial service calls
    when(() => mockLocalDb.init()).thenAnswer((_) async {});
    when(() => mockLocalDb.clear()).thenAnswer((_) async {});
    when(() => mockAuth.authStateChanges).thenAnswer((_) => Stream.value(null));
  });

  group('App', () {
    testWidgets('renders LoginScreen initially, and DashboardPage after signing in', (tester) async {
      await tester.pumpWidget(
        App(
          auth: mockAuth,
          remoteDb: mockRemoteDb,
          localDb: mockLocalDb,
        ),
      );
      
      // Allow router and stream listener to execute
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Setup login success stubs
      when(() => mockAuth.signIn(any(), any())).thenAnswer(
        (_) async => const AppUser(uid: 'user-123', email: 'test@example.com'),
      );
      // When login succeeds, authStateChanges should emit the authenticated user
      when(() => mockAuth.authStateChanges).thenAnswer(
        (_) => Stream.value(const AppUser(uid: 'user-123', email: 'test@example.com')),
      );

      await tester.enterText(find.bySemanticsLabel('Email Address'), 'test@example.com');
      await tester.enterText(find.bySemanticsLabel('Password'), 'password123');
      await tester.tap(find.text('Sign In'));
      
      // Let AuthCubit login run and stream changes propagate
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DashboardPage), findsOneWidget);
    });
  });
}
