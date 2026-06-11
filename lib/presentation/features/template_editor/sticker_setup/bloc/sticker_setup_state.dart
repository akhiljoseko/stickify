import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Base state for the sticker layout outline setup editor.
sealed class StickerSetupState extends Equatable {
  /// Base constructor.
  const StickerSetupState();

  @override
  List<Object?> get props => [];
}

/// Initial state of the sticker setup view.
class StickerSetupInitial extends StickerSetupState {
  /// Creates a [StickerSetupInitial] state.
  const StickerSetupInitial();
}

/// Loading state indicating data retrieval/initialization is active.
class StickerSetupLoading extends StickerSetupState {
  /// Creates a [StickerSetupLoading] state.
  const StickerSetupLoading();
}

/// Active editing state containing the dimensions, margin padding, and polygon vertices defining the sticker contour.
class StickerSetupEditing extends StickerSetupState {
  /// Creates a [StickerSetupEditing] state.
  const StickerSetupEditing({
    required this.widthMm,
    required this.heightMm,
    required this.cornerRadiusMm,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
    required this.polygonPoints,
    required this.polygonPointIds,
    this.isCustomPolygon = false,
  });

  /// Width of the sticker (mm).
  final double widthMm;

  /// Height of the sticker (mm).
  final double heightMm;

  /// Corner radius of the sticker (mm).
  final double cornerRadiusMm;

  /// Top printable boundary padding inset (mm).
  final double paddingTop;

  /// Bottom printable boundary padding inset (mm).
  final double paddingBottom;

  /// Left printable boundary padding inset (mm).
  final double paddingLeft;

  /// Right printable boundary padding inset (mm).
  final double paddingRight;

  /// True if the user defined a custom polygon printable contour boundary.
  final bool isCustomPolygon;

  /// Ordered vertices defining the custom printable polygon area.
  final List<StickerPoint> polygonPoints;

  /// Unique IDs corresponding to each custom polygon vertex.
  final List<String> polygonPointIds;

  /// Converts the current state data into a domain [StickerConfig] entity.
  StickerConfig toConfig() {
    return StickerConfig(
      widthMm: widthMm,
      heightMm: heightMm,
      cornerRadiusMm: cornerRadiusMm,
      printableArea: isCustomPolygon
          ? polygonPoints
          : [
              StickerPoint(paddingLeft, paddingTop),
              StickerPoint(widthMm - paddingRight, paddingTop),
              StickerPoint(widthMm - paddingRight, heightMm - paddingBottom),
              StickerPoint(paddingLeft, heightMm - paddingBottom),
            ],
    );
  }

  @override
  List<Object?> get props => [
        widthMm,
        heightMm,
        cornerRadiusMm,
        paddingTop,
        paddingBottom,
        paddingLeft,
        paddingRight,
        isCustomPolygon,
        polygonPoints,
        polygonPointIds,
      ];

  /// Returns a copy of this editing state with the given parameters overridden.
  StickerSetupEditing copyWith({
    double? widthMm,
    double? heightMm,
    double? cornerRadiusMm,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
    bool? isCustomPolygon,
    List<StickerPoint>? polygonPoints,
    List<String>? polygonPointIds,
  }) {
    return StickerSetupEditing(
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      cornerRadiusMm: cornerRadiusMm ?? this.cornerRadiusMm,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
      isCustomPolygon: isCustomPolygon ?? this.isCustomPolygon,
      polygonPoints: polygonPoints ?? this.polygonPoints,
      polygonPointIds: polygonPointIds ?? this.polygonPointIds,
    );
  }
}

/// Transition state during configuration save.
class StickerSetupSaving extends StickerSetupState {
  /// Creates a [StickerSetupSaving] state.
  const StickerSetupSaving();
}

/// Success state indicating the sticker outline was saved successfully.
class StickerSetupSaved extends StickerSetupState {
  /// Creates a [StickerSetupSaved] state.
  const StickerSetupSaved(this.templateId);

  /// The template ID that was modified.
  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

/// Error state conveying configuration issues or database failures.
class StickerSetupError extends StickerSetupState {
  /// Creates a [StickerSetupError] state.
  const StickerSetupError(this.message);

  /// The error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
