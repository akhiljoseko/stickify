// The LabelElementRenderer strategy contract defines a single render method.
// ignore_for_file: one_member_abstracts
import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';

/// Interface defining a strategy contract to render an [ElementBlueprint] on the UI canvas.
abstract interface class LabelElementRenderer {
  /// Renders the given layout [blueprint] widget.
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
    DateTime? manufacturingDate,
  });
}
