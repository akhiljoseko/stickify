import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/core/label_element_renderer.dart';

class ImageElementRenderer implements LabelElementRenderer {
  const ImageElementRenderer();

  @override
  Widget render(
    BuildContext context,
    ElementBlueprint blueprint, {
    Product? product,
    ProductVariant? variant,
  }) {
    final bp = blueprint as ImageElementBlueprint;

    final boxFit = switch (bp.fit) {
      BlueprintBoxFit.fill => BoxFit.fill,
      BlueprintBoxFit.contain => BoxFit.contain,
      BlueprintBoxFit.cover => BoxFit.cover,
      BlueprintBoxFit.fitWidth => BoxFit.fitWidth,
      BlueprintBoxFit.fitHeight => BoxFit.fitHeight,
      BlueprintBoxFit.none => BoxFit.none,
    };

    Widget imageWidget;

    if (bp.localFilePath != null && bp.localFilePath!.isNotEmpty) {
      final file = File(bp.localFilePath!);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          fit: boxFit,
          errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
        );
      } else {
        imageWidget = _buildErrorPlaceholder(message: 'File not found');
      }
    } else if (bp.networkUrl != null && bp.networkUrl!.isNotEmpty) {
      imageWidget = Image.network(
        bp.networkUrl!,
        fit: boxFit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else if (bp.assetPath != null && bp.assetPath!.isNotEmpty) {
      imageWidget = Image.asset(
        bp.assetPath!,
        fit: boxFit,
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      imageWidget = _buildPlaceholder();
    }

    return SizedBox(
      width: bp.width,
      height: bp.height,
      child: imageWidget,
    );
  }

  Widget _buildPlaceholder() {
    return ColoredBox(
      color: Colors.grey.shade300,
      child: const Center(
        child: Icon(Icons.image, color: Colors.grey, size: 24),
      ),
    );
  }

  Widget _buildErrorPlaceholder({String message = 'Error loading image'}) {
    return ColoredBox(
      color: Colors.red.shade50,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image, color: Colors.red, size: 20),
            const SizedBox(height: 2),
            Text(
              message,
              style: const TextStyle(fontSize: 8, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
