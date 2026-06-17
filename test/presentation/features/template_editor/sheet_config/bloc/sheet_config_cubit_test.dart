import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/bloc/sheet_config_cubit.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/bloc/sheet_config_state.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}

void main() {
  late TemplateRepository templateRepository;
  const templateId = 'temp-123';

  setUpAll(() {
    registerFallbackValue(const SheetConfig(
      pageWidth: 210, pageHeight: 297,
      marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0,
      columns: 3, rows: 6, columnGap: 0, rowGap: 0,
    ));
  });

  setUp(() {
    templateRepository = MockTemplateRepository();
  });

  group('SheetConfigCubit', () {
    blocTest<SheetConfigCubit, SheetConfigState>(
      'load emits default config when template has no sheet config',
      build: () {
        when(() => templateRepository.fetchTemplate(templateId)).thenAnswer(
          (_) async => Result.success(
            LabelTemplate(id: templateId, name: 'Test'),
          ),
        );
        return SheetConfigCubit(templateRepository, templateId);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const SheetConfigLoading(),
        isA<SheetConfigEditing>()
            .having((s) => s.config.marginTop, 'marginTop', 0.0)
            .having((s) => s.config.marginBottom, 'marginBottom', 0.0)
            .having((s) => s.config.marginLeft, 'marginLeft', 0.0)
            .having((s) => s.config.marginRight, 'marginRight', 0.0)
            .having((s) => s.config.columnGap, 'columnGap', 0.0)
            .having((s) => s.config.rowGap, 'rowGap', 0.0)
            .having((s) => s.config.columns, 'columns', 3)
            .having((s) => s.config.rows, 'rows', 6),
      ],
    );

    blocTest<SheetConfigCubit, SheetConfigState>(
      'load reads sheet config from template when present',
      build: () {
        final existingConfig = const SheetConfig(
          pageWidth: 210,
          pageHeight: 297,
          marginTop: 10,
          marginBottom: 10,
          marginLeft: 5,
          marginRight: 5,
          columns: 2,
          rows: 3,
          columnGap: 2,
          rowGap: 2,
        );
        when(() => templateRepository.fetchTemplate(templateId)).thenAnswer(
          (_) async => Result.success(
            LabelTemplate(id: templateId, name: 'Test', sheetConfig: existingConfig),
          ),
        );
        return SheetConfigCubit(templateRepository, templateId);
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const SheetConfigLoading(),
        isA<SheetConfigEditing>()
            .having((s) => s.config.marginTop, 'marginTop', 10.0)
            .having((s) => s.config.columns, 'columns', 2),
      ],
    );

    blocTest<SheetConfigCubit, SheetConfigState>(
      'updateConfig replaces current config',
      build: () => SheetConfigCubit(templateRepository, templateId),
      seed: () => const SheetConfigEditing(
        SheetConfig(pageWidth: 210, pageHeight: 297, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0, columns: 3, rows: 6, columnGap: 0, rowGap: 0),
      ),
      act: (cubit) => cubit.updateConfig(
        const SheetConfig(pageWidth: 100, pageHeight: 200, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0, columns: 3, rows: 6, columnGap: 0, rowGap: 0),
      ),
      expect: () => [
        isA<SheetConfigEditing>()
            .having((s) => s.config.pageWidth, 'pageWidth', 100.0)
            .having((s) => s.config.pageHeight, 'pageHeight', 200.0),
      ],
    );

    blocTest<SheetConfigCubit, SheetConfigState>(
      'saveAndContinue invokes repo save and emits saved',
      build: () {
        when(() => templateRepository.saveSheetConfig(any(), any()))
            .thenAnswer((_) async => const Result.success(null));
        return SheetConfigCubit(templateRepository, templateId);
      },
      seed: () => const SheetConfigEditing(
        SheetConfig(pageWidth: 210, pageHeight: 297, marginTop: 0, marginBottom: 0, marginLeft: 0, marginRight: 0, columns: 3, rows: 6, columnGap: 0, rowGap: 0),
      ),
      act: (cubit) => cubit.saveAndContinue(),
      expect: () => [
        const SheetConfigSaving(),
        const SheetConfigSaved(templateId),
      ],
      verify: (_) {
        verify(() => templateRepository.saveSheetConfig(templateId, any())).called(1);
      },
    );
  });
}
