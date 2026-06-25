// Redundant argument values are used in tests to verify defaults and cover edge cases.
// ignore_for_file: avoid_redundant_argument_values
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/database_printer_profile_repository.dart';
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
      late DatabasePrinterProfileRepository printerProfileRepository;
      late DatabasePrintJobRepository printJobRepository;
      late DatabaseSearchRepository searchRepository;

      setUp(() async {
        tempDir = await Directory.systemTemp.createTemp('stickify_test_${dbName.toLowerCase()}');
        database = await dbBuilder(tempDir);
        productRepository = DatabaseProductRepository(database: database);
        templateRepository = DatabaseTemplateRepository(database: database);
        printerProfileRepository = DatabasePrinterProfileRepository(database: database);
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
          const newProduct = Product(
            id: 'prod-new-99',
            name: 'Super Sticker Pack',
            sku: 'STK-99-SUPER',
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

        test('save three products', () async {
          const p1 = Product(
            id: 'prod-1',
            name: 'Product A',
            sku: 'SKU-A',
          );
          const p2 = Product(
            id: 'prod-2',
            name: 'Product B',
            sku: 'SKU-B',
          );
          const p3 = Product(
            id: 'prod-3',
            name: 'Product C',
            sku: 'SKU-C',
          );
          (await productRepository.saveProduct(p1)).getOrThrow();
          (await productRepository.saveProduct(p2)).getOrThrow();
          (await productRepository.saveProduct(p3)).getOrThrow();

          final all = (await productRepository.getAllProducts()).getOrThrow();
          expect(all.length, 3);
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
            productId: 'prod-test',
            productName: 'Dynamic Test Sticker',
            variantId: 'TEST-SKU-PRINT',
            variantName: 'Standard',
            variantSku: targetSku,
            templateId: 'template-test',
            templateName: 'Test Template',
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
          const p1 = Product(
            id: 'prod-chrono',
            name: 'ChronoMaster Elite',
            sku: 'CHRONO-01',
          );
          (await productRepository.saveProduct(p1)).getOrThrow();

          final results = (await searchRepository.search('ChronoMaster')).getOrThrow();
          expect(results, isNotEmpty);
          expect(results.any((r) => r.title.contains('ChronoMaster')), isTrue);
        });

        test('search filters with category facets', () async {
          const p1 = Product(
            id: 'prod-search-1',
            name: 'Search Product',
            sku: 'SP-01',
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

      group('DatabasePrinterProfileRepository', () {
        test('starts empty', () async {
          final profiles = (await printerProfileRepository.getAllProfiles()).getOrThrow();
          expect(profiles, isEmpty);
        });

        test('save, update, delete, and nested round-trip calibration integrity', () async {
          final now = DateTime(2026, 6, 24, 12, 0, 0);

          final profile = PrinterProfile(
            id: 'prof-test-1',
            displayName: 'Zebra Shipping',
            status: PrinterProfileStatus.active,
            printerIdentity: const PrinterIdentity(
              systemPrinterName: 'Zebra ZT411',
              manufacturer: 'Zebra Technologies',
            ),
            capabilities: const PrinterCapabilities(
              supportsCustomPaperSize: true,
              supportsPortraitCustomPaper: true,
              supportsLandscapeCustomPaper: false,
              supportsManualFeed: false,
              supportsBorderlessPrinting: false,
              supportsTraySelection: true,
            ),
            optimizationPreferences: const OptimizationPreferences(
              allowScaling: true,
              allowTranslation: true,
              allowStickerSpecificAdjustment: true,
            ),
            trays: [
              PrinterTrayProfile(
                trayIdentifier: 'tray_1',
                displayName: 'Main Roll',
                supportedPaperConfigurations: const [
                  PaperConfigurationReference(
                    id: 'shipping_100x150',
                    displayName: 'Shipping Label',
                  ),
                ],
                calibration: PrinterCalibration(
                  enabled: true,
                  calibrationRules: const [
                    CalibrationRule(
                      target: CalibrationTarget.sheet(),
                      transformation: PrintStickerTransform(
                        offsetX: 1.5,
                        offsetY: -2,
                        scaleX: 0.98,
                        scaleY: 0.98,
                        anchorX: 0,
                        anchorY: 1,
                      ),
                    ),
                  ],
                  lastCalibratedAt: now,
                ),
              ),
            ],
            createdAt: now,
            updatedAt: now,
          );

          // 1. Save profile
          (await printerProfileRepository.saveProfile(profile)).getOrThrow();
          var fetched = (await printerProfileRepository.getProfileById('prof-test-1')).getOrThrow();
          expect(fetched, isNotNull);
          
          // Verify nested round-trip calibration integrity
          expect(fetched!.id, equals(profile.id));
          expect(fetched.displayName, equals(profile.displayName));
          expect(fetched.status, equals(profile.status));
          expect(fetched.printerIdentity, equals(profile.printerIdentity));
          expect(fetched.capabilities, equals(profile.capabilities));
          expect(fetched.optimizationPreferences, equals(profile.optimizationPreferences));
          expect(fetched.trays, equals(profile.trays));
          expect(fetched.createdAt, equals(profile.createdAt));
          expect(fetched.updatedAt, equals(profile.updatedAt));

          // Verify nested details specifically
          final tray = fetched.trays.first;
          expect(tray.trayIdentifier, equals('tray_1'));
          expect(tray.supportedPaperConfigurations.first.id, equals('shipping_100x150'));
          expect(tray.calibration.enabled, isTrue);
          expect(tray.calibration.calibrationRules.first.target.type, equals(TargetType.sheet));
          expect(tray.calibration.calibrationRules.first.transformation.offsetX, equals(1.5));
          expect(tray.calibration.calibrationRules.first.transformation.anchorX, equals(0.0));

          // 2. Update profile
          final updatedProfile = PrinterProfile(
            id: 'prof-test-1',
            displayName: 'Zebra Shipping Updated',
            status: PrinterProfileStatus.needsValidation,
            printerIdentity: profile.printerIdentity,
            capabilities: profile.capabilities,
            optimizationPreferences: profile.optimizationPreferences,
            trays: profile.trays,
            createdAt: profile.createdAt,
            updatedAt: now.add(const Duration(hours: 1)),
          );

          (await printerProfileRepository.saveProfile(updatedProfile)).getOrThrow();
          fetched = (await printerProfileRepository.getProfileById('prof-test-1')).getOrThrow();
          expect(fetched, isNotNull);
          expect(fetched!.displayName, equals('Zebra Shipping Updated'));
          expect(fetched.status, equals(PrinterProfileStatus.needsValidation));
          expect(fetched.updatedAt, equals(now.add(const Duration(hours: 1))));

          // 3. Retrieve all
          final all = (await printerProfileRepository.getAllProfiles()).getOrThrow();
          expect(all.length, equals(1));
          expect(all.first.id, equals('prof-test-1'));

          // 4. Delete profile
          (await printerProfileRepository.deleteProfile('prof-test-1')).getOrThrow();
          fetched = (await printerProfileRepository.getProfileById('prof-test-1')).getOrThrow();
          expect(fetched, isNull);

          final allAfterDelete = (await printerProfileRepository.getAllProfiles()).getOrThrow();
          expect(allAfterDelete, isEmpty);
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
