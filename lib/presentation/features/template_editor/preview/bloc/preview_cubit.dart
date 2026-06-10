import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/preview/bloc/preview_state.dart';

class PreviewCubit extends Cubit<PreviewState> {
  PreviewCubit(this._templateRepository, this.templateId)
    : super(const PreviewLoading());

  final TemplateRepository _templateRepository;
  final String templateId;

  Future<void> loadPreview() async {
    emit(const PreviewLoading());
    try {
      final template = await _templateRepository.fetchTemplate(templateId);
      emit(PreviewLoaded(template));
    } on Exception catch (e) {
      emit(PreviewError(e.toString()));
    }
  }

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
