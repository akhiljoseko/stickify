import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/bloc/sheet_config_state.dart';

/// Cubit that manages the layout state of a printable sticker sheet template.
///
/// Handles fetching the current configuration, updates to dimensions/margins,
/// and saving changes back to the repository.
class SheetConfigCubit extends Cubit<SheetConfigState> {
  /// Creates a [SheetConfigCubit] instance.
  SheetConfigCubit(this._templateRepository, this.templateId)
      : super(const SheetConfigInitial());

  final TemplateRepository _templateRepository;

  /// The unique identifier of the template being configured.
  final String templateId;

  /// Loads the sheet configuration for [templateId].
  ///
  /// Emits [SheetConfigLoading] followed by [SheetConfigEditing] with a loaded
  /// configuration (or default values if none exist yet).
  Future<void> load() async {
    emit(const SheetConfigLoading());
    final result = await _templateRepository.fetchTemplate(templateId);
    switch (result) {
      case Success(value: final template):
        final config =
            template.sheetConfig ??
            const SheetConfig(
              pageWidth: 210,
              pageHeight: 297,
              marginTop: 0,
              marginBottom: 0,
              marginLeft: 0,
              marginRight: 0,
              columns: 3,
              rows: 6,
              columnGap: 0,
              rowGap: 0,
            );
        emit(SheetConfigEditing(config));
      case Failure(error: final err):
        emit(SheetConfigError(err.message));
    }
  }

  /// Updates the current sheet layout parameters and emits the editing state.
  void updateConfig(SheetConfig config) {
    emit(SheetConfigEditing(config));
  }

  /// Saves the active sheet configuration parameters to repository.
  ///
  /// Transition to [SheetConfigSaved] upon success, or [SheetConfigError] on failure.
  Future<void> saveAndContinue() async {
    final currentState = state;
    if (currentState is! SheetConfigEditing) return;

    emit(const SheetConfigSaving());
    final result = await _templateRepository.saveSheetConfig(
      templateId,
      currentState.config,
    );
    switch (result) {
      case Success():
        emit(SheetConfigSaved(templateId));
      case Failure(error: final err):
        emit(SheetConfigError(err.message));
        // Restore editing state with previous config
        emit(SheetConfigEditing(currentState.config));
    }
  }
}
