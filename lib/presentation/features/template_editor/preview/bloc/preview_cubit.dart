import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/preview/bloc/preview_state.dart';

/// Cubit that manages the state of the template preview screen.
///
/// Handles loading the configured layout template and finalizing the design.
class PreviewCubit extends Cubit<PreviewState> {
  /// Creates a [PreviewCubit] instance.
  PreviewCubit(this._templateRepository, this.templateId)
      : super(const PreviewLoading());

  final TemplateRepository _templateRepository;

  /// The unique identifier of the template to preview.
  final String templateId;

  /// Loads the template from repository to display in the preview.
  Future<void> loadPreview() async {
    emit(const PreviewLoading());
    final result = await _templateRepository.fetchTemplate(templateId);
    switch (result) {
      case Success(value: final template):
        emit(PreviewLoaded(template));
      case Failure(error: final err):
        emit(PreviewError(err.message));
    }
  }

  /// Finalizes the template structure and saves it to the database.
  Future<void> finalizeAndSave() async {
    emit(const PreviewFinalizing());
    final result = await _templateRepository.finalizeTemplate(templateId);
    switch (result) {
      case Success():
        emit(const PreviewFinalized());
      case Failure(error: final err):
        emit(PreviewError(err.message));
        // Reload preview to recover
        await loadPreview();
    }
  }
}
