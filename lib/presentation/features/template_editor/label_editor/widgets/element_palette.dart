import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_state.dart';

/// Sidebar palette displaying available label element types that can be dragged onto the canvas.
///
/// Contains preconfigured text fields, dynamic values, barcodes, and shapes.
class ElementPalette extends StatelessWidget {
  /// Creates an [ElementPalette] instance.
  const ElementPalette({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      width: 256,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Elements Palette',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildCategoryHeader(context, 'Product Details'),
                _buildDraggableTile(
                  context: context,
                  label: 'Product Name',
                  icon: Icons.title,
                  blueprint: () => TextElementBlueprint(
                    id: 'text-name-${DateTime.now().millisecondsSinceEpoch}',
                    x: 5,
                    y: 5,
                    width: 37.5,
                    height: 6,
                    rotation: 0,
                    content: '{{product.name}}',
                    isDynamic: true,
                    fontSize: 3.5,
                    fontWeightValue: 700,
                    textAlign: BlueprintTextAlign.left,
                    colorHex: 0xFF000000,
                  ),
                ),
                _buildDraggableTile(
                  context: context,
                  label: 'Product SKU',
                  icon: Icons.qr_code_2,
                  blueprint: () => TextElementBlueprint(
                    id: 'text-sku-${DateTime.now().millisecondsSinceEpoch}',
                    x: 5,
                    y: 12.5,
                    width: 30,
                    height: 5,
                    rotation: 0,
                    content: 'SKU: {{product.sku}}',
                    isDynamic: true,
                    fontSize: 3,
                    fontWeightValue: 400,
                    textAlign: BlueprintTextAlign.left,
                    colorHex: 0xFF555555,
                  ),
                ),
                _buildDraggableTile(
                  context: context,
                  label: 'Shelf Life',
                  icon: Icons.calendar_today,
                  blueprint: () => TextElementBlueprint(
                    id: 'text-shelflife-${DateTime.now().millisecondsSinceEpoch}',
                    x: 5,
                    y: 20,
                    width: 37.5,
                    height: 5,
                    rotation: 0,
                    content: 'Shelf Life: {{product.shelfLifeDays}} days',
                    isDynamic: true,
                    fontSize: 3,
                    fontWeightValue: 400,
                    textAlign: BlueprintTextAlign.left,
                    colorHex: 0xFF000000,
                  ),
                ),
                const SizedBox(height: 24),
                
                _buildCategoryHeader(context, 'General & Design'),
                _buildDraggableTile(
                  context: context,
                  label: 'Custom Text',
                  icon: Icons.text_fields,
                  blueprint: () => TextElementBlueprint(
                    id: 'text-custom-${DateTime.now().millisecondsSinceEpoch}',
                    x: 7.5,
                    y: 7.5,
                    width: 25,
                    height: 6,
                    rotation: 0,
                    content: 'Custom Text',
                    isDynamic: false,
                    fontSize: 3,
                    fontWeightValue: 400,
                    textAlign: BlueprintTextAlign.left,
                    colorHex: 0xFF000000,
                  ),
                ),
                _buildDraggableTile(
                  context: context,
                  label: 'Rectangle Shape',
                  icon: Icons.check_box_outline_blank,
                  blueprint: () => ShapeElementBlueprint(
                    id: 'shape-rect-${DateTime.now().millisecondsSinceEpoch}',
                    x: 10,
                    y: 10,
                    width: 25,
                    height: 15,
                    rotation: 0,
                    fillColorHex: 0x229E9E9E,
                    strokeColorHex: 0xFF000000,
                    strokeWidth: 0.5,
                    cornerRadius: 1,
                    isFilled: false,
                  ),
                ),
                _buildDraggableTile(
                  context: context,
                  label: 'Local Image',
                  icon: Icons.image_outlined,
                  blueprint: () => ImageElementBlueprint(
                    id: 'image-${DateTime.now().millisecondsSinceEpoch}',
                    x: 12.5,
                    y: 12.5,
                    width: 20,
                    height: 20,
                    rotation: 0,
                    fit: BlueprintBoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
 
                _buildCategoryHeader(context, 'Dynamic Codes'),
                _buildDraggableTile(
                  context: context,
                  label: '1D Barcode',
                  icon: Icons.line_weight,
                  blueprint: () => BarcodeElementBlueprint(
                    id: 'barcode-${DateTime.now().millisecondsSinceEpoch}',
                    x: 2.5,
                    y: 25,
                    width: 50,
                    height: 15,
                    rotation: 0,
                    data: '{{product.sku}}',
                    isDynamic: true,
                    barcodeType: BlueprintBarcodeType.code128,
                    showLabel: true,
                  ),
                ),
                _buildDraggableTile(
                  context: context,
                  label: 'QR Code',
                  icon: Icons.qr_code,
                  blueprint: () => QrElementBlueprint(
                    id: 'qr-${DateTime.now().millisecondsSinceEpoch}',
                    x: 10,
                    y: 10,
                    width: 25,
                    height: 25,
                    rotation: 0,
                    data: '{{product.sku}}',
                    isDynamic: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDraggableTile({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ElementBlueprint Function() blueprint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Draggable<ElementBlueprint>(
        data: blueprint(),
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.primary),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        childWhenDragging: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () {
            final editorState = context.read<EditorCubit>().state;
            var element = blueprint();
            if (editorState is EditorLoaded) {
              final stickerWidthMm = editorState.stickerConfig.widthMm;
              final stickerHeightMm = editorState.stickerConfig.heightMm;

              // Center the element on the sticker board
              final centerX = (stickerWidthMm / 2.0) - (element.width / 2.0);
              final centerY = (stickerHeightMm / 2.0) - (element.height / 2.0);

              // Clamp inside sticker boundaries
              final finalX = centerX.clamp(0.0, stickerWidthMm - element.width);
              final finalY = centerY.clamp(0.0, stickerHeightMm - element.height);

              element = element.copyWith(x: finalX, y: finalY);
            }
            context.read<EditorCubit>().addElement(element);

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(color: colorScheme.onSurface, fontSize: 13),
                ),
                const Spacer(),
                Icon(Icons.drag_indicator, size: 16, color: colorScheme.outlineVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
