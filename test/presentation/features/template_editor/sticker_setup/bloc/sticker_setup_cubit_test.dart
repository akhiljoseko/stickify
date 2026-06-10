import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_cubit.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_state.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  late TemplateRepository templateRepository;
  const templateId = 'temp-123';
  late StickerConfig defaultStickerConfig;
  late LabelTemplate mockTemplate;

  setUpAll(() {
    registerFallbackValue(
      const StickerConfig(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        printableArea: [],
      ),
    );
  });

  setUp(() {
    templateRepository = MockTemplateRepository();
    defaultStickerConfig = const StickerConfig(
      widthMm: 100,
      heightMm: 60,
      cornerRadiusMm: 4,
      printableArea: [
        StickerPoint(4, 4),
        StickerPoint(96, 4),
        StickerPoint(96, 56),
        StickerPoint(4, 56),
      ],
    );
    mockTemplate = LabelTemplate(
      id: templateId,
      name: 'Test Template',
      stickerConfig: defaultStickerConfig,
    );
  });

  group('StickerSetupCubit Tests', () {
    blocTest<StickerSetupCubit, StickerSetupState>(
      'loads sticker config from template successfully',
      build: () {
        when(() => templateRepository.fetchTemplate(templateId))
            .thenAnswer((_) async => mockTemplate);
        return StickerSetupCubit(templateRepository, templateId);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const StickerSetupLoading(),
        isA<StickerSetupEditing>()
            .having((s) => s.widthMm, 'widthMm', 100)
            .having((s) => s.heightMm, 'heightMm', 60)
            .having((s) => s.isCustomPolygon, 'isCustomPolygon', false)
            .having((s) => s.polygonPoints.length, 'polygonPoints.length', 4)
            .having((s) => s.polygonPointIds.length, 'polygonPointIds.length', 4),
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'updateFields modifies basic fields',
      build: () {
        when(() => templateRepository.fetchTemplate(templateId))
            .thenAnswer((_) async => mockTemplate);
        return StickerSetupCubit(templateRepository, templateId);
      },
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        polygonPoints: [
          StickerPoint(4, 4),
          StickerPoint(96, 4),
          StickerPoint(96, 56),
          StickerPoint(4, 56),
        ],
        polygonPointIds: ['p1', 'p2', 'p3', 'p4'],
      ),
      act: (cubit) => cubit.updateFields(widthMm: 120, heightMm: 80),
      expect: () => [
        isA<StickerSetupEditing>()
            .having((s) => s.widthMm, 'widthMm', 120)
            .having((s) => s.heightMm, 'heightMm', 80)
            .having((s) => s.polygonPoints[2].x, 'bottom right x', 116) // 120 - 4 padding
            .having((s) => s.polygonPoints[2].y, 'bottom right y', 76), // 80 - 4 padding
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'toggleCustomPolygon enables polygon mode and generates point IDs',
      build: () => StickerSetupCubit(templateRepository, templateId),
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        polygonPoints: [
          StickerPoint(4, 4),
          StickerPoint(96, 4),
          StickerPoint(96, 56),
          StickerPoint(4, 56),
        ],
        polygonPointIds: ['p1', 'p2', 'p3', 'p4'],
      ),
      act: (cubit) => cubit.toggleCustomPolygon(enabled: true),
      expect: () => [
        isA<StickerSetupEditing>()
            .having((s) => s.isCustomPolygon, 'isCustomPolygon', true)
            .having((s) => s.polygonPointIds.length, 'polygonPointIds length', 4)
            .having((s) => s.polygonPointIds[0].startsWith('point_'), 'generates new IDs', true),
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'updatePolygonPoint modifies coordinate at target index while keeping IDs stable',
      build: () => StickerSetupCubit(templateRepository, templateId),
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        isCustomPolygon: true,
        polygonPoints: [
          StickerPoint(4, 4),
          StickerPoint(96, 4),
          StickerPoint(96, 56),
          StickerPoint(4, 56),
        ],
        polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4'],
      ),
      act: (cubit) => cubit.updatePolygonPoint(1, 98, 5),
      expect: () => [
        const StickerSetupEditing(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          paddingTop: 4,
          paddingBottom: 4,
          paddingLeft: 4,
          paddingRight: 4,
          isCustomPolygon: true,
          polygonPoints: [
            StickerPoint(4, 4),
            StickerPoint(98, 5),
            StickerPoint(96, 56),
            StickerPoint(4, 56),
          ],
          polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4'],
        ),
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'addPolygonPoint appends point and a unique ID',
      build: () => StickerSetupCubit(templateRepository, templateId),
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        isCustomPolygon: true,
        polygonPoints: [
          StickerPoint(4, 4),
          StickerPoint(96, 4),
          StickerPoint(96, 56),
          StickerPoint(4, 56),
        ],
        polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4'],
      ),
      act: (cubit) => cubit.addPolygonPoint(),
      expect: () => [
        isA<StickerSetupEditing>()
            .having((s) => s.polygonPoints.length, 'points length', 5)
            .having((s) => s.polygonPointIds.length, 'IDs length', 5)
            .having((s) => s.polygonPoints[4].x, 'added x', 14.0) // 4 + 10 clamped
            .having((s) => s.polygonPointIds[4].startsWith('point_add_'), 'new ID prefix', true),
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'removePolygonPoint removes point and ID at target index',
      build: () => StickerSetupCubit(templateRepository, templateId),
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        isCustomPolygon: true,
        polygonPoints: [
          StickerPoint(4, 4),
          StickerPoint(96, 4),
          StickerPoint(96, 56),
          StickerPoint(4, 56),
          StickerPoint(50, 30),
        ],
        polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4', 'id-5'],
      ),
      act: (cubit) => cubit.removePolygonPoint(4),
      expect: () => [
        const StickerSetupEditing(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          paddingTop: 4,
          paddingBottom: 4,
          paddingLeft: 4,
          paddingRight: 4,
          isCustomPolygon: true,
          polygonPoints: [
            StickerPoint(4, 4),
            StickerPoint(96, 4),
            StickerPoint(96, 56),
            StickerPoint(4, 56),
          ],
          polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4'],
        ),
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'reorderPolygonPoints swaps points and their corresponding stable IDs correctly',
      build: () => StickerSetupCubit(templateRepository, templateId),
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        isCustomPolygon: true,
        polygonPoints: [
          StickerPoint(10, 10),
          StickerPoint(20, 20),
          StickerPoint(30, 30),
          StickerPoint(40, 40),
        ],
        polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4'],
      ),
      act: (cubit) => cubit.reorderPolygonPoints(0, 3), // Moves index 0 to index 2
      expect: () => [
        const StickerSetupEditing(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          paddingTop: 4,
          paddingBottom: 4,
          paddingLeft: 4,
          paddingRight: 4,
          isCustomPolygon: true,
          polygonPoints: [
            StickerPoint(20, 20),
            StickerPoint(30, 30),
            StickerPoint(10, 10),
            StickerPoint(40, 40),
          ],
          polygonPointIds: ['id-2', 'id-3', 'id-1', 'id-4'],
        ),
      ],
    );

    blocTest<StickerSetupCubit, StickerSetupState>(
      'saveAndContinue invokes repo save and emits saved state',
      build: () {
        when(() => templateRepository.saveStickerConfig(any(), any()))
            .thenAnswer((_) async => {});
        return StickerSetupCubit(templateRepository, templateId);
      },
      seed: () => const StickerSetupEditing(
        widthMm: 100,
        heightMm: 60,
        cornerRadiusMm: 4,
        paddingTop: 4,
        paddingBottom: 4,
        paddingLeft: 4,
        paddingRight: 4,
        polygonPoints: [
          StickerPoint(4, 4),
          StickerPoint(96, 4),
          StickerPoint(96, 56),
          StickerPoint(4, 56),
        ],
        polygonPointIds: ['id-1', 'id-2', 'id-3', 'id-4'],
      ),
      act: (cubit) => cubit.saveAndContinue(),
      expect: () => [
        const StickerSetupSaving(),
        const StickerSetupSaved(templateId),
      ],
      verify: (_) {
        verify(() => templateRepository.saveStickerConfig(templateId, any())).called(1);
      },
    );
  });
}
