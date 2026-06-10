import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_state.dart';

class StickerSetupCubit extends Cubit<StickerSetupState> {
  StickerSetupCubit(this._templateRepository, this.templateId)
      : super(const StickerSetupInitial());

  final TemplateRepository _templateRepository;
  final String templateId;

  Future<void> load() async {
    emit(const StickerSetupLoading());
    try {
      final template = await _templateRepository.fetchTemplate(templateId);
      final config = template.stickerConfig;
      
      if (config != null) {
        // Deconstruct printable area polygon to find padding
        // TL is (L, T)
        final tl = config.printableArea.isNotEmpty ? config.printableArea[0] : const StickerPoint(4, 4);
        final br = config.printableArea.length > 2 ? config.printableArea[2] : const StickerPoint(96, 56);
        
        final paddingLeft = tl.x;
        final paddingTop = tl.y;
        final paddingRight = config.widthMm - br.x;
        final paddingBottom = config.heightMm - br.y;

        emit(StickerSetupEditing(
          widthMm: config.widthMm,
          heightMm: config.heightMm,
          cornerRadiusMm: config.cornerRadiusMm,
          paddingTop: paddingTop,
          paddingBottom: paddingBottom,
          paddingLeft: paddingLeft,
          paddingRight: paddingRight,
        ));
      } else {
        emit(const StickerSetupEditing(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          paddingTop: 4,
          paddingBottom: 4,
          paddingLeft: 4,
          paddingRight: 4,
        ));
      }
    } catch (e) {
      emit(StickerSetupError(e.toString()));
    }
  }

  void updateFields({
    double? widthMm,
    double? heightMm,
    double? cornerRadiusMm,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
  }) {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    emit(currentState.copyWith(
      widthMm: widthMm,
      heightMm: heightMm,
      cornerRadiusMm: cornerRadiusMm,
      paddingTop: paddingTop,
      paddingBottom: paddingBottom,
      paddingLeft: paddingLeft,
      paddingRight: paddingRight,
    ));
  }

  Future<void> saveAndContinue() async {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    emit(const StickerSetupSaving());
    try {
      final config = currentState.toConfig();
      await _templateRepository.saveStickerConfig(templateId, config);
      emit(StickerSetupSaved(templateId));
    } catch (e) {
      emit(StickerSetupError(e.toString()));
      emit(currentState);
    }
  }
}
