import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/paginated_result.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

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
        category: 'Snacks',
      ),
      Product(
        id: 'prod-2',
        name: 'OmniAudio Pro-X',
        sku: 'AUD-HX0-912-PR',
        category: 'Pickles',
      ),
    ];
  });

  group('ProductCubit Tests', () {
    blocTest<ProductCubit, ProductState>(
      'fetchPage emits ProductPageLoading then ProductPageLoaded',
      build: () {
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
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.fetchPage(pageKey: 0, pageSize: 20),
      expect: () => [
        const ProductPageLoading(),
        isA<ProductPageLoaded>()
            .having((s) => s.items.length, 'items length', 2)
            .having((s) => s.hasMore, 'hasMore', false),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'fetchPage emits ProductPageError when repository fails',
      build: () {
        when(() => productRepository.getProducts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              query: any(named: 'query'),
              category: any(named: 'category'),
            )).thenAnswer((_) async => const Result.failure(DatabaseError(
              message: 'Local database is corrupted.',
            )));
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.fetchPage(pageKey: 0, pageSize: 20),
      expect: () => [
        const ProductPageLoading(),
        const ProductPageError('Local database is corrupted.'),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'fetchPage with query filters results',
      build: () {
        when(() => productRepository.getProducts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              query: any(named: 'query'),
              category: any(named: 'category'),
            )).thenAnswer((invocation) async {
          final query = invocation.namedArguments[const Symbol('query')] as String?;
          final filtered = query == null || query.isEmpty
              ? mockProducts
              : mockProducts.where((p) => p.name.contains(query)).toList();
          return Result.success(PaginatedResult(
            items: filtered,
            totalCount: filtered.length,
            hasMore: false,
            currentPage: 0,
          ));
        });
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.fetchPage(pageKey: 0, pageSize: 20, query: 'Chrono'),
      expect: () => [
        const ProductPageLoading(),
        isA<ProductPageLoaded>()
            .having((s) => s.items.length, 'items length', 1)
            .having((s) => s.searchQuery, 'searchQuery', 'Chrono'),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'fetchPage with category filters results',
      build: () {
        when(() => productRepository.getProducts(
              page: any(named: 'page'),
              pageSize: any(named: 'pageSize'),
              query: any(named: 'query'),
              category: any(named: 'category'),
            )).thenAnswer((invocation) async {
          final category = invocation.namedArguments[const Symbol('category')] as String?;
          final filtered = category == null || category.isEmpty
              ? mockProducts
              : mockProducts.where((p) => p.category == category).toList();
          return Result.success(PaginatedResult(
            items: filtered,
            totalCount: filtered.length,
            hasMore: false,
            currentPage: 0,
          ));
        });
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.fetchPage(pageKey: 0, pageSize: 20, category: 'Pickles'),
      expect: () => [
        const ProductPageLoading(),
        isA<ProductPageLoaded>()
            .having((s) => s.items.length, 'items length', 1)
            .having((s) => s.categoryFilter, 'categoryFilter', 'Pickles'),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'setSubView switches subView state correctly',
      build: () {
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
        return ProductCubit(productRepository);
      },
      seed: () => ProductPageLoaded(
        items: mockProducts,
        currentPage: 0,
        hasMore: false,
      ),
      act: (cubit) => cubit.setSubView(const ProductCreateView()),
      expect: () => [
        isA<ProductPageLoaded>()
            .having((s) => s.subView, 'subView', const ProductCreateView()),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'saveProduct emits FormSubmitting, FormSuccess, then reloads',
      build: () {
        when(() => productRepository.saveProduct(any())).thenAnswer((_) async => const Result.success(null));
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
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.saveProduct(mockProducts[0]),
      expect: () => [
        const ProductFormSubmitting(),
        const ProductFormSuccess(),
        const ProductPageLoading(),
        isA<ProductPageLoaded>(),
      ],
      verify: (_) {
        verify(() => productRepository.saveProduct(any())).called(1);
      },
    );

    blocTest<ProductCubit, ProductState>(
      'saveProduct emits FormError when repository fails',
      build: () {
        when(() => productRepository.saveProduct(any())).thenAnswer(
          (_) async => const Result.failure(NetworkError(
            message: 'Network connection lost.',
          )),
        );
        return ProductCubit(productRepository);
      },
      act: (cubit) => cubit.saveProduct(mockProducts[0]),
      expect: () => [
        const ProductFormSubmitting(),
        const ProductFormError('Network connection lost.'),
      ],
    );

    blocTest<ProductCubit, ProductState>(
      'deleteProduct calls repository and removes item from state',
      build: () {
        when(() => productRepository.deleteProduct(any())).thenAnswer((_) async => const Result.success(null));
        return ProductCubit(productRepository);
      },
      seed: () => ProductPageLoaded(
        items: mockProducts,
        currentPage: 0,
        hasMore: false,
      ),
      act: (cubit) => cubit.deleteProduct('prod-1'),
      expect: () => [
        isA<ProductPageLoaded>()
            .having((s) => s.items.length, 'items length', 1)
            .having((s) => s.items[0].id, 'remaining product id', 'prod-2'),
      ],
      verify: (_) {
        verify(() => productRepository.deleteProduct('prod-1')).called(1);
      },
    );
  });
}
