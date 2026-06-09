import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/pages/search_screen.dart';

import '../../../../helpers/helpers.dart';

class TestSearchRepository implements SearchRepository {
  TestSearchRepository({required this.results});

  final List<SearchItem> results;

  @override
  Future<List<SearchItem>> search(
    String query, {
    Set<String>? categories,
    Set<String>? tags,
    bool sortByRelevance = true,
  }) async {
    return results;
  }
}

void main() {
  group('SearchScreen Widget Tests', () {
    late List<SearchItem> mockItems;
    late TestSearchRepository testRepo;

    setUp(() {
      mockItems = [
        const SearchItem(
          id: 'alm-1',
          title: 'Artisanal Toasted Almonds - 150g Pouch',
          sku: 'ALM-TS-150P',
          category: 'Products',
          description: 'Premium toasted almonds package labels.',
          imageUrl: 'https://example.com/image.jpg',
          relevanceScore: 0.98,
          tags: ['organic', 'toasted'],
        ),
        const SearchItem(
          id: 'alm-3',
          title: 'Smoked Honey Almonds - 250g Pouch',
          sku: 'ALM-SH-250P',
          category: 'Products',
          description: 'Honey glazed smoked almonds.',
          imageUrl: 'https://example.com/image.jpg',
          relevanceScore: 0.85,
          tags: ['smoked', 'honey'],
        ),
        const SearchItem(
          id: 'alm-4',
          title: 'Bulk Raw Almonds - 5kg Sack',
          sku: 'ALM-RW-5KG',
          category: 'Products',
          description: 'Raw whole almonds bulk.',
          imageUrl: 'https://example.com/image.jpg',
          relevanceScore: 0.78,
          tags: ['raw', 'bulk'],
        ),
      ];
      testRepo = TestSearchRepository(results: mockItems);
    });

    testWidgets('renders industrial precision data table on desktop viewport', (tester) async {
      await tester.pumpApp(
        SearchPage(
          initialQuery: 'Almonds',
          searchRepository: testRepo,
        ),
        size: const Size(1200, 800),
      );

      // Let the post-frame callback run and mock delay settle
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the results layout renders the table
      expect(find.byType(Table), findsOneWidget);
      expect(find.text('Product Variant'), findsOneWidget);
      expect(find.text('SKU'), findsOneWidget);
      expect(find.text('Actions'), findsOneWidget);

      // Verify item rows
      expect(find.text('Artisanal Toasted Almonds - 150g Pouch'), findsOneWidget);
      expect(find.text('ALM-TS-150P'), findsOneWidget);
      expect(find.text('ALM-SH-250P'), findsOneWidget);

      // Verify buttons
      expect(find.text('Print Label'), findsNWidgets(2)); // One active, one disabled
      expect(find.text('Queue New'), findsOneWidget);
    });

    testWidgets('active Print Label button triggers SnackBar confirmation', (tester) async {
      await tester.pumpApp(
        SearchPage(
          initialQuery: 'Almonds',
          searchRepository: testRepo,
        ),
        size: const Size(1200, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap first Print Label button (active one)
      final printButton = find.text('Print Label').first;
      await tester.tap(printButton);
      await tester.pumpAndSettle();

      // Verify SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Print job sent: 15 labels queued'), findsOneWidget);
    });

    testWidgets('Queue New button triggers SnackBar confirmation', (tester) async {
      await tester.pumpApp(
        SearchPage(
          initialQuery: 'Almonds',
          searchRepository: testRepo,
        ),
        size: const Size(1200, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap Queue New button
      final queueButton = find.text('Queue New');
      await tester.tap(queueButton);
      await tester.pumpAndSettle();

      // Verify SnackBar is shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Queued new print job'), findsOneWidget);
    });

    testWidgets('renders cards list with action buttons on mobile viewport', (tester) async {
      await tester.pumpApp(
        SearchPage(
          initialQuery: 'Almonds',
          searchRepository: testRepo,
        ),
        size: const Size(400, 800),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Table is NOT rendered on mobile
      expect(find.byType(Table), findsNothing);

      // Verify list cards and buttons are present
      expect(find.text('Artisanal Toasted Almonds - 150g Pouch'), findsOneWidget);
      expect(find.text('Print Label'), findsNWidgets(2)); // One active, one disabled card buttons
      expect(find.text('Queue New'), findsOneWidget);
    });
  });
}
