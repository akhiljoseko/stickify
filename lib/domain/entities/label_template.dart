import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/editor/element_blueprint.dart';
import 'package:stickify/domain/entities/sheet_config.dart';
import 'package:stickify/domain/entities/sticker_config.dart';

/// Represents a designed sticker/label template.
///
/// Contains references to the sheet layout configuration, sticker outline,
/// active elements (text, barcodes, shapes, etc.), and status flags.
class LabelTemplate extends Equatable {
  /// Creates a [LabelTemplate] design.
  const LabelTemplate({
    required this.id,
    required this.name,
    this.sheetConfig,
    this.stickerConfig,
    this.elements = const [],
    this.isFinalized = false,
    this.updatedAt,
    this.imageUrl,
  });

  /// Unique identifier of the label template.
  final String id;

  /// User-friendly name of the template (e.g. "ChronoMaster Premium Label").
  final String name;

  /// Layout configuration of the paper sheet on which labels are printed.
  final SheetConfig? sheetConfig;

  /// Dimensions and cut boundaries of the individual sticker.
  final StickerConfig? stickerConfig;

  /// Collection of customizable elements (e.g., text blocks, barcodes, images) in the template.
  final List<ElementBlueprint> elements;

  /// True if the design process is finished and the template can be printed.
  final bool isFinalized;

  /// Timestamp representing when the template design was last updated.
  final DateTime? updatedAt;

  /// Optional preview image URL or local file path for this template.
  final String? imageUrl;

  @override
  List<Object?> get props => [
        id,
        name,
        sheetConfig,
        stickerConfig,
        elements,
        isFinalized,
        updatedAt,
        imageUrl,
      ];

  /// Creates a copy of this [LabelTemplate] with the given fields replaced by new values.
  LabelTemplate copyWith({
    String? id,
    String? name,
    SheetConfig? sheetConfig,
    StickerConfig? stickerConfig,
    List<ElementBlueprint>? elements,
    bool? isFinalized,
    DateTime? updatedAt,
    String? imageUrl,
  }) {
    return LabelTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      sheetConfig: sheetConfig ?? this.sheetConfig,
      stickerConfig: stickerConfig ?? this.stickerConfig,
      elements: elements ?? this.elements,
      isFinalized: isFinalized ?? this.isFinalized,
      updatedAt: updatedAt ?? this.updatedAt,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
