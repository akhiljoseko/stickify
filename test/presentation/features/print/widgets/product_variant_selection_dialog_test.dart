import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/widgets/product_variant_selection_dialog.dart';

import '../../../../helpers/pump_app.dart';

class MockProductRepository extends Mock implements ProductRepository {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late ProductRepository productRepository;
  late GoRouter goRouter;

  const testProductC = Product(
    id: 'prod-c',
    name: 'C Product',
    sku: 'SKU-C',
    variants: [
      ProductVariant(
        name: 'Pack of 15',
        quantity: 15,
        unit: 'pcs',
        wholesale: 150,
        mrp: 100,
        sku: 'SKU-C-15',
      ),
      ProductVariant(
        name: 'Pack of 5',
        quantity: 5,
        unit: 'pcs',
        wholesale: 50,
        mrp: 300,
        sku: 'SKU-C-5',
      ),
      ProductVariant(
        name: 'Pack of 10',
        quantity: 10,
        unit: 'pcs',
        wholesale: 100,
        mrp: 200,
        sku: 'SKU-C-10',
      ),
    ],
  );

  const testProductA = Product(
    id: 'prod-a',
    name: 'A Product',
    sku: 'SKU-A',
  );

  const testProductB = Product(
    id: 'prod-b',
    name: 'B Product',
    sku: 'SKU-B',
  );

  setUp(() {
    productRepository = MockProductRepository();
    goRouter = MockGoRouter();

    when(() => productRepository.getAllProducts()).thenAnswer(
      (_) async => const Result.success([testProductC, testProductA, testProductB]),
    );
  });

  Widget buildTestableWidget() {
    return RepositoryProvider<ProductRepository>.value(
      value: productRepository,
      child: InheritedGoRouter(
        goRouter: goRouter,
        child: const ProductVariantSelectionDialog(),
      ),
    );
  }

  group('ProductVariantSelectionDialog Widget Tests', () {
    testWidgets('auto-focuses search field on launch', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      final searchTextFieldFinder = find.byType(TextField);
      expect(searchTextFieldFinder, findsOneWidget);

      final searchTextField = tester.widget<TextField>(searchTextFieldFinder);
      expect(searchTextField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('sorts products alphabetically by name', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Products should be sorted A, B, C
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, 3);
      expect((listTiles[0].title! as Text).data, 'A Product');
      expect((listTiles[1].title! as Text).data, 'B Product');
      expect((listTiles[2].title! as Text).data, 'C Product');
    });

    testWidgets('sorts variants by MRP', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Tap on C Product (which is the third in sorted list)
      await tester.tap(find.widgetWithText(ListTile, 'C Product'));
      await tester.pumpAndSettle();

      // Variants should be sorted by MRP: 100, 200, 300 (Pack of 15, Pack of 10, Pack of 5)
      final listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles.length, 3);
      expect((listTiles[0].title! as Text).data, 'Pack of 15');
      expect((listTiles[1].title! as Text).data, 'Pack of 10');
      expect((listTiles[2].title! as Text).data, 'Pack of 5');
    });

    testWidgets('arrow keys change highlight and Enter selects product', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Default highlighted index should be 0 (A Product)
      var listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles[0].selected, isTrue);
      expect(listTiles[1].selected, isFalse);

      // Down arrow -> highlights B Product
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      listTiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(listTiles[0].selected, isFalse);
      expect(listTiles[1].selected, isTrue);

      // Enter key -> selects B Product
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      // B Product has no variants, should show no variants configured screen
      expect(find.text('No variants configured for this product.'), findsOneWidget);
    });

    testWidgets('backspace key goes back to product list from variant selection', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Select C Product
      await tester.tap(find.widgetWithText(ListTile, 'C Product'));
      await tester.pumpAndSettle();

      expect(find.text('Select Variant'), findsOneWidget);

      // Press Backspace
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      // Should be back to product list
      expect(find.text('Select Product'), findsOneWidget);
    });

    testWidgets('Ctrl + S focuses and selects search field text', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Type some text in the search controller
      final searchTextFieldFinder = find.byType(TextField);
      await tester.enterText(searchTextFieldFinder, 'Hello');
      await tester.pumpAndSettle();

      // Trigger Ctrl + S
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Text should be fully selected
      final searchTextField = tester.widget<TextField>(searchTextFieldFinder);
      expect(searchTextField.controller?.selection.baseOffset, 0);
      expect(searchTextField.controller?.selection.extentOffset, 5);
    });

    testWidgets('Ctrl + S in variant state returns to product list and selects search field', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Type search text
      final searchTextFieldFinder = find.byType(TextField);
      await tester.enterText(searchTextFieldFinder, 'C Product');
      await tester.pumpAndSettle();

      // Select C Product
      await tester.tap(find.widgetWithText(ListTile, 'C Product'));
      await tester.pumpAndSettle();
      expect(find.text('Select Variant'), findsOneWidget);

      // Trigger Ctrl + S
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pumpAndSettle();

      // Should be back to product list
      expect(find.text('Select Product'), findsOneWidget);

      // Search text 'C Product' should be fully selected
      final searchTextFieldRebuilt = tester.widget<TextField>(find.byType(TextField));
      expect(searchTextFieldRebuilt.controller?.selection.baseOffset, 0);
      expect(searchTextFieldRebuilt.controller?.selection.extentOffset, 9);
    });

    testWidgets('restores scroll position and highlighted index when returning to product list', (tester) async {
      final largeProductList = List.generate(
        15,
        (index) => Product(
          id: 'prod-$index',
          name: 'Product ${String.fromCharCode(65 + index)}',
          sku: 'SKU-$index',
        ),
      );
      when(() => productRepository.getAllProducts()).thenAnswer(
        (_) async => Result.success(largeProductList),
      );

      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      for (var i = 0; i < 9; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
      }

      final scrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      final initialOffset = scrollable.position.pixels;
      expect(initialOffset, greaterThan(0));

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Select Variant'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();

      final restoredScrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(ListView),
          matching: find.byType(Scrollable),
        ),
      );
      expect(restoredScrollable.position.pixels, equals(initialOffset));

      final listTileFinder = find.ancestor(
        of: find.text('Product J'),
        matching: find.byType(ListTile),
      );
      expect(listTileFinder, findsOneWidget);
      final tile = tester.widget<ListTile>(listTileFinder);
      expect(tile.selected, isTrue);
    });

    testWidgets('search filters products by keyword in print dialog', (tester) async {
      final products = [
        const Product(
          id: 'prod-kw-1',
          name: 'Product Organic',
          sku: 'SKU-1',
          keywords: ['gluten-free'],
        ),
        const Product(
          id: 'prod-kw-2',
          name: 'Product Normal',
          sku: 'SKU-2',
          keywords: ['nut-free'],
        ),
      ];
      when(() => productRepository.getAllProducts()).thenAnswer(
        (_) async => Result.success(products),
      );

      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Enter search text 'gluten-free'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'gluten-free');
      await tester.pumpAndSettle();

      // Verify that Product Organic is shown, but Product Normal is filtered out
      expect(find.text('Product Organic'), findsOneWidget);
      expect(find.text('Product Normal'), findsNothing);
    });
  });
}
