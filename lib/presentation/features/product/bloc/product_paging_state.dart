import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:stickify/domain/entities/product.dart';

base class ProductPagingState extends PagingStateBase<int, Product> {
  ProductPagingState({
    super.pages,
    super.keys,
    super.error,
    super.hasNextPage = true,
    super.isLoading = false,
    this.searchQuery,
    this.categoryFilter,
  });

  final String? searchQuery;
  final String? categoryFilter;

  List<Product>? get items =>
      pages != null ? List.unmodifiable(pages!.expand((e) => e)) : null;

  @override
  ProductPagingState copyWith({
    Defaulted<List<List<Product>>?>? pages = const Omit(),
    Defaulted<List<int>?>? keys = const Omit(),
    Defaulted<Object?>? error = const Omit(),
    Defaulted<bool>? hasNextPage = const Omit(),
    Defaulted<bool>? isLoading = const Omit(),
    Defaulted<String?>? searchQuery = const Omit(),
    Defaulted<String?>? categoryFilter = const Omit(),
  }) {
    return ProductPagingState(
      pages: pages is Omit ? this.pages : pages as List<List<Product>>?,
      keys: keys is Omit ? this.keys : keys as List<int>?,
      error: error is Omit ? this.error : error as Object?,
      hasNextPage: hasNextPage is Omit ? this.hasNextPage : hasNextPage! as bool,
      isLoading: isLoading is Omit ? this.isLoading : isLoading! as bool,
      searchQuery: searchQuery is Omit ? this.searchQuery : searchQuery as String?,
      categoryFilter: categoryFilter is Omit ? this.categoryFilter : categoryFilter as String?,
    );
  }

  @override
  ProductPagingState reset() => ProductPagingState();
}
