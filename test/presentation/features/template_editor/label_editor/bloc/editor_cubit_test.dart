import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_state.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  late TemplateRepository templateRepository;
  const templateId = 'temp-123';
  late StickerConfig defaultStickerConfig;
  late TextElementBlueprint defaultElement;

  setUpAll(() {
    registerFallbackValue(const <ElementBlueprint>[]);
  });

  setUp(() {
    templateRepository = MockTemplateRepository();
    defaultStickerConfig = const StickerConfig(
      widthMm: 100, // width in px = 400
      heightMm: 60, // height in px = 240
      cornerRadiusMm: 4,
      printableArea: [
        StickerPoint(4, 4),
        StickerPoint(96, 4),
        StickerPoint(96, 56),
        StickerPoint(4, 56),
      ],
    );
    defaultElement = const TextElementBlueprint(
      id: 'elem-1',
      x: 50,
      y: 30,
      width: 30,
      height: 15,
      rotation: 0,
      content: 'Hello',
      isDynamic: false,
      fontSize: 14,
      fontWeightValue: 400,
      textAlign: BlueprintTextAlign.left,
      colorHex: 0xFF000000,
    );
  });

  group('EditorCubit Snapping & Clamping Tests', () {
    blocTest<EditorCubit, EditorState>(
      'loads elements successfully from repository',
      build: () {
        when(() => templateRepository.fetchTemplate(templateId)).thenAnswer(
          (_) async => Result.success(LabelTemplate(
            id: templateId,
            name: 'Test Template',
            stickerConfig: defaultStickerConfig,
            elements: [defaultElement],
          )),
        );
        return EditorCubit(templateRepository, templateId);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const EditorLoading(),
        isA<EditorLoaded>()
            .having((s) => s.elements.length, 'elements.length', 1)
            .having((s) => s.elements[0].id, 'element id', 'elem-1')
            .having((s) => s.stickerConfig.widthMm, 'widthMm', 100),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'dragElement moves the element freely by exactly dx/dy and clamps inside boundary',
      build: () => EditorCubit(templateRepository, templateId),
      seed: () => EditorLoaded(
        stickerConfig: defaultStickerConfig,
        elements: [defaultElement],
      ),
      act: (cubit) {
        // Drag it down and right by 10 mm
        cubit.dragElement('elem-1', 10, 15);
      },
      expect: () => [
        isA<EditorLoaded>()
            .having((s) => s.elements[0].x, 'x moves freely to 60', 60.0)
            .having((s) => s.elements[0].y, 'y moves freely to 45', 45.0),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'dragElement clamps coordinate to 0.0 when dragged off top-left',
      build: () => EditorCubit(templateRepository, templateId),
      seed: () => EditorLoaded(
        stickerConfig: defaultStickerConfig,
        elements: [defaultElement],
      ),
      act: (cubit) {
        // Drag it far left and top
        cubit.dragElement('elem-1', -100, -100);
      },
      expect: () => [
        isA<EditorLoaded>()
            .having((s) => s.elements[0].x, 'x clamped to 0.0', 0.0)
            .having((s) => s.elements[0].y, 'y clamped to 0.0', 0.0),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'dragElement clamps coordinate to sticker bounds when dragged off bottom-right',
      build: () => EditorCubit(templateRepository, templateId),
      seed: () => EditorLoaded(
        stickerConfig: defaultStickerConfig,
        elements: [defaultElement],
      ),
      act: (cubit) {
        // Sticker is 100x60 mm. Element at (50,50) with size 30x15.
        // Max x = 100 - 30 = 70. Max y = 60 - 15 = 45.
        // Drag far bottom-right: newX = 550 → clamped to 70; newY = 550 → clamped to 45.
        cubit.dragElement('elem-1', 500, 500);
      },
      expect: () => [
        isA<EditorLoaded>()
            .having((s) => s.elements[0].x, 'x clamped to 70', 70.0)
            .having((s) => s.elements[0].y, 'y clamped to 45', 45.0),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'nudgeElement moves coordinate by precise steps (keyboard arrow nudge)',
      build: () => EditorCubit(templateRepository, templateId),
      seed: () => EditorLoaded(
        stickerConfig: defaultStickerConfig,
        elements: [defaultElement],
      ),
      act: (cubit) => cubit.nudgeElement('elem-1', 1, -1),
      expect: () => [
        isA<EditorLoaded>()
            .having((s) => s.elements[0].x, 'x nudged by 1.0 to 51', 51.0)
            .having((s) => s.elements[0].y, 'y nudged by -1.0 to 29', 29.0),
      ],
    );

    blocTest<EditorCubit, EditorState>(
      'saveAndContinue calls saveElements and emits saved state',
      build: () {
        when(() => templateRepository.saveElements(any(), any()))
            .thenAnswer((_) async => const Result.success(null));
        return EditorCubit(templateRepository, templateId);
      },
      seed: () => EditorLoaded(
        stickerConfig: defaultStickerConfig,
        elements: [defaultElement],
      ),
      act: (cubit) => cubit.saveAndContinue(),
      expect: () => [
        const EditorSaving(),
        const EditorSaved(templateId),
      ],
      verify: (_) {
        verify(() => templateRepository.saveElements(templateId, [defaultElement])).called(1);
      },
    );
  });
}
