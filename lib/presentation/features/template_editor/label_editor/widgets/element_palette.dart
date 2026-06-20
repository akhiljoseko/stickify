import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_state.dart';
import 'package:uuid/uuid.dart';

/// Sidebar or bottom toolbar palette displaying available label element types that can be added onto the canvas.
///
/// Supports vertical category list for desktop and horizontally scrollable photo-editor-style strip for mobile.
class ElementPalette extends StatelessWidget {
  /// Creates an [ElementPalette] instance.
  const ElementPalette({this.isHorizontal = false, super.key});

  /// If true, renders as a horizontally scrollable bar suited for mobile footers.
  final bool isHorizontal;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final items = [
      _PaletteItemData(
        label: 'Product Name',
        shortLabel: 'Name',
        icon: Icons.title,
        blueprint: () => TextElementBlueprint(
          id: 'text-name-${const Uuid().v4()}',
          x: 5,
          y: 5,
          width: 37.5,
          height: 6,
          rotation: 0,
          content: '{{product.name}}',
          isDynamic: true,
          fontSize: 3.5,
          fontWeightValue: 700,
          textAlign: BlueprintTextAlign.center,
          colorHex: 0xFF000000,
        ),
      ),
      _PaletteItemData(
        label: 'Product SKU',
        shortLabel: 'SKU',
        icon: Icons.qr_code_2,
        blueprint: () => TextElementBlueprint(
          id: 'text-sku-${const Uuid().v4()}',
          x: 5,
          y: 12.5,
          width: 30,
          height: 5,
          rotation: 0,
          content: 'SKU: {{product.sku}}',
          isDynamic: true,
          fontSize: 3,
          fontWeightValue: 400,
          textAlign: BlueprintTextAlign.center,
          colorHex: 0xFF555555,
        ),
      ),
      _PaletteItemData(
        label: 'Shelf Life',
        shortLabel: 'Shelf Life',
        icon: Icons.calendar_today,
        blueprint: () => TextElementBlueprint(
          id: 'text-shelflife-${const Uuid().v4()}',
          x: 5,
          y: 20,
          width: 37.5,
          height: 5,
          rotation: 0,
          content: 'Shelf Life: {{product.shelfLifeDays}} days',
          isDynamic: true,
          fontSize: 3,
          fontWeightValue: 400,
          textAlign: BlueprintTextAlign.center,
          colorHex: 0xFF000000,
        ),
      ),
      _PaletteItemData(
        label: 'MFG Date',
        shortLabel: 'MFG Date',
        icon: Icons.date_range,
        blueprint: () => TextElementBlueprint(
          id: 'text-mfg-${const Uuid().v4()}',
          x: 5,
          y: 27.5,
          width: 30,
          height: 5,
          rotation: 0,
          content: 'MFG: {{product.mfgDate}}',
          isDynamic: true,
          fontSize: 3,
          fontWeightValue: 400,
          textAlign: BlueprintTextAlign.center,
          colorHex: 0xFF000000,
        ),
      ),
      _PaletteItemData(
        label: 'Nutrition Facts',
        shortLabel: 'Nutrition',
        icon: Icons.description_outlined,
        blueprint: () => NutritionTableElementBlueprint(
          id: 'nutrition-table-${const Uuid().v4()}',
          x: 5,
          y: 5,
          width: 30,
          height: 40,
          rotation: 0,
          colorHex: 0xFF000000,
        ),
      ),
      _PaletteItemData(
        label: 'Custom Text',
        shortLabel: 'Text',
        icon: Icons.text_fields,
        blueprint: () => TextElementBlueprint(
          id: 'text-custom-${const Uuid().v4()}',
          x: 7.5,
          y: 7.5,
          width: 25,
          height: 6,
          rotation: 0,
          content: 'Custom Text',
          isDynamic: false,
          fontSize: 3,
          fontWeightValue: 400,
          textAlign: BlueprintTextAlign.center,
          colorHex: 0xFF000000,
        ),
      ),
      _PaletteItemData(
        label: 'Rectangle Shape',
        shortLabel: 'Shape',
        icon: Icons.check_box_outline_blank,
        blueprint: () => ShapeElementBlueprint(
          id: 'shape-rect-${const Uuid().v4()}',
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
      _PaletteItemData(
        label: 'Local Image',
        shortLabel: 'Image',
        icon: Icons.image_outlined,
        blueprint: () => ImageElementBlueprint(
          id: 'image-${const Uuid().v4()}',
          x: 12.5,
          y: 12.5,
          width: 20,
          height: 20,
          rotation: 0,
          fit: BlueprintBoxFit.contain,
        ),
      ),
      _PaletteItemData(
        label: '1D Barcode',
        shortLabel: 'Barcode',
        icon: Icons.line_weight,
        blueprint: () => BarcodeElementBlueprint(
          id: 'barcode-${const Uuid().v4()}',
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
      _PaletteItemData(
        label: 'QR Code',
        shortLabel: 'QR Code',
        icon: Icons.qr_code,
        blueprint: () => QrElementBlueprint(
          id: 'qr-${const Uuid().v4()}',
          x: 10,
          y: 10,
          width: 25,
          height: 25,
          rotation: 0,
          data: '{{product.sku}}',
          isDynamic: true,
        ),
      ),
    ];

    if (isHorizontal) {
      return Container(
        height: 84,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          border: Border(
            top: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildHorizontalTile(context, item);
          },
        ),
      );
    }

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
                ...items.take(5).map((item) => _buildDraggableTile(context, item)),
                const SizedBox(height: 24),
                _buildCategoryHeader(context, 'General & Design'),
                ...items.skip(5).take(3).map((item) => _buildDraggableTile(context, item)),
                const SizedBox(height: 24),
                _buildCategoryHeader(context, 'Dynamic Codes'),
                ...items.skip(8).map((item) => _buildDraggableTile(context, item)),
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

  Widget _buildHorizontalTile(BuildContext context, _PaletteItemData item) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleItemSelection(context, item.blueprint),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 68,
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
            color: colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, size: 20, color: colorScheme.primary),
              const SizedBox(height: 4),
              Text(
                item.shortLabel,
                style: textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableTile(BuildContext context, _PaletteItemData item) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Draggable<ElementBlueprint>(
        data: item.blueprint(),
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
                Icon(item.icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  item.label,
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
              Icon(item.icon, size: 18, color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
              const SizedBox(width: 8),
              Text(
                item.label,
                style: TextStyle(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4), fontSize: 13),
              ),
            ],
          ),
        ),
        child: GestureDetector(
          onTap: () => _handleItemSelection(context, item.blueprint),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 18, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  item.label,
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

  void _handleItemSelection(BuildContext context, ElementBlueprint Function() blueprint) {
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
  }
}

class _PaletteItemData {
  const _PaletteItemData({
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.blueprint,
  });

  final String label;
  final String shortLabel;
  final IconData icon;
  final ElementBlueprint Function() blueprint;
}
