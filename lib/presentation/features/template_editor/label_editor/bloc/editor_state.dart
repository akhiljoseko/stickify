import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Base class for all states emitted by the editor cubit.
sealed class EditorState extends Equatable {
  /// Creates an [EditorState] instance.
  const EditorState();

  @override
  List<Object?> get props => [];
}

/// State emitted when template data is being loaded.
class EditorLoading extends EditorState {
  /// Creates an [EditorLoading] instance.
  const EditorLoading();
}

/// State emitted when template designer details are successfully loaded and editable.
class EditorLoaded extends EditorState {
  /// Creates an [EditorLoaded] instance.
  const EditorLoaded({
    required this.stickerConfig,
    required this.elements,
    this.selectedElementId,
    this.zoomLevel = 1.0,
  });

  /// The dimensions and boundaries configuration of the sticker template.
  final StickerConfig stickerConfig;

  /// The list of placed visual blueprint components on the canvas.
  final List<ElementBlueprint> elements;

  /// The unique identifier of the currently selected element on the canvas.
  final String? selectedElementId;

  /// The current zoom scaling coefficient of the designer viewport.
  final double zoomLevel;

  /// Gets the selected blueprint element (if any matches [selectedElementId]).
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

  /// Creates a copy of this state with the given fields replaced.
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

/// State emitted when layout elements are being saved to the database.
class EditorSaving extends EditorState {
  /// Creates an [EditorSaving] instance.
  const EditorSaving();
}

/// State emitted when layout elements have been successfully saved.
class EditorSaved extends EditorState {
  /// Creates an [EditorSaved] instance.
  const EditorSaved(this.templateId);

  /// Unique template identifier.
  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

/// State emitted when an error occurs while configuring elements.
class EditorError extends EditorState {
  /// Creates an [EditorError] instance.
  const EditorError(this.message);

  /// Message describing the error.
  final String message;

  @override
  List<Object?> get props => [message];
}
