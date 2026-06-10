import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';

//
// ignore: one_member_abstracts
abstract interface class LabelElementRenderer {
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
  });
}
