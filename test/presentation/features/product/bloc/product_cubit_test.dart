import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';

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
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
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
        assignedStation: 'Station #02',
        stationStatus: StationStatus.online,
        category: 'Electronics',
      ),
      Product(
        id: 'prod-2',
        name: 'OmniAudio Pro-X',
        sku: 'AUD-HX0-912-PR',
        totalPrints: 892,
        lastPrintedAt: DateTime(2023, 10, 24),
        assignedStation: 'Station #05',
        stationStatus: StationStatus.online,
        category: 'Peripherals',
      ),
    ];
  });

  group('ProductCubit Tests', () {
    blocTest<ProductCubit, ProductState>(
      'loadProducts emits Loading then Success with all products',
      build: () {
        when(() => productRepository.getAllProducts()).thenAnswer(
          (_) async => mockProducts,
        );
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.loadProducts(),
      expect: () => [
        const ProductCatalogLoading(),
        isA<ProductCatalogSuccess>()
            .having((s) => s.products.length, 'products length', 2)
            .having((s) => s.filteredProducts.length, 'filteredProducts length', 2),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'applyFilter filters by query matching name or SKU',
      build: () {
        return ProductCubit(productRepository);
      },
      seed: () => ProductCatalogSuccess(
        products: mockProducts,
        filteredProducts: mockProducts,
      ),
      act: (cubit) => cubit.applyFilter(query: 'Chrono'),
      expect: () => [
        isA<ProductCatalogSuccess>()
            .having((s) => s.searchQuery, 'searchQuery', 'Chrono')
            .having((s) => s.filteredProducts.length, 'filteredProducts length', 1)
            .having((s) => s.filteredProducts[0].id, 'filtered product id', 'prod-1'),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'applyFilter filters by category',
      build: () {
        return ProductCubit(productRepository);
      },
      seed: () => ProductCatalogSuccess(
        products: mockProducts,
        filteredProducts: mockProducts,
      ),
      act: (cubit) => cubit.applyFilter(category: 'Peripherals'),
      expect: () => [
        isA<ProductCatalogSuccess>()
            .having((s) => s.categoryFilter, 'categoryFilter', 'Peripherals')
            .having((s) => s.filteredProducts.length, 'filteredProducts length', 1)
            .having((s) => s.filteredProducts[0].id, 'filtered product id', 'prod-2'),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'setSubView switches subView state correctly',
      build: () {
        return ProductCubit(productRepository);
      },
      seed: () => ProductCatalogSuccess(
        products: mockProducts,
        filteredProducts: mockProducts,
      ),
      act: (cubit) => cubit.setSubView('create'),
      expect: () => [
        isA<ProductCatalogSuccess>()
            .having((s) => s.subView, 'subView', 'create')
            .having((s) => s.selectedProduct, 'selectedProduct', null),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'saveProduct calls repository and loads products again',
      build: () {
        when(() => productRepository.saveProduct(any())).thenAnswer((_) async => {});
        when(() => productRepository.getAllProducts()).thenAnswer((_) async => mockProducts);
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.saveProduct(mockProducts[0]),
      expect: () => [
        const ProductFormSubmitting(),
        const ProductFormSuccess(),
        const ProductCatalogLoading(),
        isA<ProductCatalogSuccess>(),
      ],
      verify: (_) {
        verify(() => productRepository.saveProduct(any())).called(1);
      },
    );

    blocTest<ProductCubit, ProductState>(
      'deleteProduct calls repository and filters item out',
      build: () {
        when(() => productRepository.deleteProduct(any())).thenAnswer((_) async => {});
        return ProductCubit(productRepository);
      },
      seed: () => ProductCatalogSuccess(
        products: mockProducts,
        filteredProducts: mockProducts,
      ),
      act: (cubit) => cubit.deleteProduct('prod-1'),
      expect: () => [
        isA<ProductCatalogSuccess>()
            .having((s) => s.products.length, 'products length', 1)
            .having((s) => s.filteredProducts.length, 'filteredProducts length', 1)
            .having((s) => s.products[0].id, 'remaining product id', 'prod-2'),
      ],
      verify: (_) {
        verify(() => productRepository.deleteProduct('prod-1')).called(1);
      },
    );
  });
}
