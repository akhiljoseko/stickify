import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/search/cubits/search_cubit.dart';
import 'package:stickify/presentation/features/search/cubits/search_state.dart';

class MockSearchRepo implements SearchRepository {
  MockSearchRepo({required this.mockResults});

  final List<SearchItem> mockResults;
  String? lastQuery;
  Set<String>? lastCategories;
  Set<String>? lastTags;
  bool? lastSortByRelevance;

  @override
  Future<List<SearchItem>> search(
    String query, {
    Set<String>? categories,
    Set<String>? tags,
    bool sortByRelevance = true,
  }) async {
    lastQuery = query;
    lastCategories = categories;
    lastTags = tags;
    lastSortByRelevance = sortByRelevance;
    return mockResults;
  }
}

void main() {
  group('SearchCubit', () {
    late MockSearchRepo mockRepo;
    late SearchItem testItem;

    setUp(() {
      testItem = const SearchItem(
        id: '1',
        title: 'Almonds',
        sku: 'ALM-01',
        category: 'Products',
        description: 'Test almonds',
        imageUrl: '',
        relevanceScore: 0.95,
        tags: ['test'],
      );
      mockRepo = MockSearchRepo(mockResults: [testItem]);
    });

    test('initial state is SearchInitial', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      expect(cubit.state, isA<SearchInitial>());
      await cubit.close();
    });

    test('executeSearch with empty query emits SearchInitial', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      await cubit.executeSearch('');
      expect(cubit.state, isA<SearchInitial>());
      await cubit.close();
    });

    test('executeSearch emits SearchLoading then SearchSuccess on success', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      final states = <SearchState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.executeSearch('Almonds');
      await pumpEventQueue();

      expect(states, [
        const SearchLoading(),
        SearchSuccess(
          query: 'Almonds',
          results: [testItem],
          selectedCategories: const {},
          selectedTags: const {},
          sortByRelevance: true,
        ),
      ]);

      expect(mockRepo.lastQuery, 'Almonds');
      await subscription.cancel();
      await cubit.close();
    });

    test('executeSearch emits SearchLoading then SearchEmpty when no results found', () async {
      final emptyRepo = MockSearchRepo(mockResults: []);
      final cubit = SearchCubit(searchRepository: emptyRepo);
      final states = <SearchState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.executeSearch('NotMatching');
      await pumpEventQueue();

      expect(states, [
        const SearchLoading(),
        const SearchEmpty(query: 'NotMatching'),
      ]);

      await subscription.cancel();
      await cubit.close();
    });

    test('toggleCategory triggers search with updated categories', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      
      // Set to success state first
      await cubit.executeSearch('Almonds');

      // Toggle category
      await cubit.toggleCategory('Products');

      expect(mockRepo.lastCategories, {'Products'});
      await cubit.close();
    });

    test('toggleTag triggers search with updated tags', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      
      await cubit.executeSearch('Almonds');
      await cubit.toggleTag('organic');

      expect(mockRepo.lastTags, {'organic'});
      await cubit.close();
    });

    test('toggleSortOrder toggles sortByRelevance sorting', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      
      await cubit.executeSearch('Almonds');
      await cubit.toggleSortOrder();

      expect(mockRepo.lastSortByRelevance, false);
      await cubit.close();
    });

    test('clearAllFilters resets all filters', () async {
      final cubit = SearchCubit(searchRepository: mockRepo);
      
      await cubit.executeSearch('Almonds');
      await cubit.toggleCategory('Products');
      await cubit.toggleTag('organic');
      await cubit.clearAllFilters();

      expect(mockRepo.lastCategories, isEmpty);
      expect(mockRepo.lastTags, isEmpty);
      expect(mockRepo.lastSortByRelevance, true);
      await cubit.close();
    });
  });
}
