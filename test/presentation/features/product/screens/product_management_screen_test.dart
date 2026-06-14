import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/presentation/product_management_entry.dart';
import '../../../../helpers/pump_app.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late ProductRepository productRepository;
  late List<Product> mockProducts;

  setUpAll(() {
    registerFallbackValue(
      Product(
        id: 'fallback',
        name: 'Fallback',
        sku: 'SKU-FALLBACK',
        totalPrints: 0,
        lastPrintedAt: DateTime(2023, 10, 24),
      ),
    );
  });

  setUp(() {
    productRepository = MockProductRepository();
    mockProducts = [
      Product(
        id: 'prod-1',
        name: 'ChronoMaster Elite',
        sku: 'WTCH-293-882-EL',
        totalPrints: 1240,
        lastPrintedAt: DateTime(2023, 10, 24),
        category: 'Electronics',
      ),
      Product(
        id: 'prod-2',
        name: 'OmniAudio Pro-X',
        sku: 'AUD-HX0-912-PR',
        totalPrints: 892,
        lastPrintedAt: DateTime(2023, 10, 24),
        category: 'Peripherals',
      ),
    ];

    when(() => productRepository.getAllProducts()).thenAnswer(
      (_) async => Result.success(mockProducts),
    );
    when(() => productRepository.saveProduct(any())).thenAnswer(
      (_) async => const Result.success(null),
    );
  });

  Widget buildTestableWidget() {
    return RepositoryProvider<ProductRepository>.value(
      value: productRepository,
      child: const ProductManagementScreen(),
    );
  }

  group('ProductManagementScreen Widget Tests', () {
    testWidgets('renders Product Assets title', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Product Assets'), findsOneWidget);
    });

    testWidgets('renders Desktop high-density table rows when viewport is large', (tester) async {
      // Desktop width (1200)
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 800));
      await tester.pumpAndSettle();

      expect(find.text('ASSET'), findsOneWidget);
      expect(find.text('SKU / ID'), findsOneWidget);
      expect(find.text('ChronoMaster Elite'), findsOneWidget);
      expect(find.text('OmniAudio Pro-X'), findsOneWidget);
    });

    testWidgets('renders Mobile list layout when viewport is compact', (tester) async {
      // Mobile width (400) and large height (1800) to fit sliver elements
      await tester.pumpApp(buildTestableWidget(), size: const Size(400, 1800));
      await tester.pumpAndSettle();

      expect(find.text('ASSET'), findsNothing);
      expect(find.text('ChronoMaster Elite'), findsOneWidget);
      expect(find.text('OmniAudio Pro-X'), findsOneWidget);
    });

    testWidgets('switching to Create view shows empty form without preview card', (tester) async {
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 800));
      await tester.pumpAndSettle();

      // Click Add Product
      final addButton = find.widgetWithText(ElevatedButton, 'Add Product');
      expect(addButton, findsOneWidget);
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Check header and form field presence
      expect(find.text('Add New Product'), findsOneWidget);
      expect(find.byType(TextFormField), findsAtLeast(2)); // Name and SKU prefix
      expect(find.text('LIVE PRINT PREVIEW'), findsNothing);
    });

    testWidgets('clicking View Details navigates to the detailed view page', (tester) async {
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 800));
      await tester.pumpAndSettle();

      final viewDetailsButton = find.text('View Details').first;
      expect(viewDetailsButton, findsOneWidget);
      await tester.tap(viewDetailsButton);
      await tester.pumpAndSettle();

      expect(find.text('GLOBAL SKU PREFIX'), findsOneWidget);
      expect(find.text('Packaging Variants'), findsOneWidget);
    });
  });
}
