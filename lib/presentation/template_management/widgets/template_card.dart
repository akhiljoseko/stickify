import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/widgets/widgets.dart';

/// Grid card item displaying metadata and CRUD action buttons for a single template.
class TemplateCard extends StatefulWidget {
  /// Creates a [TemplateCard] instance.
  const TemplateCard({
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onEditDetails,
    super.key,
  });

  /// The label template details.
  final LabelTemplate template;

  /// Callback to edit the template.
  final VoidCallback onEdit;

  /// Callback to delete the template.
  final VoidCallback onDelete;

  /// Callback to edit the template details.
  final VoidCallback onEditDetails;

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
                padding: template.imageUrl != null && template.imageUrl!.isNotEmpty
                    ? EdgeInsets.zero
                    : const EdgeInsets.all(12),
                child: template.imageUrl != null && template.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
                        child: AppImage(
                          imageUrl: template.imageUrl,
                          placeholderIcon: Icons.picture_in_picture_alt_outlined,
                          width: double.infinity,
                          height: double.infinity,
                          borderRadius: 0,
                          iconSize: 32,
                        ),
                      )
                    : FittedBox(
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
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (val) {
                            if (val == 'edit') {
                              widget.onEdit();
                            } else if (val == 'edit_details') {
                              widget.onEditDetails();
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
                            const PopupMenuItem(
                              value: 'edit_details',
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit Details'),
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
