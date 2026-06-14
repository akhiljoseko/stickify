import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/data/models/hive/print_job_hive_model.dart';
import 'package:stickify/data/models/hive/product_hive_model.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';
import 'package:stickify/presentation/features/dashboard/presentation/dashboard_entry.dart';
import 'package:stickify/presentation/login/login_screen.dart';

class MockAuthService extends Mock implements AuthService {}
class MockRemoteDatabaseService extends Mock implements RemoteDatabaseService {}
class MockLocalDatabase extends Mock implements LocalDatabase {}

void main() {
  late MockAuthService mockAuth;
  late MockRemoteDatabaseService mockRemoteDb;
  late MockLocalDatabase mockLocalDb;
  late StreamController<AppUser?> authStateController;

  setUp(() {
    mockAuth = MockAuthService();
    mockRemoteDb = MockRemoteDatabaseService();
    mockLocalDb = MockLocalDatabase();
    authStateController = StreamController<AppUser?>.broadcast();

    // Stub initial service calls
    when(() => mockLocalDb.init()).thenAnswer((_) async {});
    when(() => mockLocalDb.clear()).thenAnswer((_) async {});
    when(() => mockLocalDb.getAll<PrintJobHiveModel>(any())).thenAnswer((_) async => <PrintJobHiveModel>[]);
    when(() => mockLocalDb.getAll<ProductHiveModel>(any())).thenAnswer((_) async => <ProductHiveModel>[]);
    when(() => mockLocalDb.getAll<LabelTemplateHiveModel>(any())).thenAnswer((_) async => <LabelTemplateHiveModel>[]);
    when(() => mockAuth.authStateChanges).thenAnswer((_) => authStateController.stream);
    
    // Seed initial unauthenticated state
    authStateController.add(null);
  });

  tearDown(() {
    authStateController.close();
  });

  group('App', () {
    testWidgets('renders LoginScreen initially, and DashboardPage after signing in', (tester) async {
      final locator = await AppServiceLocator.create(
        localDbOverride: mockLocalDb,
        authServiceOverride: mockAuth,
        remoteDbOverride: mockRemoteDb,
      );
      await tester.pumpWidget(
        App(
          locator: locator,
        ),
      );
      
      // Allow router and stream listener to execute
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);

      // Setup login success stubs
      when(() => mockAuth.signIn(any(), any())).thenAnswer(
        (_) async {
          const user = AppUser(uid: 'user-123', email: 'test@example.com');
          authStateController.add(user);
          return const Result.success(user);
        },
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
