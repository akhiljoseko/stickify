import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/bloc/sheet_config_state.dart';

class SheetConfigCubit extends Cubit<SheetConfigState> {
  SheetConfigCubit(this._templateRepository, this.templateId)
    : super(const SheetConfigInitial());

  final TemplateRepository _templateRepository;
  final String templateId;

  Future<void> load() async {
    emit(const SheetConfigLoading());
    try {
      final template = await _templateRepository.fetchTemplate(templateId);
      final config =
          template.sheetConfig ??
          const SheetConfig(
            pageWidth: 210,
            pageHeight: 297,
            marginTop: 10,
            marginBottom: 10,
            marginLeft: 10,
            marginRight: 10,
            columns: 3,
            rows: 6,
            columnGap: 5,
            rowGap: 5,
          );
      emit(SheetConfigEditing(config));
    } on Exception catch (e) {
      emit(SheetConfigError(e.toString()));
    }
  }

  void updateConfig(SheetConfig config) {
    emit(SheetConfigEditing(config));
  }

  Future<void> saveAndContinue() async {
    final currentState = state;
    if (currentState is! SheetConfigEditing) return;

    emit(const SheetConfigSaving());
    try {
      await _templateRepository.saveSheetConfig(
        templateId,
        currentState.config,
      );
      emit(SheetConfigSaved(templateId));
    } on Object catch (e) {
      emit(SheetConfigError(e.toString()));
      // Restore editing state with previous config
      emit(SheetConfigEditing(currentState.config));
    }
  }
}
