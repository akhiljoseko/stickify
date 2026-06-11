import 'package:flutter_bloc/flutter_bloc.dart';
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
    try {
      final template = await _templateRepository.fetchTemplate(templateId);
      emit(PreviewLoaded(template));
    } on Exception catch (e) {
      emit(PreviewError(e.toString()));
    }
  }

  /// Finalizes the template structure and saves it to the database.
  Future<void> finalizeAndSave() async {
    emit(const PreviewFinalizing());
    try {
      await _templateRepository.finalizeTemplate(templateId);
      emit(const PreviewFinalized());
    } on Object catch (e) {
      emit(PreviewError(e.toString()));
      // Reload preview to recover
      await loadPreview();
    }
  }
}
