import 'package:stickify/core/services/pdf/pdf_element_renderer.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderers.dart';
import 'package:stickify/domain/domain.dart';

/// Registry mapping [ElementBlueprint] types to their corresponding [PdfElementRenderer] Strategy.
class PdfElementRendererRegistry {
  static final Map<Type, PdfElementRenderer> _renderers = {
    TextElementBlueprint: const PdfTextElementRenderer(),
    ShapeElementBlueprint: const PdfShapeElementRenderer(),
    BarcodeElementBlueprint: const PdfBarcodeElementRenderer(),
    QrElementBlueprint: const PdfQrElementRenderer(),
    ImageElementBlueprint: const PdfImageElementRenderer(),
  };

  /// Returns the concrete [PdfElementRenderer] strategy corresponding to the type of [blueprint].
  static PdfElementRenderer<T> getRenderer<T extends ElementBlueprint>(T blueprint) {
    final renderer = _renderers[blueprint.runtimeType];
    if (renderer == null) {
      throw Exception('No PDF renderer found for ${blueprint.runtimeType}');
    }
    return renderer as PdfElementRenderer<T>;
  }
}
