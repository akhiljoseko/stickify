import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/platform/file_picker_service.dart';
import 'package:stickify/core/utils/token_registry.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/bloc/editor_cubit.dart';

/// Sidebar panel displaying detailed configuration inputs for the selected canvas element.
///
/// Features shape dimensions adjustments, text formats, dynamic tokens insertion, etc.
class PropertiesPanel extends StatelessWidget {
  /// Creates a [PropertiesPanel] instance.
  const PropertiesPanel({
    required this.selectedElement,
    required this.onBack,
    required this.onNext,
    this.showNavigation = true,
    super.key,
  });

  /// The active selected element blueprint.
  final ElementBlueprint? selectedElement;

  /// Callback when user hits back button.
  final VoidCallback onBack;

  /// Callback when user hits next button.
  final VoidCallback onNext;

  /// Whether to show the navigation footer actions.
  final bool showNavigation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
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
                  : _buildPropertiesForm(
                      context,
                      selectedElement!,
                      textTheme,
                      colorScheme,
                    ),
            ),
          ),

          if (showNavigation) ...[
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
        ],
      ),
    );
  }

  Widget _buildNoSelectionPlaceholder(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
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
          bp.runtimeType
              .toString()
              .replaceAll('ElementBlueprint', '')
              .toUpperCase(),
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
                onChanged: (val) =>
                    cubit.updateElementProperty(bp.id, bp.copyWith(width: val)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RealTimeNumberField(
                label: 'Height',
                value: bp.height,
                onChanged: (val) => cubit.updateElementProperty(
                  bp.id,
                  bp.copyWith(height: val),
                ),
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
                onChanged: (val) =>
                    cubit.updateElementProperty(bp.id, bp.copyWith(x: val)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RealTimeNumberField(
                label: 'Y',
                value: bp.y,
                onChanged: (val) =>
                    cubit.updateElementProperty(bp.id, bp.copyWith(y: val)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        RealTimeNumberField(
          label: 'Rotation (deg)',
          value: bp.rotation,
          onChanged: (val) =>
              cubit.updateElementProperty(bp.id, bp.copyWith(rotation: val)),
        ),
        const SizedBox(height: 20),

        // Type-Specific Fields
        if (bp is TextElementBlueprint)
          TextPropertiesWidget(
            blueprint: bp,
            cubit: cubit,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        if (bp is BarcodeElementBlueprint)
          BarcodePropertiesWidget(
            blueprint: bp,
            cubit: cubit,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        if (bp is QrElementBlueprint)
          QrPropertiesWidget(
            blueprint: bp,
            cubit: cubit,
            textTheme: textTheme,
            colorScheme: colorScheme,
          ),
        if (bp is ImageElementBlueprint)
          ..._buildImageProperties(context, bp, textTheme, colorScheme),
        if (bp is ShapeElementBlueprint)
          ..._buildShapeProperties(context, bp, textTheme, colorScheme),

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

      ElevatedButton.icon(
        icon: const Icon(Icons.file_open),
        label: const Text('Pick Local Image'),
        onPressed: () async {
          final path = await context.read<FilePickerService>().pickImage();
          if (path != null) {
            cubit.updateElementProperty(
              bp.id,
              bp.copyWith(localFilePath: path),
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
          DropdownMenuItem(
            value: BlueprintBoxFit.contain,
            child: Text('Contain'),
          ),
          DropdownMenuItem(
            value: BlueprintBoxFit.cover,
            child: Text('Cover (Crop)'),
          ),
          DropdownMenuItem(
            value: BlueprintBoxFit.fill,
            child: Text('Fill / Stretch'),
          ),
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
      Text(
        'Corner Radius: ${bp.cornerRadius.toInt()} px',
        style: textTheme.bodySmall,
      ),
      Slider(
        max: 30,
        value: bp.cornerRadius,
        onChanged: (val) {
          cubit.updateElementProperty(bp.id, bp.copyWith(cornerRadius: val));
        },
      ),

      // Stroke width slider
      Text(
        'Stroke Width: ${bp.strokeWidth.toInt()} px',
        style: textTheme.bodySmall,
      ),
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

/// Input text field displaying coordinates or sizes that update in real time.
class RealTimeNumberField extends StatefulWidget {
  /// Creates a [RealTimeNumberField] instance.
  const RealTimeNumberField({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The label display text.
  final String label;

  /// The active double value.
  final double value;

  /// Callback when the value is updated.
  final ValueChanged<double> onChanged;

  @override
  State<RealTimeNumberField> createState() => _RealTimeNumberFieldState();
}

class _RealTimeNumberFieldState extends State<RealTimeNumberField> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toStringAsFixed(1));
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(RealTimeNumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      final currentVal = double.tryParse(_controller.text);
      if (currentVal != widget.value) {
        _controller.text = widget.value.toStringAsFixed(1);
      }
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _commitValue();
    }
  }

  void _commitValue() {
    final num = double.tryParse(_controller.text);
    if (num != null) {
      widget.onChanged(num);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onFieldSubmitted: (_) => _commitValue(),
    );
  }
}

/// Widget providing property configuration controls specific to text elements.
class TextPropertiesWidget extends StatefulWidget {
  /// Creates a [TextPropertiesWidget] instance.
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

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, token);
    _contentController.text = newText;

    _contentController.selection = TextSelection.collapsed(
      offset: start + token.length,
    );

    widget.cubit.updateElementProperty(
      widget.blueprint.id,
      widget.blueprint.copyWith(
        content: newText,
        isDynamic: true,
      ),
    );
  }

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
            labelText: 'Insert Dynamic Token',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          hint: const Text('Select token to insert'),
          items: tokenRegistry
              .where((t) => t.visibleInDropdown)
              .map((t) {
            return DropdownMenuItem<String>(
              value: t.token,
              child: Text('[${t.category}] ${t.displayName}'),
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
        Text(
          'Font Size: ${bp.fontSize.toInt()} px',
          style: widget.textTheme.bodySmall,
        ),
        Slider(
          min: 1,
          max: 72,
          value: bp.fontSize.clamp(1.0, 72.0),
          onChanged: (val) {
            final oldFontSize = bp.fontSize;
            final scale = val / oldFontSize;
            final newWidth = bp.width * scale;
            final newHeight = bp.maxLines * val * 1.3;
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(
                fontSize: val,
                width: newWidth,
                height: newHeight,
              ),
            );
          },
        ),

        // Max lines slider
        Text(
          'Max Lines: ${bp.maxLines}',
          style: widget.textTheme.bodySmall,
        ),
        Slider(
          min: 1,
          max: 10,
          divisions: 9,
          value: bp.maxLines.toDouble(),
          onChanged: (val) {
            final newMaxLines = val.toInt();
            final newHeight = newMaxLines * bp.fontSize * 1.3;
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(
                maxLines: newMaxLines,
                height: newHeight,
              ),
            );
          },
        ),

        // Letter spacing slider
        Text(
          'Letter Spacing: ${bp.letterSpacing.toStringAsFixed(1)}',
          style: widget.textTheme.bodySmall,
        ),
        Slider(
          min: -2,
          max: 10,
          value: bp.letterSpacing,
          onChanged: (val) {
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(letterSpacing: val),
            );
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
            widget.cubit.updateElementProperty(
              bp.id,
              bp.copyWith(textAlign: align),
            );
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
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
          boxShadow: isSelected
              ? [const BoxShadow(color: Colors.black26, blurRadius: 4)]
              : null,
        ),
      ),
    );
  }
}

/// Widget providing property configuration controls specific to barcode elements.
class BarcodePropertiesWidget extends StatefulWidget {
  /// Creates a [BarcodePropertiesWidget] instance.
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
  State<BarcodePropertiesWidget> createState() =>
      _BarcodePropertiesWidgetState();
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

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, token);
    _dataController.text = newText;
    _dataController.selection = TextSelection.collapsed(
      offset: start + token.length,
    );

    widget.cubit.updateElementProperty(
      widget.blueprint.id,
      widget.blueprint.copyWith(
        data: newText,
        isDynamic: true,
      ),
    );
  }

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
            labelText: 'Insert Dynamic Token',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          hint: const Text('Select token to insert'),
          items: tokenRegistry
              .where((t) => t.visibleInDropdown)
              .map((t) {
            return DropdownMenuItem<String>(
              value: t.token,
              child: Text('[${t.category}] ${t.displayName}'),
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
              widget.cubit.updateElementProperty(
                bp.id,
                bp.copyWith(barcodeType: val),
              );
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
                widget.cubit.updateElementProperty(
                  bp.id,
                  bp.copyWith(showLabel: val),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget providing property configuration controls specific to QR elements.
class QrPropertiesWidget extends StatefulWidget {
  /// Creates a [QrPropertiesWidget] instance.
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

    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;

    final newText = text.replaceRange(start, end, token);
    _dataController.text = newText;
    _dataController.selection = TextSelection.collapsed(
      offset: start + token.length,
    );

    widget.cubit.updateElementProperty(
      widget.blueprint.id,
      widget.blueprint.copyWith(
        data: newText,
        isDynamic: true,
      ),
    );
  }

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
            labelText: 'Insert Dynamic Token',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          ),
          hint: const Text('Select token to insert'),
          items: tokenRegistry
              .where((t) => t.visibleInDropdown)
              .map((t) {
            return DropdownMenuItem<String>(
              value: t.token,
              child: Text('[${t.category}] ${t.displayName}'),
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
