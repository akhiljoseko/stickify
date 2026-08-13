import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderer_registry.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart';
import 'package:stickify/data/models/firestore/template_firestore_model.dart';
import 'package:stickify/data/models/hive/template_hive_model.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/widgets/canvas_element_widget.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NutritionTable Tests', () {
    late MockTemplateRepository mockTemplateRepository;

    setUp(() {
      mockTemplateRepository = MockTemplateRepository();
      PdfElementRendererRegistry.registerDefaults();
    });

    test('NutritionTableElementBlueprint properties and copyWith', () {
      const bp = NutritionTableElementBlueprint(
        id: 'nut-1',
        x: 10,
        y: 15,
        width: 30,
        height: 40,
        rotation: 90,
      );

      expect(bp.id, 'nut-1');
      expect(bp.x, 10);
      expect(bp.y, 15);
      expect(bp.width, 30);
      expect(bp.height, 40);
      expect(bp.rotation, 90);
      expect(bp.colorHex, 0xFF000000);

      final updated = bp.copyWith(
        x: 12,
        y: 18,
        width: 35,
        height: 45,
        rotation: 180,
        colorHex: 0xFFFF0000,
      );

      expect(updated.id, 'nut-1');
      expect(updated.x, 12);
      expect(updated.y, 18);
      expect(updated.width, 35);
      expect(updated.height, 45);
      expect(updated.rotation, 180);
      expect(updated.colorHex, 0xFFFF0000);
    });

    testWidgets('renders Nutrition Facts Table on canvas with default mock values when product is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<EditorCubit>(
              create: (_) => EditorCubit(mockTemplateRepository, 'temp-123'),
              child: Stack(
                children: [
                  CanvasElementWidget(
                    blueprint: const NutritionTableElementBlueprint(
                      id: 'nut-1',
                      x: 10,
                      y: 10,
                      width: 30,
                      height: 40,
                      rotation: 0,
                    ),
                    isSelected: false,
                    onTap: () {},
                    zoomLevel: 1,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify header and elements render
      expect(find.text('Nutrition Facts'), findsOneWidget);
      expect(find.text('Energy/Calories'), findsOneWidget);
      expect(find.text('250 kcal'), findsOneWidget); // Default fallback calories
      expect(find.text('Total Fat'), findsOneWidget);
      expect(find.text('8.0 g'), findsOneWidget); // Default fallback fat
      expect(find.text('Protein'), findsOneWidget);
      expect(find.text('10.0 g'), findsOneWidget); // Default fallback protein
    });

    testWidgets('renders Nutrition Facts Table on canvas with active product data', (tester) async {
      const product = Product(
        id: 'prod-123',
        name: 'Whey Protein',
        sku: 'WHEY-1',
        nutritionFacts: NutritionFacts(
          calories: 140,
          protein: 25.5,
          totalFat: 1.5,
          saturatedFat: 0.5,
          totalCarbs: 3,
          fiber: 1,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider<EditorCubit>(
              create: (_) => EditorCubit(mockTemplateRepository, 'temp-123'),
              child: Stack(
                children: [
                  CanvasElementWidget(
                    blueprint: const NutritionTableElementBlueprint(
                      id: 'nut-1',
                      x: 10,
                      y: 10,
                      width: 30,
                      height: 40,
                      rotation: 0,
                    ),
                    isSelected: false,
                    onTap: () {},
                    zoomLevel: 1,
                    product: product,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify active product values render
      expect(find.text('Nutrition Facts'), findsOneWidget);
      expect(find.text('140 kcal'), findsOneWidget);
      expect(find.text('25.5 g'), findsOneWidget);
      expect(find.text('1.5 g'), findsOneWidget);
      expect(find.text('0.5 g'), findsOneWidget);
      expect(find.text('3.0 g'), findsOneWidget);
      expect(find.text('1.0 g'), findsOneWidget);
    });

    test('Firestore model serialization and deserialization', () {
      const bp = NutritionTableElementBlueprint(
        id: 'nut-1',
        x: 10,
        y: 20,
        width: 30,
        height: 40,
        rotation: 0,
        colorHex: 0xFFFF0000,
      );

      final firestoreModel = ElementBlueprintFirestoreModel.fromDomain(bp);
      expect(firestoreModel.type, 'nutrition_table');
      
      final map = firestoreModel.toMap();
      expect(map['type'], 'nutrition_table');
      expect(map['colorHex'], 0xFFFF0000);

      final fromMapModel = ElementBlueprintFirestoreModel.fromMap(map);
      final domainBp = fromMapModel.toDomain() as NutritionTableElementBlueprint;
      
      expect(domainBp.id, bp.id);
      expect(domainBp.x, bp.x);
      expect(domainBp.y, bp.y);
      expect(domainBp.width, bp.width);
      expect(domainBp.height, bp.height);
      expect(domainBp.colorHex, 0xFFFF0000);
    });

    test('Hive model serialization and deserialization', () {
      const bp = NutritionTableElementBlueprint(
        id: 'nut-1',
        x: 10,
        y: 20,
        width: 30,
        height: 40,
        rotation: 0,
        colorHex: 0xFF2196F3,
      );

      final hiveModel = ElementBlueprintHiveModel.fromDomain(bp);
      expect(hiveModel.type, 'nutrition_table');
      expect(hiveModel.colorHex, 0xFF2196F3);

      final domainBp = hiveModel.toDomain() as NutritionTableElementBlueprint;
      expect(domainBp.id, bp.id);
      expect(domainBp.x, bp.x);
      expect(domainBp.y, bp.y);
      expect(domainBp.width, bp.width);
      expect(domainBp.height, bp.height);
      expect(domainBp.colorHex, 0xFF2196F3);
    });

    test('LabelPdfLayoutEngine compiles PDF with Nutrition Table correctly', () async {
      const engine = LabelPdfLayoutEngine(useIsolate: false);
      const template = LabelTemplate(
        id: 'temp-nut',
        name: 'Nutrition Template',
        sheetConfig: SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 10,
          marginRight: 10,
          columns: 1,
          rows: 1,
          columnGap: 0,
          rowGap: 0,
        ),
        stickerConfig: StickerConfig(
          widthMm: 80,
          heightMm: 80,
          cornerRadiusMm: 0,
          printableArea: [],
        ),
        elements: [
          NutritionTableElementBlueprint(
            id: 'nut-1',
            x: 5,
            y: 5,
            width: 30,
            height: 40,
            rotation: 0,
          ),
        ],
      );

      const product = Product(
        id: 'prod-1',
        name: 'Peanut Butter',
        sku: 'PB-1',
        nutritionFacts: NutritionFacts(
          calories: 190,
          protein: 7,
          totalFat: 16,
          saturatedFat: 3,
          totalCarbs: 6,
          fiber: 2,
        ),
      );

      const variant = ProductVariant(
        name: 'Regular',
        quantity: 1,
        unit: 'jar',
        wholesale: 3,
        mrp: 4.5,
        sku: 'PB-1-REG',
      );

      final pdfBytes = await engine.buildPdfBytes(
        items: [const PrintableItem(product: product, variant: variant, quantity: 1)],
        template: template,
        disabledSlots: {},
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(0));
    });
  });
}
