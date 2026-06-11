import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/template_management/bloc/template_list_state.dart';

/// Cubit managing the list and CRUD operations of sticker templates.
class TemplateListCubit extends Cubit<TemplateListState> {
  /// Creates a [TemplateListCubit] instance.
  TemplateListCubit(this._templateRepository) : super(const TemplateListInitial());

  final TemplateRepository _templateRepository;

  /// Loads all templates from the repository and emits loaded status.
  Future<void> loadTemplates() async {
    emit(const TemplateListLoading());
    try {
      final templates = await _templateRepository.fetchTemplates();
      emit(TemplateListLoaded(templates));
    } on Object catch (e) {
      emit(TemplateListError(e.toString()));
    }
  }

  /// Deletes the template with [id] and reloads the template list.
  Future<void> deleteTemplate(String id) async {
    try {
      await _templateRepository.deleteTemplate(id);
      await loadTemplates();
    } on Object catch (e) {
      emit(TemplateListError(e.toString()));
    }
  }

  /// Creates a new template with [name] and reloads the template list.
  Future<LabelTemplate?> createNewTemplate(String name) async {
    try {
      final template = await _templateRepository.createTemplate(name);
      await loadTemplates();
      return template;
    } on Object catch (e) {
      emit(TemplateListError(e.toString()));
      return null;
    }
  }
}
