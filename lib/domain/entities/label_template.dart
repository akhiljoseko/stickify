import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/editor/element_blueprint.dart';
import 'package:stickify/domain/entities/sheet_config.dart';
import 'package:stickify/domain/entities/sticker_config.dart';

class LabelTemplate extends Equatable {
  const LabelTemplate({
    required this.id,
    required this.name,
    this.sheetConfig,
    this.stickerConfig,
    this.elements = const [],
    this.isFinalized = false,
    this.updatedAt,
  });

  final String id;
  final String name;
  final SheetConfig? sheetConfig;
  final StickerConfig? stickerConfig;
  final List<ElementBlueprint> elements;
  final bool isFinalized;
  final DateTime? updatedAt;

  @override
  List<Object?> get props => [
        id,
        name,
        sheetConfig,
        stickerConfig,
        elements,
        isFinalized,
        updatedAt,
      ];

  LabelTemplate copyWith({
    String? id,
    String? name,
    SheetConfig? sheetConfig,
    StickerConfig? stickerConfig,
    List<ElementBlueprint>? elements,
    bool? isFinalized,
    DateTime? updatedAt,
  }) {
    return LabelTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      sheetConfig: sheetConfig ?? this.sheetConfig,
      stickerConfig: stickerConfig ?? this.stickerConfig,
      elements: elements ?? this.elements,
      isFinalized: isFinalized ?? this.isFinalized,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
