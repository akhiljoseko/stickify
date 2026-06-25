import 'package:flutter/material.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

class TrayConfigurationSheet extends StatefulWidget {
  const TrayConfigurationSheet({
    this.existingTray,
    this.availableTemplates = const [],
    this.selectedTemplateIds = const {},
    super.key,
  });

  final PrinterTrayProfile? existingTray;
  final List<LabelTemplate> availableTemplates;
  final Set<String> selectedTemplateIds;

  static Future<PrinterTrayProfile?> show({
    required BuildContext context,
    PrinterTrayProfile? existingTray,
    List<LabelTemplate> availableTemplates = const [],
    Set<String> selectedTemplateIds = const {},
  }) {
    return showAdaptiveSheet<PrinterTrayProfile>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrayConfigurationSheet(
        existingTray: existingTray,
        availableTemplates: availableTemplates,
        selectedTemplateIds: selectedTemplateIds,
      ),
    );
  }

  @override
  State<TrayConfigurationSheet> createState() => _TrayConfigurationSheetState();
}

class _TrayConfigurationSheetState extends State<TrayConfigurationSheet> {
  late final TextEditingController _trayNameController;
  late final TextEditingController _trayIdentifierController;
  late final TextEditingController _marginTopController;
  late final TextEditingController _marginBottomController;
  late final TextEditingController _marginLeftController;
  late final TextEditingController _marginRightController;
  late Set<String> _selectedTemplateIds;

  @override
  void initState() {
    super.initState();
    _trayNameController = TextEditingController(
      text: widget.existingTray?.displayName ?? '',
    );
    _trayIdentifierController = TextEditingController(
      text: widget.existingTray?.trayIdentifier ?? '',
    );
    _marginTopController = TextEditingController(text: '0.0');
    _marginBottomController = TextEditingController(text: '0.0');
    _marginLeftController = TextEditingController(text: '0.0');
    _marginRightController = TextEditingController(text: '0.0');
    _selectedTemplateIds = Set.from(widget.selectedTemplateIds);
  }

  @override
  void dispose() {
    _trayNameController.dispose();
    _trayIdentifierController.dispose();
    _marginTopController.dispose();
    _marginBottomController.dispose();
    _marginLeftController.dispose();
    _marginRightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existingTray != null
                          ? 'Edit Tray'
                          : 'Add Tray',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Tray Information',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _trayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Tray Name',
                      hintText: 'e.g. Main Feed Tray',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.label),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _trayIdentifierController,
                    decoration: const InputDecoration(
                      labelText: 'Tray Identifier',
                      hintText: 'e.g. tray_1',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.terminal),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Supported Templates',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select which label templates this tray can print.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.availableTemplates.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No templates available. Create templates first, then assign them to this tray.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...widget.availableTemplates.map((template) {
                      final isSelected =
                          _selectedTemplateIds.contains(template.id);
                      return CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(
                          template.name,
                          style: textTheme.bodyMedium,
                        ),
                        subtitle: template.sheetConfig != null
                            ? Text(
                                '${template.sheetConfig!.pageWidth} × ${template.sheetConfig!.pageHeight} mm',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              )
                            : null,
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedTemplateIds.add(template.id);
                            } else {
                              _selectedTemplateIds.remove(template.id);
                            }
                          });
                        },
                      );
                    }),
                  const SizedBox(height: 32),
                  Text(
                    'Hardware Printable Area',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set the non-printable margin offsets for this tray.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _marginTopController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Top (mm)',
                            border: OutlineInputBorder(),
                            suffixText: 'mm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _marginBottomController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Bottom (mm)',
                            border: OutlineInputBorder(),
                            suffixText: 'mm',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _marginLeftController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Left (mm)',
                            border: OutlineInputBorder(),
                            suffixText: 'mm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _marginRightController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Right (mm)',
                            border: OutlineInputBorder(),
                            suffixText: 'mm',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                  child: Text(
                    widget.existingTray != null
                        ? 'Update Tray'
                        : 'Add Tray',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSave() {
    final name = _trayNameController.text.trim();
    final identifier = _trayIdentifierController.text.trim();

    if (name.isEmpty || identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tray name and identifier are required.'),
        ),
      );
      return;
    }

    final supportedConfigs = widget.availableTemplates
        .where((t) => _selectedTemplateIds.contains(t.id))
        .map(
          (t) => PaperConfigurationReference(id: t.id, displayName: t.name),
        )
        .toList();

    final tray = PrinterTrayProfile(
      trayIdentifier: identifier,
      displayName: name,
      supportedPaperConfigurations: supportedConfigs,
      calibration: PrinterCalibration(
        enabled: false,
        calibrationRules: const [],
      ),
      nonPrintableMarginLeft: double.tryParse(_marginLeftController.text) ?? 0.0,
      nonPrintableMarginRight: double.tryParse(_marginRightController.text) ?? 0.0,
      nonPrintableMarginTop: double.tryParse(_marginTopController.text) ?? 0.0,
      nonPrintableMarginBottom: double.tryParse(_marginBottomController.text) ?? 0.0,
    );

    Navigator.of(context).pop(tray);
  }
}
