import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';
import 'package:stickify/domain/entities/label_template.dart';
import 'package:stickify/presentation/widgets/template_grid_card.dart';

/// A custom template selection form field.
///
/// Renders as a dropdown-sized button. Tapping it opens a dialog on larger screens
/// (desktop/tablet) and a bottom sheet on smaller screens (mobile).
class TemplateSelectorField extends StatelessWidget {
  /// Creates a [TemplateSelectorField].
  const TemplateSelectorField({
    required this.templates,
    required this.selectedTemplateId,
    required this.onChanged,
    this.labelText = 'Select Template',
    this.allowNone = false,
    this.noneLabel = 'None (always pick)',
    super.key,
  });

  /// The list of selectable templates.
  final List<LabelTemplate> templates;

  /// The ID of the currently selected template.
  final String? selectedTemplateId;

  /// Callback triggered when a template is selected.
  final ValueChanged<String?>? onChanged;

  /// Label text for the input decoration.
  final String labelText;

  /// Whether to allow selecting a null / "None" value.
  final bool allowNone;

  /// The text to display for the null / "None" option.
  final String noneLabel;

  void _showSelectionDialogOrBottomSheet(BuildContext context) {
    if (onChanged == null) return;
    final bp = ResponsiveBreakpoints.of(context);
    final isLargerScreen = bp.breakpoint.name != AppBreakpoints.mobile;

    if (isLargerScreen) {
      showDialog<void>(
        context: context,
        builder: (context) => _TemplateDialog(
          templates: templates,
          selectedTemplateId: selectedTemplateId,
          onChanged: onChanged!,
          allowNone: allowNone,
          noneLabel: noneLabel,
        ),
      );
    } else {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => _TemplateBottomSheet(
          templates: templates,
          selectedTemplateId: selectedTemplateId,
          onChanged: onChanged!,
          allowNone: allowNone,
          noneLabel: noneLabel,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    LabelTemplate? selectedTemplate;
    for (final t in templates) {
      if (t.id == selectedTemplateId) {
        selectedTemplate = t;
        break;
      }
    }

    final displayString = selectedTemplate != null
        ? '${selectedTemplate.name} (${selectedTemplate.sheetConfig != null ? '${selectedTemplate.sheetConfig!.columns * selectedTemplate.sheetConfig!.rows} labels' : '0 labels'})'
        : noneLabel;

    return InkWell(
      onTap: onChanged == null ? null : () => _showSelectionDialogOrBottomSheet(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: labelText,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          enabled: onChanged != null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                displayString,
                style: theme.textTheme.bodyMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _NoneListTile extends StatelessWidget {
  const _NoneListTile({
    required this.noneLabel,
    required this.isSelected,
    required this.onTap,
  });

  final String noneLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.15) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.block, color: colorScheme.onSurfaceVariant, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    noneLabel,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'No default template selected',
                    style: textTheme.bodySmall?.copyWith(
                      color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _TemplateDialog extends StatelessWidget {
  const _TemplateDialog({
    required this.templates,
    required this.selectedTemplateId,
    required this.onChanged,
    required this.allowNone,
    required this.noneLabel,
  });

  final List<LabelTemplate> templates;
  final String? selectedTemplateId;
  final ValueChanged<String?> onChanged;
  final bool allowNone;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Label Template'),
      content: SizedBox(
        width: 720,
        height: 480,
        child: Column(
          children: [
            if (allowNone) ...[
              _NoneListTile(
                noneLabel: noneLabel,
                isSelected: selectedTemplateId == null,
                onTap: () {
                  onChanged(null);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
            ],
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.only(top: 8),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 210,
                  mainAxisExtent: 220,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final t = templates[index];
                  final isSelected = selectedTemplateId == t.id;

                  return TemplateGridCard(
                    template: t,
                    isSelected: isSelected,
                    onTap: () {
                      onChanged(t.id);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _TemplateBottomSheet extends StatelessWidget {
  const _TemplateBottomSheet({
    required this.templates,
    required this.selectedTemplateId,
    required this.onChanged,
    required this.allowNone,
    required this.noneLabel,
  });

  final List<LabelTemplate> templates;
  final String? selectedTemplateId;
  final ValueChanged<String?> onChanged;
  final bool allowNone;
  final String noneLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Select Label Template',
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          if (allowNone) ...[
            _NoneListTile(
              noneLabel: noneLabel,
              isSelected: selectedTemplateId == null,
              onTap: () {
                onChanged(null);
                Navigator.pop(context);
              },
            ),
            const Divider(),
          ],
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.only(top: 8),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 180,
                mainAxisExtent: 200,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final t = templates[index];
                final isSelected = selectedTemplateId == t.id;

                return TemplateGridCard(
                  template: t,
                  isSelected: isSelected,
                  onTap: () {
                    onChanged(t.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
