import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/data/repositories/database_settings_repository.dart';
import 'package:stickify/domain/domain.dart';

class MockLocalDatabase extends Mock implements LocalDatabase {}

void main() {
  late MockLocalDatabase localDatabase;
  late DatabaseSettingsRepository repository;

  setUp(() {
    localDatabase = MockLocalDatabase();
    repository = DatabaseSettingsRepository(database: localDatabase);
  });

  group('DatabaseSettingsRepository Tests', () {
    test('getSettings returns defaults when database returns nulls', () async {
      when(() => localDatabase.get<bool>('settings', 'enable_default_template_usage'))
          .thenAnswer((_) async => null);
      when(() => localDatabase.get<bool>('settings', 'enable_resume_partial_sheet'))
          .thenAnswer((_) async => null);
      when(() => localDatabase.get<bool>('settings', 'print_from_bottom'))
          .thenAnswer((_) async => null);
      when(() => localDatabase.get<bool>('settings', 'group_batch_variants'))
          .thenAnswer((_) async => null);
      when(() => localDatabase.get<bool>('settings', 'enable_per_sheet_spooling'))
          .thenAnswer((_) async => null);

      final settings = await repository.getSettings();

      expect(settings.enableDefaultTemplateUsage, isTrue);
      expect(settings.enableResumePartialSheet, isTrue);
      expect(settings.printFromBottom, isFalse);
      expect(settings.groupBatchVariants, isTrue);
      expect(settings.enablePerSheetSpooling, isFalse);
    });

    test('getSettings returns stored settings when database returns values', () async {
      when(() => localDatabase.get<bool>('settings', 'enable_default_template_usage'))
          .thenAnswer((_) async => false);
      when(() => localDatabase.get<bool>('settings', 'enable_resume_partial_sheet'))
          .thenAnswer((_) async => false);
      when(() => localDatabase.get<bool>('settings', 'print_from_bottom'))
          .thenAnswer((_) async => true);
      when(() => localDatabase.get<bool>('settings', 'group_batch_variants'))
          .thenAnswer((_) async => false);
      when(() => localDatabase.get<bool>('settings', 'enable_per_sheet_spooling'))
          .thenAnswer((_) async => true);

      final settings = await repository.getSettings();

      expect(settings.enableDefaultTemplateUsage, isFalse);
      expect(settings.enableResumePartialSheet, isFalse);
      expect(settings.printFromBottom, isTrue);
      expect(settings.groupBatchVariants, isFalse);
      expect(settings.enablePerSheetSpooling, isTrue);
    });

    test('saveSettings saves values into LocalDatabase and emits through watchSettings', () async {
      when(() => localDatabase.save<bool>(any(), any(), any()))
          .thenAnswer((_) async {});

      const updated = AppSettings(
        enableDefaultTemplateUsage: false,
        enableResumePartialSheet: false,
        printFromBottom: true,
        groupBatchVariants: false,
        enablePerSheetSpooling: true,
      );

      final expectation = expectLater(
        repository.watchSettings,
        emits(updated),
      );

      await repository.saveSettings(updated);
      await expectation;

      verify(() => localDatabase.save<bool>('settings', 'enable_default_template_usage', false)).called(1);
      verify(() => localDatabase.save<bool>('settings', 'enable_resume_partial_sheet', false)).called(1);
      verify(() => localDatabase.save<bool>('settings', 'print_from_bottom', true)).called(1);
      verify(() => localDatabase.save<bool>('settings', 'group_batch_variants', false)).called(1);
      verify(() => localDatabase.save<bool>('settings', 'enable_per_sheet_spooling', true)).called(1);
    });
  });
}
