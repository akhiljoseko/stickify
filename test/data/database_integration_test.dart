import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/database_search_repository.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  late Directory tempDir;
  late DocumentDatabase database;
  late DatabaseProductRepository productRepository;
  late DatabaseTemplateRepository templateRepository;
  late DatabasePrintJobRepository printJobRepository;
  late DatabaseSearchRepository searchRepository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stickify_test_db');
    database = DocumentDatabase(customDirectory: tempDir);
    productRepository = DatabaseProductRepository(database: database);
    templateRepository = DatabaseTemplateRepository(database: database);
    printJobRepository = DatabasePrintJobRepository(database: database);
    searchRepository = DatabaseSearchRepository(
      productRepository: productRepository,
      templateRepository: templateRepository,
    );
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('DocumentDatabase tests', () {
    test('save and retrieve data', () async {
      await database.save('users', 'user-1', {'name': 'Akhil', 'role': 'Admin'});
      final data = await database.get('users', 'user-1');
      expect(data, isNotNull);
      expect(data!['name'], 'Akhil');
      expect(data['role'], 'Admin');
    });

    test('get all in collection', () async {
      await database.save('items', 'i1', {'val': 10});
      await database.save('items', 'i2', {'val': 20});
      final list = await database.getAll('items');
      expect(list.length, 2);
      final vals = list.map((e) => e['val']).toList();
      expect(vals, containsAll([10, 20]));
    });

    test('delete document', () async {
      await database.save('items', 'i1', {'val': 10});
      await database.delete('items', 'i1');
      final data = await database.get('items', 'i1');
      expect(data, isNull);
    });

    test('clear database', () async {
      await database.save('items', 'i1', {'val': 10});
      await database.clear();
      final list = await database.getAll('items');
      expect(list, isEmpty);
    });
  });

  group('DatabaseProductRepository tests', () {
    test('starts empty', () async {
      final products = await productRepository.getAllProducts();
      expect(products, isEmpty);
    });

    test('save and delete product', () async {
      final newProduct = Product(
        id: 'prod-new-99',
        name: 'Super Sticker Pack',
        sku: 'STK-99-SUPER',
        totalPrints: 5,
        lastPrintedAt: DateTime.now(),
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
        category: 'Dry Goods',
      );

      await productRepository.saveProduct(newProduct);
      var fetched = await productRepository.getProductById('prod-new-99');
      expect(fetched, isNotNull);
      expect(fetched!.name, 'Super Sticker Pack');

      await productRepository.deleteProduct('prod-new-99');
      fetched = await productRepository.getProductById('prod-new-99');
      expect(fetched, isNull);
    });

    test('getFrequentProducts sorting limit works', () async {
      final p1 = Product(
        id: 'prod-1',
        name: 'Product A',
        sku: 'SKU-A',
        totalPrints: 10,
        lastPrintedAt: DateTime.now(),
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
      );
      final p2 = Product(
        id: 'prod-2',
        name: 'Product B',
        sku: 'SKU-B',
        totalPrints: 20,
        lastPrintedAt: DateTime.now(),
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
      );
      final p3 = Product(
        id: 'prod-3',
        name: 'Product C',
        sku: 'SKU-C',
        totalPrints: 5,
        lastPrintedAt: DateTime.now(),
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
      );
      await productRepository.saveProduct(p1);
      await productRepository.saveProduct(p2);
      await productRepository.saveProduct(p3);

      final frequent = await productRepository.getFrequentProducts(limit: 2);
      expect(frequent.length, 2);
      expect(frequent[0].id, 'prod-2');
      expect(frequent[1].id, 'prod-1');
    });
  });

  group('DatabaseTemplateRepository tests', () {
    test('starts empty', () async {
      final templates = await templateRepository.fetchTemplates();
      expect(templates, isEmpty);
    });

    test('create, update configs, and finalize template', () async {
      final created = await templateRepository.createTemplate('Custom Shipping Box');
      expect(created.name, 'Custom Shipping Box');
      expect(created.id, startsWith('temp-'));

      // Save configs
      const sheet = SheetConfig(
        pageWidth: 200,
        pageHeight: 200,
        marginTop: 10,
        marginBottom: 10,
        marginLeft: 10,
        marginRight: 10,
        columns: 1,
        rows: 1,
        columnGap: 0,
        rowGap: 0,
      );
      await templateRepository.saveSheetConfig(created.id, sheet);

      var updated = await templateRepository.fetchTemplate(created.id);
      expect(updated.sheetConfig!.pageWidth, 200);

      // Save elements
      final elements = [
        const TextElementBlueprint(
          id: 'text-1',
          x: 10,
          y: 20,
          width: 100,
          height: 30,
          rotation: 0,
          content: 'Hello World',
          isDynamic: false,
          fontSize: 16,
          fontWeightValue: 400,
          textAlign: BlueprintTextAlign.left,
          colorHex: 0xFF000000,
        ),
      ];
      await templateRepository.saveElements(created.id, elements);
      updated = await templateRepository.fetchTemplate(created.id);
      expect(updated.elements.length, 1);
      expect(updated.elements.first, isA<TextElementBlueprint>());
      expect((updated.elements.first as TextElementBlueprint).content, 'Hello World');

      // Finalize
      await templateRepository.finalizeTemplate(created.id);
      updated = await templateRepository.fetchTemplate(created.id);
      expect(updated.isFinalized, isTrue);
    });
  });

  group('DatabasePrintJobRepository tests', () {
    test('starts empty', () async {
      final jobs = await printJobRepository.getRecentJobs();
      expect(jobs, isEmpty);
    });

    test('getRecentJobs sorting and getJobsBySku filter', () async {
      const targetSku = 'TEST-SKU-PRINT';
      final newJob = PrintJob(
        id: 'job-test-12',
        productName: 'Dynamic Test Sticker',
        sku: targetSku,
        status: PrintJobStatus.completed,
        printerStation: 'Station #01',
        printedAt: DateTime.now(),
        labelCount: 15,
      );
      await printJobRepository.savePrintJob(newJob);

      final matches = await printJobRepository.getJobsBySku(targetSku);
      expect(matches.length, 1);
      expect(matches.first.id, 'job-test-12');
    });
  });

  group('DatabaseSearchRepository tests', () {
    test('search items dynamically matches text', () async {
      final p1 = Product(
        id: 'prod-chrono',
        name: 'ChronoMaster Elite',
        sku: 'CHRONO-01',
        totalPrints: 0,
        lastPrintedAt: DateTime.now(),
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
      );
      await productRepository.saveProduct(p1);

      final results = await searchRepository.search('ChronoMaster');
      expect(results, isNotEmpty);
      expect(results.any((r) => r.title.contains('ChronoMaster')), isTrue);
    });

    test('search filters with category facets', () async {
      final p1 = Product(
        id: 'prod-search-1',
        name: 'Search Product',
        sku: 'SP-01',
        totalPrints: 0,
        lastPrintedAt: DateTime.now(),
        assignedStation: 'Station #01',
        stationStatus: StationStatus.online,
      );
      await productRepository.saveProduct(p1);

      await templateRepository.createTemplate('Search Template');

      final productsOnly = await searchRepository.search('', categories: {'Products'});
      final templatesOnly = await searchRepository.search('', categories: {'Templates'});

      expect(productsOnly.every((r) => r.category == 'Products'), isTrue);
      expect(templatesOnly.every((r) => r.category == 'Templates'), isTrue);
      expect(productsOnly.any((r) => r.title == 'Search Product'), isTrue);
      expect(templatesOnly.any((r) => r.title == 'Search Template'), isTrue);
    });
  });
}
