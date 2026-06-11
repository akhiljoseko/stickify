import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_state.dart';

/// Cubit managing the label designer canvas editor state.
///
/// Handles adding, editing, moving, scaling, deleting, and saving label elements.
class EditorCubit extends Cubit<EditorState> {
  /// Creates an [EditorCubit] instance.
  EditorCubit(this._templateRepository, this.templateId)
      : super(const EditorLoading());

  final TemplateRepository _templateRepository;

  /// The unique identifier of the template being designed.
  final String templateId;

  /// Loads the template from repository to initiate the label design canvas editing.
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

  /// Adds a new layout [element] blueprint to the editor canvas.
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

  /// Relocates the element to absolute canvas coordinates [newX] and [newY].
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

  /// Nudges the element relatively by offset [dx] and [dy].
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

  /// Drags the element by offset [dx] and [dy], clamping inside boundary bounds.
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

  /// Selects the element with identifier [id].
  void selectElement(String id) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    emit(currentState.copyWith(selectedElementId: id));
  }

  /// Deselects all elements on the canvas.
  void deselectAll() {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    emit(currentState.copyWith(clearSelection: true));
  }

  /// Updates properties of the element by replacing with [updatedElement].
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

  /// Removes the element from the canvas.
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

  /// Adjusts the canvas viewport zoom level.
  void setZoom(double level) {
    final currentState = state;
    if (currentState is! EditorLoaded) return;

    // Clamp zoom level between 0.5 (50%) and 2.0 (200%)
    final clamped = level.clamp(0.5, 2.0);
    emit(currentState.copyWith(zoomLevel: clamped));
  }

  /// Saves the active elements configuration to the template repository and continues.
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
