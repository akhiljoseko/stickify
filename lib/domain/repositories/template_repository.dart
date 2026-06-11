import 'package:stickify/domain/entities/editor/element_blueprint.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/domain/entities/sheet_config.dart';
import 'package:stickify/domain/entities/sticker_config.dart';

/// Repository contract for managing label templates and their configurations.
abstract interface class TemplateRepository {
  /// Fetches all stored label templates.
  Future<List<LabelTemplate>> fetchTemplates();

  /// Fetches a specific template by its [id].
  Future<LabelTemplate> fetchTemplate(String id);

  /// Creates a new label template with the given [name].
  Future<LabelTemplate> createTemplate(String name);

  /// Saves the paper sheet layout configuration for the template specified by [templateId].
  Future<void> saveSheetConfig(String templateId, SheetConfig config);

  /// Saves the individual sticker dimensions/outlines for the template specified by [templateId].
  Future<void> saveStickerConfig(String templateId, StickerConfig config);

  /// Saves the active layout elements (text, barcodes, shapes) for the template specified by [templateId].
  Future<void> saveElements(String templateId, List<ElementBlueprint> elements);

  /// Finalizes the template specified by [templateId], marking it ready for printing.
  Future<void> finalizeTemplate(String templateId);

  /// Saves the complete state of a template.
  Future<void> saveTemplate(LabelTemplate template);

  /// Deletes the template matching the given [id].
  Future<void> deleteTemplate(String id);
}
