import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/presentation/widgets/adaptive_navigation_shell.dart';
import 'package:stickify/presentation/widgets/global_header_bar.dart';

import '../../helpers/helpers.dart';

void main() {
  group('AdaptiveNavigationShell', () {
    Widget buildShell({
      required Widget body,
      required int selectedIndex,
      required ValueChanged<int> onDestinationSelected,
    }) {
      return AdaptiveNavigationShell(
        body: body,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      );
    }

    testWidgets('renders expanded left sidebar and global header on desktop viewports', (tester) async {
      await tester.pumpApp(
        buildShell(
          body: const Center(child: Text('Desktop Content')),
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        size: const Size(1200, 800),
      );
      
      // Allow AnimatedContainer width animation to complete (72px -> 280px)
      await tester.pumpAndSettle();

      // Verify desktop layout features
      expect(find.text('Desktop Content'), findsOneWidget);
      expect(find.byType(GlobalHeaderBar), findsOneWidget);
      expect(find.text('LabelFlow Pro'), findsOneWidget);
      expect(find.text('Warehouse Admin'), findsOneWidget);
      expect(find.text('Start New Print'), findsOneWidget);

      // Verify navigation labels are rendered
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);

      // Verify that bottom navigation bar is NOT rendered
      expect(find.byType(NavigationBar), findsNothing);

      // Verify expanded sidebar width is 280
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is AnimatedContainer && widget.constraints?.maxWidth == 280,
      );
      expect(sidebarFinder, findsOneWidget);
    });

    testWidgets('renders compact left sidebar on tablet viewports', (tester) async {
      await tester.pumpApp(
        buildShell(
          body: const Center(child: Text('Tablet Content')),
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        size: const Size(700, 800),
      );
      
      await tester.pumpAndSettle();

      expect(find.text('Tablet Content'), findsOneWidget);
      expect(find.byType(GlobalHeaderBar), findsOneWidget);

      // Verify branding text and text labels are NOT rendered in compact mode
      expect(find.text('LabelFlow Pro'), findsNothing);
      expect(find.text('Start New Print'), findsNothing);

      // Verify that bottom navigation bar is NOT rendered
      expect(find.byType(NavigationBar), findsNothing);

      // Verify compact sidebar width is 72
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is AnimatedContainer && widget.constraints?.maxWidth == 72,
      );
      expect(sidebarFinder, findsOneWidget);
    });

    testWidgets('renders bottom navigation bar on mobile viewports', (tester) async {
      await tester.pumpApp(
        buildShell(
          body: const Center(child: Text('Mobile Content')),
          selectedIndex: 0,
          onDestinationSelected: (_) {},
        ),
        size: const Size(400, 800),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mobile Content'), findsOneWidget);

      // Verify bottom navigation is active
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);

      // Verify left sidebar is NOT rendered (neither 280 nor 72 size)
      final sidebarFinder = find.byWidgetPredicate(
        (widget) => widget is AnimatedContainer && (widget.constraints?.maxWidth == 280 || widget.constraints?.maxWidth == 72),
      );
      expect(sidebarFinder, findsNothing);
    });

    testWidgets('triggers callback when tab is selected', (tester) async {
      int? tappedIndex;

      await tester.pumpApp(
        buildShell(
          body: const SizedBox(),
          selectedIndex: 0,
          onDestinationSelected: (idx) => tappedIndex = idx,
        ),
        size: const Size(1200, 800),
      );
      
      await tester.pumpAndSettle();

      // Tap the 'Products' sidebar item
      await tester.tap(find.text('Products'));
      await tester.pumpAndSettle();

      expect(tappedIndex, equals(1));
    });
  });
}
