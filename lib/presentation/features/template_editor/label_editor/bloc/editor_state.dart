import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

sealed class EditorState extends Equatable {
  const EditorState();

  @override
  List<Object?> get props => [];
}

class EditorLoading extends EditorState {
  const EditorLoading();
}

class EditorLoaded extends EditorState {
  const EditorLoaded({
    required this.stickerConfig,
    required this.elements,
    this.selectedElementId,
    this.zoomLevel = 1.0,
  });

  final StickerConfig stickerConfig;
  final List<ElementBlueprint> elements;
  final String? selectedElementId;
  final double zoomLevel;

  ElementBlueprint? get selectedElement {
    if (selectedElementId == null) return null;
    for (final e in elements) {
      if (e.id == selectedElementId) return e;
    }
    return null;
  }

  @override
  List<Object?> get props => [
        stickerConfig,
        elements,
        selectedElementId,
        zoomLevel,
      ];

  EditorLoaded copyWith({
    StickerConfig? stickerConfig,
    List<ElementBlueprint>? elements,
    String? selectedElementId,
    double? zoomLevel,
    bool clearSelection = false,
  }) {
    return EditorLoaded(
      stickerConfig: stickerConfig ?? this.stickerConfig,
      elements: elements ?? this.elements,
      selectedElementId: clearSelection ? null : (selectedElementId ?? this.selectedElementId),
      zoomLevel: zoomLevel ?? this.zoomLevel,
    );
  }
}

class EditorSaving extends EditorState {
  const EditorSaving();
}

class EditorSaved extends EditorState {
  const EditorSaved(this.templateId);

  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

class EditorError extends EditorState {
  const EditorError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
