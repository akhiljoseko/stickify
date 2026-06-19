import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/paginated_result.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/domain/services/file_storage_service.dart';
import 'package:stickify/presentation/features/product/presentation/product_management_entry.dart';
import '../../../../helpers/pump_app.dart';

class MockProductRepository extends Mock implements ProductRepository {}
class MockFileStorageService extends Mock implements FileStorageService {}

void main() {
  late ProductRepository productRepository;
  late FileStorageService fileStorageService;
  late List<Product> mockProducts;

  setUpAll(() {
    registerFallbackValue(
      const Product(
        id: 'fallback',
        name: 'Fallback',
        sku: 'SKU-FALLBACK',
      ),
    );
  });

  setUp(() {
    productRepository = MockProductRepository();
    fileStorageService = MockFileStorageService();
    mockProducts = [
      const Product(
        id: 'prod-1',
        name: 'ChronoMaster Elite',
        sku: 'WTCH-293-882-EL',
        category: 'Snacks',
      ),
      const Product(
        id: 'prod-2',
        name: 'OmniAudio Pro-X',
        sku: 'AUD-HX0-912-PR',
        category: 'Pickles',
      ),
    ];

    when(() => productRepository.getProducts(
          page: any(named: 'page'),
          pageSize: any(named: 'pageSize'),
          query: any(named: 'query'),
          category: any(named: 'category'),
        )).thenAnswer((_) async => Result.success(PaginatedResult(
              items: mockProducts,
              totalCount: 2,
              hasMore: false,
              currentPage: 0,
            )));
    when(() => productRepository.saveProduct(any())).thenAnswer(
      (_) async => const Result.success(null),
    );
  });

  Widget buildTestableWidget() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProductRepository>.value(value: productRepository),
        RepositoryProvider<FileStorageService>.value(value: fileStorageService),
      ],
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

    testWidgets('clicking visibility icon opens detail view', (tester) async {
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 800));
      await tester.pumpAndSettle();

      final viewDetailsButton = find.byTooltip('View Details').first;
      expect(viewDetailsButton, findsOneWidget);
      await tester.tap(viewDetailsButton);
      await tester.pumpAndSettle();

      expect(find.text('GLOBAL SKU PREFIX'), findsOneWidget);
      expect(find.text('Packaging Variants'), findsOneWidget);
      expect(find.text('No packaging variants configured.'), findsOneWidget);

      // Verify removed elements
      expect(find.text('VALUE'), findsNothing);
      expect(find.text('Sensitive to high humidity'), findsNothing);
    });

    testWidgets('tapping row opens detail view', (tester) async {
      await tester.pumpApp(buildTestableWidget(), size: const Size(1200, 800));
      await tester.pumpAndSettle();

      final firstRow = find.text('ChronoMaster Elite').first;
      expect(firstRow, findsOneWidget);
      await tester.tap(firstRow);
      await tester.pumpAndSettle();

      expect(find.text('GLOBAL SKU PREFIX'), findsOneWidget);
      expect(find.text('Packaging Variants'), findsOneWidget);
      expect(find.text('No packaging variants configured.'), findsOneWidget);
    });
  });
}
