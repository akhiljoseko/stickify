import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/presentation/template_selection_page.dart';

import '../../../../helpers/pump_app.dart';

class MockProductRepository extends Mock implements ProductRepository {}
class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  late ProductRepository productRepository;
  late TemplateRepository templateRepository;

  const testProduct = Product(
    id: 'prod-test',
    name: 'Dynamic Product',
    sku: 'PROD-SKU',
    variants: [
      ProductVariant(
        name: 'Pack of 10',
        quantity: 10,
        unit: 'pcs',
        wholesale: 150,
        mrp: 200,
        sku: 'PROD-VAR-SKU',
      ),
    ],
  );

  const testTemplate = LabelTemplate(
    id: 'temp-test',
    name: 'A4 Shipping Label',
    sheetConfig: SheetConfig(
      pageWidth: 210,
      pageHeight: 297,
      marginTop: 10,
      marginBottom: 10,
      marginLeft: 10,
      marginRight: 10,
      columns: 2,
      rows: 5,
      columnGap: 5,
      rowGap: 5,
    ),
    stickerConfig: StickerConfig(
      widthMm: 90,
      heightMm: 50,
      cornerRadiusMm: 2,
      printableArea: [],
    ),
    isFinalized: true,
  );

  setUp(() {
    productRepository = MockProductRepository();
    templateRepository = MockTemplateRepository();

    when(() => productRepository.getProductById('prod-test'))
        .thenAnswer((_) async => const Result.success(testProduct));
    when(() => templateRepository.fetchTemplates())
        .thenAnswer((_) async => const Result.success([testTemplate]));
  });

  Widget buildTestableWidget() {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: productRepository),
        RepositoryProvider.value(value: templateRepository),
      ],
      child: const TemplateSelectionPage(
        productId: 'prod-test',
        variantSku: 'PROD-VAR-SKU',
      ),
    );
  }

  group('TemplateSelectionPage Widget Tests', () {
    testWidgets('renders AppBar with back button and title', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Select Template'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      expect(find.textContaining('Dynamic Product'), findsOneWidget);
      expect(find.textContaining('Pack of 10'), findsOneWidget);
      expect(find.text('A4 Shipping Label'), findsOneWidget);
    });

    testWidgets('allows selecting a template and shows selected state', (tester) async {
      await tester.pumpApp(buildTestableWidget());
      await tester.pumpAndSettle();

      // Verify the template is displayed and selected by default if it's the only one
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.text('Continue to Print Configuration'), findsOneWidget);
    });
  });
}
