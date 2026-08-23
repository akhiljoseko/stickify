import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/settings/cubit/settings_cubit.dart';
import 'package:stickify/presentation/settings/cubit/settings_state.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(AppSettings.defaults);
  });

  late SettingsRepository settingsRepository;

  setUp(() {
    settingsRepository = MockSettingsRepository();
    when(() => settingsRepository.watchSettings)
        .thenAnswer((_) => const Stream.empty());
    when(() => settingsRepository.saveSettings(any()))
        .thenAnswer((_) async {});
  });

  group('SettingsCubit Tests', () {
    test('initial state has correct default values', () {
      final cubit = SettingsCubit(settingsRepository: settingsRepository);
      expect(cubit.state, const SettingsState());
    });

    blocTest<SettingsCubit, SettingsState>(
      'loadSettings emits loaded state with repository settings',
      build: () {
        when(() => settingsRepository.getSettings()).thenAnswer(
          (_) async => const AppSettings(
            enableDefaultTemplateUsage: false,
            printFromBottom: true,
          ),
        );
        return SettingsCubit(settingsRepository: settingsRepository);
      },
      act: (cubit) => cubit.loadSettings(),
      expect: () => [
        const SettingsState(),
        const SettingsState(
          isLoading: false,
          settings: AppSettings(
            enableDefaultTemplateUsage: false,
            printFromBottom: true,
          ),
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setEnableDefaultTemplateUsage updates state and saves to repository',
      build: () => SettingsCubit(settingsRepository: settingsRepository),
      act: (cubit) => cubit.setEnableDefaultTemplateUsage(value: false),
      expect: () => [
        const SettingsState(
          settings: AppSettings(enableDefaultTemplateUsage: false),
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.saveSettings(
            const AppSettings(enableDefaultTemplateUsage: false),
          ),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'setEnableResumePartialSheet updates state and saves to repository',
      build: () => SettingsCubit(settingsRepository: settingsRepository),
      act: (cubit) => cubit.setEnableResumePartialSheet(value: false),
      expect: () => [
        const SettingsState(
          settings: AppSettings(enableResumePartialSheet: false),
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.saveSettings(
            const AppSettings(enableResumePartialSheet: false),
          ),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'setPrintFromBottom updates state and saves to repository',
      build: () => SettingsCubit(settingsRepository: settingsRepository),
      act: (cubit) => cubit.setPrintFromBottom(value: true),
      expect: () => [
        const SettingsState(
          settings: AppSettings(printFromBottom: true),
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.saveSettings(
            const AppSettings(printFromBottom: true),
          ),
        ).called(1);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'setGroupBatchVariants updates state and saves to repository',
      build: () => SettingsCubit(settingsRepository: settingsRepository),
      act: (cubit) => cubit.setGroupBatchVariants(value: false),
      expect: () => [
        const SettingsState(
          settings: AppSettings(groupBatchVariants: false),
        ),
      ],
      verify: (_) {
        verify(
          () => settingsRepository.saveSettings(
            const AppSettings(groupBatchVariants: false),
          ),
        ).called(1);
      },
    );
  });
}
