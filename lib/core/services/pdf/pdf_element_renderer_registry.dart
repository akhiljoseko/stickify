import 'package:stickify/core/services/pdf/pdf_element_renderer.dart';
import 'package:stickify/core/services/pdf/pdf_element_renderers.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart' show LabelPdfLayoutEngine;
import 'package:stickify/domain/domain.dart';

/// Registry mapping [ElementBlueprint] types to their corresponding [PdfElementRenderer] Strategy.
///
/// ## ⚠️ Isolate Caveat (Static State)
///
/// Dart static state is **per-isolate**, not shared across isolates.
/// This registry uses a `static final` map, so a background isolate
/// spawned via `Isolate.run(...)` starts with an **empty** map.
///
/// ## Current Usage
///
/// The registry is used exclusively in
/// [LabelPdfLayoutEngine._buildPdfDocumentInBackground] (see
/// `lib/core/services/printing/label_pdf_layout_engine.dart`).
/// That method calls [registerDefaults] at its top **on every invocation**
/// — whether running on the main thread or inside a background isolate —
/// so renderers are always available at the point of use.
///
/// ## If You Add a New Caller
///
/// If you call [getRenderer] from somewhere **other than**
/// `_buildPdfDocumentInBackground`, you **must** ensure
/// [registerDefaults] (or individual [register] calls) has been
/// invoked **in the same isolate** before the first [getRenderer]
/// call. Failing to do so will throw an `Exception`.
///
/// Adding a `registerDefaults()` call at the top of the new entry
/// point (just like `_buildPdfDocumentInBackground` does) is the
/// simplest and safest approach.
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
