import 'package:stickify/core/services/pdf/pdf_element_renderer.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderers.dart';
import 'package:stickify/domain/domain.dart';

/// Registry mapping [ElementBlueprint] types to their corresponding [PdfElementRenderer] Strategy.
class PdfElementRendererRegistry {
  PdfElementRendererRegistry._();

  static final Map<Type, PdfElementRenderer> _renderers = {};

  /// Registers a custom [PdfElementRenderer] for [ElementBlueprint] subclass [T].
  static void register<T extends ElementBlueprint>(PdfElementRenderer<T> renderer) {
    _renderers[T] = renderer;
  }

  /// Registers the default system renderers.
  static void registerDefaults() {
    register<TextElementBlueprint>(const PdfTextElementRenderer());
    register<ShapeElementBlueprint>(const PdfShapeElementRenderer());
    register<BarcodeElementBlueprint>(const PdfBarcodeElementRenderer());
    register<QrElementBlueprint>(const PdfQrElementRenderer());
    register<ImageElementBlueprint>(const PdfImageElementRenderer());
  }

  /// Returns the concrete [PdfElementRenderer] strategy corresponding to the type of [blueprint].
  static PdfElementRenderer<T> getRenderer<T extends ElementBlueprint>(T blueprint) {
    final renderer = _renderers[blueprint.runtimeType];
    if (renderer == null) {
      throw Exception('No PDF renderer found for ${blueprint.runtimeType}');
    }
    return renderer as PdfElementRenderer<T>;
  }
}
