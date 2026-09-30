import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/services/product_brochure_generator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/settings/cubit/settings_state.dart';

/// Cubit that manages application configuration settings.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates a [SettingsCubit] instance.
  SettingsCubit({
    required this.settingsRepository,
    required this.productRepository,
    required this.brochureGenerator,
  }) : super(const SettingsState()) {
    _subscription = settingsRepository.watchSettings.listen((updated) {
      emit(state.copyWith(isLoading: false, settings: updated));
    });
  }

  /// The settings repository instance.
  final SettingsRepository settingsRepository;

  /// Repository used to fetch all products for brochure generation.
  final ProductRepository productRepository;

  /// Service responsible for generating the PDF brochure bytes and saving/sharing.
  final ProductBrochureGenerator brochureGenerator;

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

  /// Toggles the per-sheet print job spooling configuration.
  Future<void> setEnablePerSheetSpooling({required bool value}) async {
    final updated = state.settings.copyWith(enablePerSheetSpooling: value);
    await _save(updated);
  }

  /// Generates and saves/shares a product catalogue brochure PDF.
  ///
  /// On desktop (Windows / macOS) the PDF is written to the Downloads folder
  /// and [SettingsState.brochureSavedPath] contains the absolute path.
  /// On mobile (iOS / Android) the native share sheet is opened.
  Future<void> exportProductBrochure() async {
    emit(
      state.copyWith(
        brochureExportStatus: BrochureExportStatus.loading,
      ),
    );

    try {
      final result = await productRepository.getAllProducts();

      switch (result) {
        case Failure(:final error):
          emit(
            state.copyWith(
              brochureExportStatus: BrochureExportStatus.failure,
              brochureExportError: error.message,
            ),
          );
          return;
        case Success(:final value):
          if (value.isEmpty) {
            emit(
              state.copyWith(
                brochureExportStatus: BrochureExportStatus.failure,
                brochureExportError:
                    'No products found. Add products before exporting a brochure.',
              ),
            );
            return;
          }

          final savedPath = await brochureGenerator.generateAndSave(
            products: value,
          );

          emit(
            state.copyWith(
              brochureExportStatus: BrochureExportStatus.success,
              brochureSavedPath: savedPath.isEmpty ? null : savedPath,
            ),
          );
      }
    } catch (e) {
      emit(
        state.copyWith(
          brochureExportStatus: BrochureExportStatus.failure,
          brochureExportError: 'Unexpected error: $e',
        ),
      );
    }
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
