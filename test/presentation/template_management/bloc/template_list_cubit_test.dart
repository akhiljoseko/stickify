import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/template_management/bloc/template_list_cubit.dart';
import 'package:stickify/presentation/template_management/bloc/template_list_state.dart';

class MockTemplateRepository extends Mock implements TemplateRepository {}
class MockFileStorageService extends Mock implements FileStorageService {}
class FakeLabelTemplate extends Fake implements LabelTemplate {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTemplateRepository mockTemplateRepo;
  late MockFileStorageService mockFileStorageService;
  late TemplateListCubit cubit;

  const testTemplate = LabelTemplate(
    id: 'temp-1',
    name: 'Original Template',
    sheetConfig: SheetConfig(
      pageWidth: 210,
      pageHeight: 297,
      columns: 2,
      rows: 5,
      marginTop: 10,
      marginBottom: 10,
      marginLeft: 10,
      marginRight: 10,
      columnGap: 5,
      rowGap: 5,
    ),
    isFinalized: true,
  );

  setUpAll(() {
    registerFallbackValue(FakeLabelTemplate());
  });

  setUp(() {
    mockTemplateRepo = MockTemplateRepository();
    mockFileStorageService = MockFileStorageService();
    cubit = TemplateListCubit(mockTemplateRepo, mockFileStorageService);
  });

  tearDown(() {
    cubit.close();
  });

  group('TemplateListCubit Tests', () {
    test('loadTemplates emits TemplateListLoaded on success', () async {
      when(() => mockTemplateRepo.fetchTemplates())
          .thenAnswer((_) async => const Result.success([testTemplate]));

      await cubit.loadTemplates();

      expect(cubit.state, isA<TemplateListLoaded>());
      expect((cubit.state as TemplateListLoaded).templates, contains(testTemplate));
    });

    test('copyTemplate creates deep copy with new name and saves repository template', () async {
      const createdShell = LabelTemplate(id: 'temp-2', name: 'Original Template (Copy)');

      when(() => mockTemplateRepo.createTemplate('Original Template (Copy)'))
          .thenAnswer((_) async => const Result.success(createdShell));
      when(() => mockTemplateRepo.saveTemplate(any()))
          .thenAnswer((_) async => const Result.success(null));
      when(() => mockTemplateRepo.fetchTemplates())
          .thenAnswer((_) async => const Result.success([testTemplate, createdShell]));

      final copied = await cubit.copyTemplate(testTemplate, 'Original Template (Copy)');

      expect(copied, isNotNull);
      expect(copied!.name, 'Original Template (Copy)');
      expect(copied.sheetConfig, testTemplate.sheetConfig);
      expect(copied.isFinalized, testTemplate.isFinalized);

      verify(() => mockTemplateRepo.createTemplate('Original Template (Copy)')).called(1);
      verify(() => mockTemplateRepo.saveTemplate(any())).called(1);
    });

    test('deleteTemplate deletes template and reloads list', () async {
      when(() => mockTemplateRepo.deleteTemplate('temp-1'))
          .thenAnswer((_) async => const Result.success(null));
      when(() => mockTemplateRepo.fetchTemplates())
          .thenAnswer((_) async => const Result.success([]));

      await cubit.deleteTemplate('temp-1');

      verify(() => mockTemplateRepo.deleteTemplate('temp-1')).called(1);
      expect(cubit.state, isA<TemplateListLoaded>());
      expect((cubit.state as TemplateListLoaded).templates, isEmpty);
    });
  });
}
