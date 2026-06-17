import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stickify/domain/domain.dart';

/// Grid card item displaying metadata and CRUD action buttons for a single template.
class TemplateCard extends StatefulWidget {
  /// Creates a [TemplateCard] instance.
  const TemplateCard({
    required this.template,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  /// The label template details.
  final LabelTemplate template;

  /// Callback when user selects the template for printing.
  final VoidCallback onSelect;

  /// Callback to edit the template.
  final VoidCallback onEdit;

  /// Callback to delete the template.
  final VoidCallback onDelete;

  @override
  State<TemplateCard> createState() => _TemplateCardState();
}

class _TemplateCardState extends State<TemplateCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final template = widget.template;
    final formattedDate = template.updatedAt != null
        ? DateFormat.yMMMd().add_jm().format(template.updatedAt!)
        : 'Never';

    // Renders a small thumbnail of the label based on sheet/sticker config
    final sizeDesc = template.stickerConfig != null
        ? '${template.stickerConfig!.widthMm.toStringAsFixed(1)} × ${template.stickerConfig!.heightMm.toStringAsFixed(1)} mm'
        : 'Unconfigured size';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? colorScheme.primary
                : colorScheme.outlineVariant,
            width: _isHovered ? 2.0 : 1.0,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail Area (3:2 aspect ratio)
            AspectRatio(
              aspectRatio: 3 / 2,
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(11),
                  ),
                ),
                padding: const EdgeInsets.all(12),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Container(
                    width: 120,
                    height: 80,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colorScheme.outlineVariant),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.picture_in_picture_alt_outlined,
                      color: colorScheme.primary.withValues(alpha: 0.5),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),

            // Info section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template.name,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sizeDesc,
                      style: textTheme.bodySmall?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Modified: $formattedDate',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),

                    // Action Buttons row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primaryContainer,
                              foregroundColor: colorScheme.onPrimaryContainer,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: widget.onSelect,
                            child: const Text('Select for Print'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') {
                              widget.onEdit();
                            } else if (val == 'delete') {
                              widget.onDelete();
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit_outlined, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit Template'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                                  const SizedBox(width: 8),
                                  Text('Delete Template', style: TextStyle(color: colorScheme.error)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
