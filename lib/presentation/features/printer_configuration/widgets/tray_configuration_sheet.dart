import 'package:flutter/material.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

class TrayConfigurationSheet extends StatefulWidget {
  const TrayConfigurationSheet({
    this.existingTray,
    super.key,
  });

  final PrinterTrayProfile? existingTray;

  static Future<PrinterTrayProfile?> show({
    required BuildContext context,
    PrinterTrayProfile? existingTray,
  }) {
    return showAdaptiveSheet<PrinterTrayProfile>(
      context: context,
      isScrollControlled: true,
      builder: (_) => TrayConfigurationSheet(existingTray: existingTray),
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

  @override
  void initState() {
    super.initState();
    _trayNameController = TextEditingController(
      text: widget.existingTray?.displayName ?? '',
    );
    _trayIdentifierController = TextEditingController(
      text: widget.existingTray?.trayIdentifier ?? '',
    );
    _marginTopController = TextEditingController(
      text: widget.existingTray?.calibration.calibrationRules.isNotEmpty == true
          ? ''
          : '0.0',
    );
    _marginBottomController = TextEditingController(text: '0.0');
    _marginLeftController = TextEditingController(text: '0.0');
    _marginRightController = TextEditingController(text: '0.0');
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
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
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
              Expanded(
                child: ListView(
                  controller: scrollController,
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
                      'Feed & Orientation',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      context,
                      label: 'Media Type',
                      value: 'A4 Product Labels',
                      items: const [
                        'A4 Product Labels',
                        'B5 Industrial Adhesive',
                        'Custom Vinyl Roll',
                      ],
                    ),
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
          );
        },
      ),
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required List<String> items,
  }) {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.layers),
      ),
      items: items
          .map(
            (item) => DropdownMenuItem(value: item, child: Text(item)),
          )
          .toList(),
      onChanged: (_) {},
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

    final tray = PrinterTrayProfile(
      trayIdentifier: identifier,
      displayName: name,
      supportedPaperConfigurations: const [],
      calibration: PrinterCalibration(
        enabled: false,
        calibrationRules: const [],
      ),
    );

    Navigator.of(context).pop(tray);
  }
}
