import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_state.dart';

class EditorCubit extends Cubit<EditorState> {
  EditorCubit(this._templateRepository, this.templateId)
    : super(const EditorLoading());

  final TemplateRepository _templateRepository;
  final String templateId;

  Future<void> load() async {
    emit(const EditorLoading());
    try {
      final template = await _templateRepository.fetchTemplate(templateId);
      final stickerConfig =
          template.stickerConfig ??
          const StickerConfig(
            widthMm: 100,
            heightMm: 60,
            cornerRadiusMm: 4,
            printableArea: [],
          );
      emit(
        EditorLoaded(
          stickerConfig: stickerConfig,
          elements: template.elements,
        ),
      );
    } on Exception catch (e) {
      emit(EditorError(e.toString()));
    }
  }

  void addElement(ElementBlueprint element) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updated = List<ElementBlueprint>.from(currentState.elements)
      ..add(element);
    emit(
      currentState.copyWith(
        elements: updated,
        selectedElementId: element.id, // Auto-select newly added element
      ),
    );
  }

  void moveElement(String id, double newX, double newY) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updated = currentState.elements.map((e) {
      if (e.id == id) {
        return e.copyWith(x: newX, y: newY);
      }
      return e;
    }).toList();

    emit(currentState.copyWith(elements: updated));
  }

  void nudgeElement(String id, double dx, double dy) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updated = currentState.elements.map((e) {
      if (e.id == id) {
        return e.copyWith(x: e.x + dx, y: e.y + dy);
      }
      return e;
    }).toList();

    emit(currentState.copyWith(elements: updated));
  }

  void dragElement(String id, double dx, double dy) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    // Find the element being dragged
    final elementIndex = currentState.elements.indexWhere((e) => e.id == id);
    if (elementIndex == -1) return;

    final element = currentState.elements[elementIndex];

    // 1. Calculate proposed position
    var newX = element.x + dx;
    var newY = element.y + dy;

    // Sticker boundaries
    const mmToPx = 4;
    final stickerWidth = currentState.stickerConfig.widthMm * mmToPx;
    final stickerHeight = currentState.stickerConfig.heightMm * mmToPx;

    // Clamp inside the sticker bounds
    newX = newX.clamp(0.0, stickerWidth - element.width);
    newY = newY.clamp(0.0, stickerHeight - element.height);

    // 2. Emit updated state
    final updated = currentState.elements.map((e) {
      if (e.id == id) {
        return e.copyWith(x: newX, y: newY);
      }
      return e;
    }).toList();

    emit(currentState.copyWith(elements: updated));
  }

  void selectElement(String id) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    emit(currentState.copyWith(selectedElementId: id));
  }

  void deselectAll() {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    emit(currentState.copyWith(clearSelection: true));
  }

  void updateElementProperty(String id, ElementBlueprint updatedElement) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updated = currentState.elements.map((e) {
      if (e.id == id) {
        return updatedElement;
      }
      return e;
    }).toList();

    emit(currentState.copyWith(elements: updated));
  }

  void deleteElement(String id) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    final updated = List<ElementBlueprint>.from(currentState.elements)
      ..removeWhere((e) => e.id == id);
    emit(
      currentState.copyWith(
        elements: updated,
        clearSelection: currentState.selectedElementId == id,
      ),
    );
  }

  void setZoom(double level) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    // Clamp zoom level between 0.5 (50%) and 2.0 (200%)
    final clamped = level.clamp(0.5, 2.0);
    emit(currentState.copyWith(zoomLevel: clamped));
  }

  Future<void> saveAndContinue() async {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    emit(const EditorSaving());
    try {
      await _templateRepository.saveElements(templateId, currentState.elements);
      emit(EditorSaved(templateId));
    } on Exception catch (e) {
      emit(EditorError(e.toString()));
      emit(currentState);
    }
  }
}
