class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.totalCount,
    required this.hasMore,
    required this.currentPage,
  });

  final List<T> items;
  final int totalCount;
  final bool hasMore;
  final int currentPage;
}
