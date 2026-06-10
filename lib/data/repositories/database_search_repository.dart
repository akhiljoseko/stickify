import 'package:stickify/domain/entities/search_item.dart';
import 'package:stickify/domain/repositories/product_repository.dart';
import 'package:stickify/domain/repositories/template_repository.dart';
import 'package:stickify/domain/repositories/search_repository.dart';

class DatabaseSearchRepository implements SearchRepository {
  DatabaseSearchRepository({
    required ProductRepository productRepository,
    required TemplateRepository templateRepository,
  })  : _productRepo = productRepository,
        _templateRepo = templateRepository;

  final ProductRepository _productRepo;
  final TemplateRepository _templateRepo;

  @override
  Future<List<SearchItem>> search(
    String query, {
    Set<String>? categories,
    Set<String>? tags,
    bool sortByRelevance = true,
  }) async {
    // 1. Fetch dynamic products from repository
    final products = await _productRepo.getAllProducts();
    final productSearchItems = products.map((p) {
      final productTags = [
        'organic',
        if (p.category != null) p.category!.toLowerCase(),
        ...p.ingredients.map((i) => i.name.toLowerCase()),
        ...p.variants.map((v) => v.name.toLowerCase()),
        'product',
      ];
      return SearchItem(
        id: p.id,
        title: p.name,
        sku: p.sku,
        category: 'Products',
        description: p.storageConditions ?? 'Product label assets.',
        imageUrl: p.imageUrl ?? '',
        relevanceScore: 0.95,
        tags: productTags,
      );
    }).toList();

    // 2. Fetch dynamic templates from repository
    final templates = await _templateRepo.fetchTemplates();
    final templateSearchItems = templates.map((t) {
      final templateTags = [
        'template',
        'standard',
        if (t.sheetConfig != null) 'sheet',
        if (t.stickerConfig != null) 'sticker',
        ...t.elements.map((e) => e.id.toLowerCase()),
      ];
      return SearchItem(
        id: t.id,
        title: t.name,
        sku: t.id,
        category: 'Templates',
        description: t.isFinalized ? 'Finalized print layout.' : 'Draft layout.',
        imageUrl: '',
        relevanceScore: 0.90,
        tags: templateTags,
      );
    }).toList();

    // 3. Static stations search items (as in Stitch design)
    final stationSearchItems = [
      const SearchItem(
        id: 'stn-1',
        title: 'Printer Station #01',
        sku: 'PRN-STN-01',
        category: 'Stations',
        description: 'High-speed industrial thermal printer node in Packing Zone A.',
        imageUrl: '',
        relevanceScore: 0.78,
        tags: ['printer', 'hardware', 'station-1', 'barcode'],
      ),
      const SearchItem(
        id: 'stn-2',
        title: 'Printer Station #02',
        sku: 'PRN-STN-02',
        category: 'Stations',
        description: 'Backup thermal printer node in Loading Dock B.',
        imageUrl: '',
        relevanceScore: 0.75,
        tags: ['printer', 'hardware', 'station-2', 'barcode'],
      ),
    ];

    // Combine all sources
    final allItems = [
      ...productSearchItems,
      ...templateSearchItems,
      ...stationSearchItems,
    ];

    final cleanQuery = query.trim().toLowerCase();

    // Filter by text query
    var filtered = allItems.where((item) {
      final matchesTitle = item.title.toLowerCase().contains(cleanQuery);
      final matchesSku = (item.sku ?? '').toLowerCase().contains(cleanQuery);
      final matchesDescription = item.description.toLowerCase().contains(cleanQuery);
      final matchesTags = item.tags.any((t) => t.toLowerCase().contains(cleanQuery));
      return matchesTitle || matchesSku || matchesDescription || matchesTags;
    }).toList();

    // Filter by category facets
    if (categories != null && categories.isNotEmpty) {
      filtered = filtered.where((item) => categories.contains(item.category)).toList();
    }

    // Filter by tag facets
    if (tags != null && tags.isNotEmpty) {
      filtered = filtered.where((item) => item.tags.any((t) => tags.contains(t))).toList();
    }

    // Sort items
    if (sortByRelevance) {
      filtered.sort((a, b) => b.relevanceScore.compareTo(a.relevanceScore));
    } else {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }

    return filtered;
  }
}
