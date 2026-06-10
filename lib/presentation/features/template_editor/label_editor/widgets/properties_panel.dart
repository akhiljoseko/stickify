import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({
    required this.selectedElement,
    required this.onBack,
    required this.onNext,
    super.key,
  });

  final ElementBlueprint? selectedElement;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Properties',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: selectedElement == null
                  ? _buildNoSelectionPlaceholder(textTheme, colorScheme)
                  : _buildPropertiesForm(context, selectedElement!, textTheme, colorScheme),
            ),
          ),

          const Divider(height: 1),
          
          // Navigation Actions in Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Back'),
                ),
                ElevatedButton(
                  onPressed: onNext,
                  child: const Text('Next: Preview'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder(TextTheme textTheme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 64),
          Icon(
            Icons.info_outline,
            size: 48,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Element Selected',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select any element on the canvas to configure its properties.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outlineVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPropertiesForm(
    BuildContext context,
    ElementBlueprint bp,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<EditorCubit>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Type Label
        Text(
          bp.runtimeType.toString().replaceAll('ElementBlueprint', '').toUpperCase(),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Spatial Coordinates Inputs
        Text('Position & Size', style: textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: RealTimeNumberField(
                label: 'Width',
                value: bp.width,
                onChanged: (val) => cubit.updateElementProperty(bp.id, bp.copyWith(width: val)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RealTimeNumberField(
                label: 'Height',
                value: bp.height,
                onChanged: (val) => cubit.updateElementProperty(bp.id, bp.copyWith(height: val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: RealTimeNumberField(
                label: 'X',
                value: bp.x,
                onChanged: (val) => cubit.updateElementProperty(bp.id, bp.copyWith(x: val)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RealTimeNumberField(
                label: 'Y',
                value: bp.y,
                onChanged: (val) => cubit.updateElementProperty(bp.id, bp.copyWith(y: val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RealTimeNumberField(
          label: 'Rotation (deg)',
          value: bp.rotation,
          onChanged: (val) => cubit.updateElementProperty(bp.id, bp.copyWith(rotation: val)),
        ),
        const SizedBox(height: 20),

        // Type-Specific Fields
        if (bp is TextElementBlueprint) TextPropertiesWidget(blueprint: bp, cubit: cubit, textTheme: textTheme, colorScheme: colorScheme),
        if (bp is BarcodeElementBlueprint) BarcodePropertiesWidget(blueprint: bp, cubit: cubit, textTheme: textTheme, colorScheme: colorScheme),
        if (bp is QrElementBlueprint) QrPropertiesWidget(blueprint: bp, cubit: cubit, textTheme: textTheme, colorScheme: colorScheme),
        if (bp is ImageElementBlueprint) ..._buildImageProperties(context, bp, textTheme, colorScheme),
        if (bp is ShapeElementBlueprint) ..._buildShapeProperties(context, bp, textTheme, colorScheme),

        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 12),
        
        // Delete Action
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Element'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              elevation: 0,
            ),
            onPressed: () => cubit.deleteElement(bp.id),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildImageProperties(
    BuildContext context,
    ImageElementBlueprint bp,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<EditorCubit>();
    return [
      Text('Image Settings', style: textTheme.titleSmall),
      const SizedBox(height: 12),
      
      // Image source Picker (Local file picker)
      ElevatedButton.icon(
        icon: const Icon(Icons.file_open),
        label: const Text('Pick Local Image'),
        onPressed: () async {
          final picker = ImagePicker();
          final image = await picker.pickImage(source: ImageSource.gallery);
          if (image != null) {
            cubit.updateElementProperty(
              bp.id,
              bp.copyWith(localFilePath: image.path),
            );
          }
        },
      ),
      const SizedBox(height: 12),

      if (bp.localFilePath != null)
        Text(
          'Selected: ${bp.localFilePath!.split('/').last}',
          style: textTheme.bodySmall?.copyWith(color: Colors.green),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      const SizedBox(height: 12),

      DropdownButtonFormField<BlueprintBoxFit>(
        initialValue: bp.fit,
        decoration: const InputDecoration(
          labelText: 'Scale Mode',
          border: OutlineInputBorder(),
        ),
        items: const [
          DropdownMenuItem(value: BlueprintBoxFit.contain, child: Text('Contain')),
          DropdownMenuItem(value: BlueprintBoxFit.cover, child: Text('Cover (Crop)')),
          DropdownMenuItem(value: BlueprintBoxFit.fill, child: Text('Fill / Stretch')),
        ],
        onChanged: (val) {
          if (val != null) {
            cubit.updateElementProperty(bp.id, bp.copyWith(fit: val));
          }
        },
      ),
    ];
  }

  List<Widget> _buildShapeProperties(
    BuildContext context,
    ShapeElementBlueprint bp,
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    final cubit = context.read<EditorCubit>();
    return [
      Text('Shape Styling', style: textTheme.titleSmall),
      const SizedBox(height: 12),
      
      // Corner radius slider
      Text('Corner Radius: ${bp.cornerRadius.toInt()} px', style: textTheme.bodySmall),
      Slider(
        max: 30,
        value: bp.cornerRadius,
        onChanged: (val) {
          cubit.updateElementProperty(bp.id, bp.copyWith(cornerRadius: val));
        },
      ),

      // Stroke width slider
      Text('Stroke Width: ${bp.strokeWidth.toInt()} px', style: textTheme.bodySmall),
      Slider(
        max: 10,
        value: bp.strokeWidth,
        onChanged: (val) {
          cubit.updateElementProperty(bp.id, bp.copyWith(strokeWidth: val));
        },
      ),

      // Filled toggle
      Row(
        children: [
          const Text('Fill Color: ', style: TextStyle(fontSize: 12)),
          Switch(
            value: bp.isFilled,
            onChanged: (val) {
              cubit.updateElementProperty(bp.id, bp.copyWith(isFilled: val));
            },
          ),
        ],
      ),
    ];
  }
}

class RealTimeNumberField extends StatefulWidget {
  const RealTimeNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<RealTimeNumberField> createState() => _RealTimeNumberFieldState();
}

class _RealTimeNumberFieldState extends State<RealTimeNumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(RealTimeNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final currentVal = double.tryParse(_controller.text);
      if (currentVal != widget.value) {
        _controller.text = widget.value.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (val) {
        final num = double.tryParse(val);
        if (num != null) {
          widget.onChanged(num);
        }
      },
    );
  }
}

class TextPropertiesWidget extends StatefulWidget {
  const TextPropertiesWidget({
    required this.blueprint,
    required this.cubit,
    required this.textTheme,
    required this.colorScheme,
    super.key,
  });

  final TextElementBlueprint blueprint;
  final EditorCubit cubit;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  State<TextPropertiesWidget> createState() => _TextPropertiesWidgetState();
}

class _TextPropertiesWidgetState extends State<TextPropertiesWidget> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.blueprint.content);
  }

  @override
  void didUpdateWidget(TextPropertiesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blueprint.id != oldWidget.blueprint.id) {
      _contentController.text = widget.blueprint.content;
    } else if (widget.blueprint.content != _contentController.text) {
      _contentController.text = widget.blueprint.content;
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final text = _contentController.text;
    final selection = _contentController.selection;
    
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;
    
    final newText = text.replaceRange(start, end, token);
    _contentController.text = newText;
    
    _contentController.selection = TextSelection.collapsed(offset: start + token.length);
    
    widget.cubit.updateElementProperty(
      widget.blueprint.id,
      widget.blueprint.copyWith(
        content: newText,
        isDynamic: true,
      ),
    );
  }

  static const Map<String, String> _productFields = {
    'Product Name': '{{product.name}}',
    'SKU Code': '{{product.sku}}',
    'Product ID': '{{product.id}}',
    'Category': '{{product.category}}',
    'Total Prints': '{{product.totalPrints}}',
    'Last Printed': '{{product.lastPrintedAt}}',
    'Assigned Station': '{{product.assignedStation}}',
    'Shelf Life (Days)': '{{product.shelfLifeDays}}',
    'Storage Conditions': '{{product.storageConditions}}',
  };

  @override
  Widget build(BuildContext context) {
    final bp = widget.blueprint;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Text Formatting', style: widget.textTheme.titleSmall),
        const SizedBox(height: 12),
        
        TextFormField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Content / Token',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(
                content: val,
                isDynamic: val.contains('{{'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // User-friendly Field Injector Dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Insert Product Field',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          value: null,
          hint: const Text('Select field to insert'),
          items: _productFields.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
          onChanged: (token) {
            if (token != null) {
              _insertToken(token);
            }
          },
        ),
        const SizedBox(height: 16),

        // Font size slider
        Text('Font Size: ${bp.fontSize.toInt()} px', style: widget.textTheme.bodySmall),
        Slider(
          min: 6,
          max: 72,
          value: bp.fontSize,
          onChanged: (val) {
            widget.cubit.updateElementProperty(bp.id, bp.copyWith(fontSize: val));
          },
        ),

        // Letter spacing slider
        Text('Letter Spacing: ${bp.letterSpacing.toStringAsFixed(1)}', style: widget.textTheme.bodySmall),
        Slider(
          min: -2,
          max: 10,
          value: bp.letterSpacing,
          onChanged: (val) {
            widget.cubit.updateElementProperty(bp.id, bp.copyWith(letterSpacing: val));
          },
        ),

        // Font weight toggle (Regular vs Bold)
        Row(
          children: [
            const Text('Bold Font: ', style: TextStyle(fontSize: 12)),
            Switch(
              value: bp.fontWeightValue >= 700,
              onChanged: (isBold) {
                widget.cubit.updateElementProperty(
                  bp.id,
                  bp.copyWith(fontWeightValue: isBold ? 700 : 400),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 8),
        // Text Align toggle
        Text('Alignment', style: widget.textTheme.bodySmall),
        const SizedBox(height: 8),
        ToggleButtons(
          isSelected: [
            bp.textAlign == BlueprintTextAlign.left,
            bp.textAlign == BlueprintTextAlign.center,
            bp.textAlign == BlueprintTextAlign.right,
          ],
          onPressed: (index) {
            final align = switch (index) {
              0 => BlueprintTextAlign.left,
              1 => BlueprintTextAlign.center,
              2 => BlueprintTextAlign.right,
              _ => BlueprintTextAlign.left,
            };
            widget.cubit.updateElementProperty(bp.id, bp.copyWith(textAlign: align));
          },
          children: const [
            Icon(Icons.format_align_left, size: 18),
            Icon(Icons.format_align_center, size: 18),
            Icon(Icons.format_align_right, size: 18),
          ],
        ),
        const SizedBox(height: 16),

        // Basic Color Swatches
        Text('Color Swatch', style: widget.textTheme.bodySmall),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildColorSwatch(0xFF000000, Colors.black),
            _buildColorSwatch(0xFFFF0000, Colors.red),
            _buildColorSwatch(0xFF2196F3, Colors.blue),
            _buildColorSwatch(0xFF4CAF50, Colors.green),
            _buildColorSwatch(0xFFFF9800, Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildColorSwatch(int hex, Color color) {
    final bp = widget.blueprint;
    final isSelected = bp.colorHex == hex;
    return GestureDetector(
      onTap: () {
        widget.cubit.updateElementProperty(
          bp.id,
          bp.copyWith(colorHex: hex),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 2)
              : null,
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}

class BarcodePropertiesWidget extends StatefulWidget {
  const BarcodePropertiesWidget({
    required this.blueprint,
    required this.cubit,
    required this.textTheme,
    required this.colorScheme,
    super.key,
  });

  final BarcodeElementBlueprint blueprint;
  final EditorCubit cubit;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  State<BarcodePropertiesWidget> createState() => _BarcodePropertiesWidgetState();
}

class _BarcodePropertiesWidgetState extends State<BarcodePropertiesWidget> {
  late TextEditingController _dataController;

  @override
  void initState() {
    super.initState();
    _dataController = TextEditingController(text: widget.blueprint.data);
  }

  @override
  void didUpdateWidget(BarcodePropertiesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blueprint.id != oldWidget.blueprint.id) {
      _dataController.text = widget.blueprint.data;
    } else if (widget.blueprint.data != _dataController.text) {
      _dataController.text = widget.blueprint.data;
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final text = _dataController.text;
    final selection = _dataController.selection;
    
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;
    
    final newText = text.replaceRange(start, end, token);
    _dataController.text = newText;
    _dataController.selection = TextSelection.collapsed(offset: start + token.length);
    
    widget.cubit.updateElementProperty(
      widget.blueprint.id,
      widget.blueprint.copyWith(
        data: newText,
        isDynamic: true,
      ),
    );
  }

  static const Map<String, String> _productFields = {
    'Product Name': '{{product.name}}',
    'SKU Code': '{{product.sku}}',
    'Product ID': '{{product.id}}',
    'Category': '{{product.category}}',
    'Total Prints': '{{product.totalPrints}}',
    'Last Printed': '{{product.lastPrintedAt}}',
    'Assigned Station': '{{product.assignedStation}}',
    'Shelf Life (Days)': '{{product.shelfLifeDays}}',
    'Storage Conditions': '{{product.storageConditions}}',
  };

  @override
  Widget build(BuildContext context) {
    final bp = widget.blueprint;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Barcode Settings', style: widget.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dataController,
          decoration: const InputDecoration(
            labelText: 'Barcode Data / Token',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(
                data: val,
                isDynamic: val.contains('{{'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // User-friendly Field Injector Dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Insert Product Field',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          value: null,
          hint: const Text('Select field to insert'),
          items: _productFields.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
          onChanged: (token) {
            if (token != null) {
              _insertToken(token);
            }
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<BlueprintBarcodeType>(
          initialValue: bp.barcodeType,
          decoration: const InputDecoration(
            labelText: 'Symbology',
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: BlueprintBarcodeType.code128,
              child: Text('Code 128 (1D)'),
            ),
            DropdownMenuItem(
              value: BlueprintBarcodeType.ean13,
              child: Text('EAN 13 (Retail)'),
            ),
          ],
          onChanged: (val) {
            if (val != null) {
              widget.cubit.updateElementProperty(bp.id, bp.copyWith(barcodeType: val));
            }
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Show Text Label', style: TextStyle(fontSize: 12)),
            Switch(
              value: bp.showLabel,
              onChanged: (val) {
                widget.cubit.updateElementProperty(bp.id, bp.copyWith(showLabel: val));
              },
            ),
          ],
        ),
      ],
    );
  }
}

class QrPropertiesWidget extends StatefulWidget {
  const QrPropertiesWidget({
    required this.blueprint,
    required this.cubit,
    required this.textTheme,
    required this.colorScheme,
    super.key,
  });

  final QrElementBlueprint blueprint;
  final EditorCubit cubit;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  State<QrPropertiesWidget> createState() => _QrPropertiesWidgetState();
}

class _QrPropertiesWidgetState extends State<QrPropertiesWidget> {
  late TextEditingController _dataController;

  @override
  void initState() {
    super.initState();
    _dataController = TextEditingController(text: widget.blueprint.data);
  }

  @override
  void didUpdateWidget(QrPropertiesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blueprint.id != oldWidget.blueprint.id) {
      _dataController.text = widget.blueprint.data;
    } else if (widget.blueprint.data != _dataController.text) {
      _dataController.text = widget.blueprint.data;
    }
  }

  @override
  void dispose() {
    _dataController.dispose();
    super.dispose();
  }

  void _insertToken(String token) {
    final text = _dataController.text;
    final selection = _dataController.selection;
    
    final int start = selection.isValid ? selection.start : text.length;
    final int end = selection.isValid ? selection.end : text.length;
    
    final newText = text.replaceRange(start, end, token);
    _dataController.text = newText;
    _dataController.selection = TextSelection.collapsed(offset: start + token.length);
    
    widget.cubit.updateElementProperty(
      widget.blueprint.id,
      widget.blueprint.copyWith(
        data: newText,
        isDynamic: true,
      ),
    );
  }

  static const Map<String, String> _productFields = {
    'Product Name': '{{product.name}}',
    'SKU Code': '{{product.sku}}',
    'Product ID': '{{product.id}}',
    'Category': '{{product.category}}',
    'Total Prints': '{{product.totalPrints}}',
    'Last Printed': '{{product.lastPrintedAt}}',
    'Assigned Station': '{{product.assignedStation}}',
    'Shelf Life (Days)': '{{product.shelfLifeDays}}',
    'Storage Conditions': '{{product.storageConditions}}',
  };

  @override
  Widget build(BuildContext context) {
    final bp = widget.blueprint;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('QR Code Settings', style: widget.textTheme.titleSmall),
        const SizedBox(height: 12),
        TextFormField(
          controller: _dataController,
          decoration: const InputDecoration(
            labelText: 'QR Data / URL Token',
            border: OutlineInputBorder(),
          ),
          onChanged: (val) {
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(
                data: val,
                isDynamic: val.contains('{{'),
              ),
            );
          },
        ),
        const SizedBox(height: 8),

        // User-friendly Field Injector Dropdown
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Insert Product Field',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          value: null,
          hint: const Text('Select field to insert'),
          items: _productFields.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.value,
              child: Text(entry.key),
            );
          }).toList(),
          onChanged: (token) {
            if (token != null) {
              _insertToken(token);
            }
          },
        ),
      ],
    );
  }
}
