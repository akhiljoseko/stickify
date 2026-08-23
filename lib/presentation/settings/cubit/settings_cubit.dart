import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/settings/cubit/settings_state.dart';

/// Cubit that manages application configuration settings.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates a [SettingsCubit] instance.
  SettingsCubit({
    required this.settingsRepository,
  }) : super(const SettingsState()) {
    _subscription = settingsRepository.watchSettings.listen((updated) {
      emit(state.copyWith(isLoading: false, settings: updated));
    });
  }

  /// The settings repository instance.
  final SettingsRepository settingsRepository;
  StreamSubscription<AppSettings>? _subscription;

  /// Loads settings from repository.
  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    final settings = await settingsRepository.getSettings();
    emit(state.copyWith(isLoading: false, settings: settings));
  }

  /// Toggles the default template auto-skip configuration in single product print workflow.
  Future<void> setEnableDefaultTemplateUsage({required bool value}) async {
    final updated = state.settings.copyWith(enableDefaultTemplateUsage: value);
    await _save(updated);
  }

  /// Toggles the resume partial sheet configuration.
  Future<void> setEnableResumePartialSheet({required bool value}) async {
    final updated = state.settings.copyWith(enableResumePartialSheet: value);
    await _save(updated);
  }

  /// Toggles the print from bottom configuration.
  Future<void> setPrintFromBottom({required bool value}) async {
    final updated = state.settings.copyWith(printFromBottom: value);
    await _save(updated);
  }

  /// Toggles the batch variant grouping configuration.
  Future<void> setGroupBatchVariants({required bool value}) async {
    final updated = state.settings.copyWith(groupBatchVariants: value);
    await _save(updated);
  }

  Future<void> _save(AppSettings updated) async {
    emit(state.copyWith(settings: updated));
    await settingsRepository.saveSettings(updated);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
