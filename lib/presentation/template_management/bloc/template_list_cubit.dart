import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
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
    final result = await _templateRepository.fetchTemplates();
    switch (result) {
      case Success(value: final templates):
        emit(TemplateListLoaded(templates));
      case Failure(error: final err):
        emit(TemplateListError(err.message));
    }
  }

  /// Deletes the template with [id] and reloads the template list.
  Future<void> deleteTemplate(String id) async {
    final result = await _templateRepository.deleteTemplate(id);
    switch (result) {
      case Success():
        await loadTemplates();
      case Failure(error: final err):
        emit(TemplateListError(err.message));
    }
  }

  /// Creates a new template with [name] and reloads the template list.
  Future<LabelTemplate?> createNewTemplate(String name) async {
    final result = await _templateRepository.createTemplate(name);
    switch (result) {
      case Success(value: final template):
        await loadTemplates();
        return template;
      case Failure(error: final err):
        emit(TemplateListError(err.message));
        return null;
    }
  }
}
