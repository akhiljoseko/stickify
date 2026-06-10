// The Strategy pattern relies on classes implementing a single rendering method.
// ignore_for_file: one_member_abstracts

import 'dart:typed_data';
import 'package:pdf/widgets.dart' as pw;
import 'package:stickify/domain/domain.dart';

/// Strategy interface for rendering a dynamic [ElementBlueprint] into a PDF [pw.Widget].
abstract interface class PdfElementRenderer<T extends ElementBlueprint> {
  /// Renders the given [blueprint] to a PDF widget.
  pw.Widget render(
    T blueprint,
    Product? product,
    ProductVariant? variant,
    Map<String, Uint8List> imageCache,
  );
}
