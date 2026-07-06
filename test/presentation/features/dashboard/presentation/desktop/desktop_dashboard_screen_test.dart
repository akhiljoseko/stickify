import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/frequent_products_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_print_jobs_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_cubit.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';
import 'package:stickify/presentation/features/dashboard/presentation/desktop/desktop_dashboard_screen.dart';
import 'package:stickify/presentation/features/print/widgets/product_variant_selection_dialog.dart';
import 'package:stickify/presentation/navigation/desktop_app_shell.dart';

import '../../../../../helpers/pump_app.dart';

class MockSyncCubit extends MockCubit<SyncState> implements SyncCubit {}
class MockRecentPrintJobsCubit extends MockCubit<RecentPrintJobsState> implements RecentPrintJobsCubit {}
class MockFrequentProductsCubit extends MockCubit<FrequentVariantsState> implements FrequentProductsCubit {}
class MockProductRepository extends Mock implements ProductRepository {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late SyncCubit syncCubit;
  late RecentPrintJobsCubit recentPrintJobsCubit;
  late FrequentProductsCubit frequentProductsCubit;
  late ProductRepository productRepository;
  late GoRouter goRouter;

  setUp(() {
    syncCubit = MockSyncCubit();
    recentPrintJobsCubit = MockRecentPrintJobsCubit();
    frequentProductsCubit = MockFrequentProductsCubit();
    productRepository = MockProductRepository();
    goRouter = MockGoRouter();

    when(() => syncCubit.state).thenReturn(const SyncInitial());
    when(() => recentPrintJobsCubit.state).thenReturn(const RecentPrintJobsLoaded(jobs: []));
    when(() => frequentProductsCubit.state).thenReturn(const FrequentVariantsLoaded(variants: []));
    when(() => productRepository.getAllProducts()).thenAnswer((_) async => const Result.success([]));
  });

  Widget buildTestableWidget({required int selectedIndex}) {
    return RepositoryProvider<ProductRepository>.value(
      value: productRepository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider<SyncCubit>.value(value: syncCubit),
          BlocProvider<RecentPrintJobsCubit>.value(value: recentPrintJobsCubit),
          BlocProvider<FrequentProductsCubit>.value(value: frequentProductsCubit),
        ],
        child: InheritedGoRouter(
          goRouter: goRouter,
          child: DesktopAppShell(
            body: const DesktopDashboardScreen(),
            selectedIndex: selectedIndex,
            onDestinationSelected: (_) {},
          ),
        ),
      ),
    );
  }

  group('DesktopAppShell & Dashboard keyboard shortcuts', () {
    testWidgets('pressing Ctrl + P opens ProductVariantSelectionDialog when on Dashboard tab', (tester) async {
      await tester.pumpApp(buildTestableWidget(selectedIndex: 0));
      await tester.pumpAndSettle();

      // Verify dialog is not open initially
      expect(find.byType(ProductVariantSelectionDialog), findsNothing);

      // Simulate Ctrl + P
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify dialog is now visible
      expect(find.byType(ProductVariantSelectionDialog), findsOneWidget);
    });

    testWidgets('pressing Ctrl + P does NOT open ProductVariantSelectionDialog when on other tabs', (tester) async {
      await tester.pumpApp(buildTestableWidget(selectedIndex: 1));
      await tester.pumpAndSettle();

      // Verify dialog is not open initially
      expect(find.byType(ProductVariantSelectionDialog), findsNothing);

      // Simulate Ctrl + P
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyP);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Verify dialog is still not visible
      expect(find.byType(ProductVariantSelectionDialog), findsNothing);
    });
  });
}
