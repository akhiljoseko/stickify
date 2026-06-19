import 'package:flutter/material.dart';
import 'package:stickify/core/utils/image_utils.dart';

/// A reusable image widget that displays local files or network URLs,
/// falling back to a structured placeholder container when empty.
class AppImage extends StatelessWidget {
  /// Creates an [AppImage] instance.
  const AppImage({
    required this.imageUrl,
    required this.placeholderIcon,
    this.width,
    this.height,
    this.borderRadius = 6.0,
    this.iconSize,
    super.key,
  });

  /// The local file path or network URL of the image.
  final String? imageUrl;

  /// The icon to display when the image is empty or null.
  final IconData placeholderIcon;

  /// The width of the image container.
  final double? width;

  /// The height of the image container.
  final double? height;

  /// The border radius of the image container.
  final double borderRadius;

  /// The size of the placeholder icon.
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: colorScheme.surfaceContainerLow,
        border: Border.all(color: colorScheme.outlineVariant, width: 0.5),
        image: hasImage
            ? DecorationImage(
                image: resolveImageProvider(imageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: !hasImage
          ? Icon(
              placeholderIcon,
              size: iconSize,
              color: colorScheme.primary.withValues(alpha: 0.7),
            )
          : null,
    );
  }
}
