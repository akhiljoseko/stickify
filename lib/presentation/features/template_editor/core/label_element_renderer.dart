import 'package:flutter/widgets.dart';
import 'package:stickify/domain/domain.dart';

abstract interface class LabelElementRenderer {
  Widget render(BuildContext context, ElementBlueprint blueprint, {Product? product});
}
