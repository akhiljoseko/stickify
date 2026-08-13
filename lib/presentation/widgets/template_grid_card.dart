import 'dart:io';
import 'package:flutter/material.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/domain/entities/sheet_config.dart';

/// A shared visual grid card for selecting a [LabelTemplate].
///
/// Displays a scaled preview of the sticker sheet layout (or image),
/// the primary template name, grid size, and total stickers/sheet.
class TemplateGridCard extends StatelessWidget {
  /// Creates a [TemplateGridCard].
  const TemplateGridCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
    this.onDoubleTap,
    super.key,
  });

  /// The label template associated with this card.
  final LabelTemplate template;

  /// Whether this template is currently selected.
  final bool isSelected;

  /// Callback triggered on single tap.
  final VoidCallback onTap;

  /// Optional callback triggered on double tap.
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cols = template.sheetConfig?.columns ?? 0;
    final rows = template.sheetConfig?.rows ?? 0;
    final total = cols * rows;

    final gridSizeText = cols > 0 && rows > 0 ? '$cols × $rows Grid' : 'Custom Grid';
    final stickersPerSheetText = total > 0 ? '$total Stickers / Sheet' : 'Custom Sheet';

    final borderColor = isSelected
        ? colorScheme.primary
        : colorScheme.outlineVariant.withValues(alpha: 0.5);
    final backgroundColor = isSelected
        ? colorScheme.primaryContainer.withValues(alpha: 0.25)
        : colorScheme.surfaceContainerLowest;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: ColoredBox(
                          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.4),
                          child: _buildImageOrPreview(colorScheme),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Line 1: Name
                    Text(
                      template.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 3),
                    // Line 2: Grid Size
                    Text(
                      gridSizeText,
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    // Line 3: Sticker/Sheet Count
                    Text(
                      stickersPerSheetText,
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.primary.withValues(alpha: 0.85)
                            : colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: colorScheme.primary,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageOrPreview(ColorScheme colorScheme) {
    final imageUrl = template.imageUrl;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      final uri = Uri.tryParse(imageUrl);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _MiniSheetPreview(sheetConfig: template.sheetConfig),
        );
      } else {
        final file = File(imageUrl);
        if (file.existsSync()) {
          return Image.file(
            file,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _MiniSheetPreview(sheetConfig: template.sheetConfig),
          );
        }
      }
    }

    return _MiniSheetPreview(sheetConfig: template.sheetConfig);
  }
}

class _MiniSheetPreview extends StatelessWidget {
  const _MiniSheetPreview({this.sheetConfig});

  final SheetConfig? sheetConfig;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final cols = sheetConfig?.columns ?? 3;
    final rows = sheetConfig?.rows ?? 5;

    final aspectRatio = (sheetConfig != null && sheetConfig!.pageHeight > 0)
        ? (sheetConfig!.pageWidth / sheetConfig!.pageHeight)
        : 0.707;

    return Center(
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              crossAxisSpacing: 3,
              mainAxisSpacing: 3,
            ),
            itemCount: cols * rows,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
