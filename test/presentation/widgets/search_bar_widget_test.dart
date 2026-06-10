import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/data/repositories/mock_search_repository.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/widgets/search_bar_widget.dart';

import '../../helpers/helpers.dart';

void main() {
  group('SearchBarWidget', () {
    testWidgets('renders inline text field on desktop/tablet viewports', (tester) async {
      await tester.pumpApp(
        RepositoryProvider<SearchRepository>.value(
          value: const MockSearchRepository(),
          child: const Scaffold(body: SearchBarWidget()),
        ),
        size: const Size(1000, 800),
      );

      // Verify input text field is drawn directly
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products, SKUs, or templates...'), findsOneWidget); // It's a hint text
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('renders search icon button on mobile viewports', (tester) async {
      await tester.pumpApp(
        RepositoryProvider<SearchRepository>.value(
          value: const MockSearchRepository(),
          child: const Scaffold(body: SearchBarWidget()),
        ),
        size: const Size(400, 800),
      );

      // Verify inline text field is not present
      expect(find.byType(TextField), findsNothing);

      // Verify search icon button is present
      final searchButtonFinder = find.byType(IconButton);
      expect(searchButtonFinder, findsOneWidget);
      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('opens full-screen search overlay on mobile tap', (tester) async {
      await tester.pumpApp(
        RepositoryProvider<SearchRepository>.value(
          value: const MockSearchRepository(),
          child: const Scaffold(body: SearchBarWidget()),
        ),
        size: const Size(400, 800),
      );

      // Tap to open search overlay
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Verify full-screen overlay is opened
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Recent Searches'), findsOneWidget);

      // Tap back button to dismiss
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Verify overlay is closed
      expect(find.text('Recent Searches'), findsNothing);
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('closes mobile search overlay on text submit', (tester) async {
      await tester.pumpApp(
        RepositoryProvider<SearchRepository>.value(
          value: const MockSearchRepository(),
          child: const Scaffold(body: SearchBarWidget()),
        ),
        size: const Size(400, 800),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Submit search query
      await tester.showKeyboard(find.byType(TextField));
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Verify overlay is closed
      expect(find.text('Recent Searches'), findsNothing);
    });
  });
}
