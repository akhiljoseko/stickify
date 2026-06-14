import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/database_search_repository.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/data/services/hive_local_database.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  final dbFactories = <String, Future<LocalDatabase> Function(Directory tempDir)>{
    'HiveLocalDatabase': (tempDir) async {
      final db = HiveLocalDatabase();
      await db.init(tempDir.path);
      return db;
    },
  };

  for (final entry in dbFactories.entries) {
    final dbName = entry.key;
    final dbBuilder = entry.value;

    group('$dbName integration tests', () {
      late Directory tempDir;
      late LocalDatabase database;
      late DatabaseProductRepository productRepository;
      late DatabaseTemplateRepository templateRepository;
      late DatabasePrintJobRepository printJobRepository;
      late DatabaseSearchRepository searchRepository;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('stickify_test_${dbName.toLowerCase()}');
        database = await dbBuilder(tempDir);
        productRepository = DatabaseProductRepository(database: database);
        templateRepository = DatabaseTemplateRepository(database: database);
        printJobRepository = DatabasePrintJobRepository(database: database);
        searchRepository = DatabaseSearchRepository(
          productRepository: productRepository,
          templateRepository: templateRepository,
        );
      });

      tearDown(() async {
        await database.clear();
        if (dbName == 'HiveLocalDatabase') {
          await Hive.close();
        }
        if (tempDir.existsSync()) {
          try {
            await tempDir.delete(recursive: true);
          } on Object catch (_) {
            // Ignore windows file locking issues in tests
          }
        }
      });

      group('DatabaseProductRepository', () {
        test('starts empty', () async {
          final products = (await productRepository.getAllProducts()).getOrThrow();
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

          (await productRepository.saveProduct(newProduct)).getOrThrow();
          var fetched = (await productRepository.getProductById('prod-new-99')).getOrThrow();
          expect(fetched, isNotNull);
          expect(fetched!.name, 'Super Sticker Pack');

          (await productRepository.deleteProduct('prod-new-99')).getOrThrow();
          fetched = (await productRepository.getProductById('prod-new-99')).getOrThrow();
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
          (await productRepository.saveProduct(p1)).getOrThrow();
          (await productRepository.saveProduct(p2)).getOrThrow();
          (await productRepository.saveProduct(p3)).getOrThrow();

          final frequent = (await productRepository.getFrequentProducts(limit: 2)).getOrThrow();
          expect(frequent.length, 2);
          expect(frequent[0].id, 'prod-2');
          expect(frequent[1].id, 'prod-1');
        });
      });

      group('DatabaseTemplateRepository', () {
        test('starts empty', () async {
          final templates = (await templateRepository.fetchTemplates()).getOrThrow();
          expect(templates, isEmpty);
        });

        test('create, update configs, and finalize template', () async {
          final created = (await templateRepository.createTemplate('Custom Shipping Box')).getOrThrow();
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
          (await templateRepository.saveSheetConfig(created.id, sheet)).getOrThrow();

          var updated = (await templateRepository.fetchTemplate(created.id)).getOrThrow();
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
          (await templateRepository.saveElements(created.id, elements)).getOrThrow();
          updated = (await templateRepository.fetchTemplate(created.id)).getOrThrow();
          expect(updated.elements.length, 1);
          expect(updated.elements.first, isA<TextElementBlueprint>());
          expect((updated.elements.first as TextElementBlueprint).content, 'Hello World');

          // Finalize
          (await templateRepository.finalizeTemplate(created.id)).getOrThrow();
          updated = (await templateRepository.fetchTemplate(created.id)).getOrThrow();
          expect(updated.isFinalized, isTrue);
        });
      });

      group('DatabasePrintJobRepository', () {
        test('starts empty', () async {
          final jobs = (await printJobRepository.getRecentJobs()).getOrThrow();
          expect(jobs, isEmpty);
        });

        test('getRecentJobs sorting and getJobsByVariantSku filter', () async {
          const targetSku = 'TEST-SKU-PRINT';
          final newJob = PrintJob(
            id: 'job-test-12',
            productName: 'Dynamic Test Sticker',
            variantId: 'TEST-SKU-PRINT',
            variantName: 'Standard',
            variantSku: targetSku,
            templateId: 'template-test',
            templateName: 'Test Template',
            status: PrintJobStatus.completed,
            printerStation: 'Station #01',
            printedAt: DateTime.now(),
            labelCount: 15,
          );
          (await printJobRepository.savePrintJob(newJob)).getOrThrow();

          final matches = (await printJobRepository.getJobsByVariantSku(targetSku)).getOrThrow();
          expect(matches.length, 1);
          expect(matches.first.id, 'job-test-12');
        });
      });

      group('DatabaseSearchRepository', () {
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
          (await productRepository.saveProduct(p1)).getOrThrow();

          final results = (await searchRepository.search('ChronoMaster')).getOrThrow();
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
          (await productRepository.saveProduct(p1)).getOrThrow();

          (await templateRepository.createTemplate('Search Template')).getOrThrow();

          final productsOnly = (await searchRepository.search('', categories: {'Products'})).getOrThrow();
          final templatesOnly = (await searchRepository.search('', categories: {'Templates'})).getOrThrow();

          expect(productsOnly.every((r) => r.category == 'Products'), isTrue);
          expect(templatesOnly.every((r) => r.category == 'Templates'), isTrue);
          expect(productsOnly.any((r) => r.title == 'Search Product'), isTrue);
          expect(templatesOnly.any((r) => r.title == 'Search Template'), isTrue);
        });
      });
    });
  }
}

extension<T> on Result<T, AppError> {
  T getOrThrow() {
    switch (this) {
      case Success(value: final val):
        return val;
      case Failure(error: final err):
        throw Exception(err.message);
    }
  }
}
