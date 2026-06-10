import 'package:stickify/domain/entities/editor/element_blueprint.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/domain/entities/sheet_config.dart';
import 'package:stickify/domain/entities/sticker_config.dart';

abstract interface class TemplateRepository {
  Future<List<LabelTemplate>> fetchTemplates();
  Future<LabelTemplate> fetchTemplate(String id);
  Future<LabelTemplate> createTemplate(String name);
  Future<void> saveSheetConfig(String templateId, SheetConfig config);
  Future<void> saveStickerConfig(String templateId, StickerConfig config);
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements);
  Future<void> finalizeTemplate(String templateId);
  Future<void> deleteTemplate(String id);
}
