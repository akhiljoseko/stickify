import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
import 'package:stickify/presentation/features/print/presentation/shared/manufacturing_date_picker.dart';
import 'package:stickify/presentation/features/template_editor/core/element_renderer_registry.dart';
import 'package:stickify/presentation/widgets/widgets.dart';

/// Renders the print configuration parameters (quantity, printer, metadata, print button).
class ParametersPanel extends StatefulWidget {
  /// Creates a [ParametersPanel].
  const ParametersPanel({
    required this.loadedState,
    required this.totalSheets,
    required this.template,
    required this.sheetConfig,
    required this.state,
    this.onQuantityChanged,
    this.onPrinterChanged,
    this.onManufacturingDateChanged,
    this.onTemplateChanged,
    this.onToggleAllFirstSheet,
    this.onTogglePrintFromBottom,
    this.onToggleReverseSheetOrder,
    this.onPrint,
    this.showQuantityField = true,
    this.showTemplateSelector = true,
    this.isSubmitting = false,
    super.key,
  });

  /// The active print workflow loaded state.
  final PrintWorkflowLoaded loadedState;

  /// The total number of calculated sheets.
  final int totalSheets;

  /// The active template metadata.
  final LabelTemplate template;

  /// The sheet configuration parameters.
  final SheetConfig sheetConfig;

  /// The overall bloc state.
  final PrintWorkflowState state;

  /// Callback when quantity field changes.
  final ValueChanged<int>? onQuantityChanged;

  /// Callback when target printer is selected.
  final ValueChanged<PrinterDevice>? onPrinterChanged;

  /// Callback when manufacturing date changes.
  final ValueChanged<DateTime>? onManufacturingDateChanged;

  /// Callback when label template is changed.
  final ValueChanged<LabelTemplate>? onTemplateChanged;

  /// Callback when select/deselect all first sheet action is triggered.
  final ValueChanged<bool>? onToggleAllFirstSheet;

  /// Callback when print from bottom toggle changes.
  final ValueChanged<bool>? onTogglePrintFromBottom;

  /// Callback when reverse sheet order toggle changes.
  final ValueChanged<bool>? onToggleReverseSheetOrder;

  /// Callback when print action is triggered.
  final VoidCallback? onPrint;

  /// Whether to display the quantity text field.
  final bool showQuantityField;

  /// Whether to display the template selector dropdown.
  final bool showTemplateSelector;

  /// Whether a print job is currently compiling or submitting.
  final bool isSubmitting;

  @override
  State<ParametersPanel> createState() => _ParametersPanelState();
}

class _ParametersPanelState extends State<ParametersPanel> {
  late final TextEditingController _qtyController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(text: widget.loadedState.quantity.toString());
    _focusNode = FocusNode();

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _qtyController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _qtyController.text.length,
        );
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.showQuantityField) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(ParametersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loadedState.quantity.toString() != _qtyController.text && !_focusNode.hasFocus) {
      _qtyController.text = widget.loadedState.quantity.toString();
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final slotsPerSheet = widget.sheetConfig.columns * widget.sheetConfig.rows;
    final allFirstSheetSelected = Iterable<int>.generate(slotsPerSheet)
        .every((slot) => !widget.loadedState.disabledSlots.contains(slot));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Print Parameters',
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Quantity (conditional)
            if (widget.showQuantityField) ...[
              TextFormField(
                controller: _qtyController,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Quantity to Print',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final parsed = int.tryParse(val) ?? 0;
                  if (widget.onQuantityChanged != null) {
                    widget.onQuantityChanged!(parsed);
                  } else {
                    context.read<PrintWorkflowCubit>().updateQuantity(parsed);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
            // Printer Selection
            DropdownButtonFormField<PrinterDevice>(
              isExpanded: true,
              initialValue: widget.loadedState.selectedPrinter,
              decoration: const InputDecoration(
                labelText: 'Printer Selection',
                border: OutlineInputBorder(),
              ),
              items: widget.loadedState.availablePrinters
                  .map(
                    (p) => DropdownMenuItem<PrinterDevice>(
                      value: p,
                      child: Text(p.name),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  if (widget.onPrinterChanged != null) {
                    widget.onPrinterChanged!(val);
                  } else {
                    context.read<PrintWorkflowCubit>().updatePrinter(val);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            ManufacturingDatePicker(
              selectedDate: widget.loadedState.manufacturingDate,
              onDateChanged: (date) {
                if (widget.onManufacturingDateChanged != null) {
                  widget.onManufacturingDateChanged!(date);
                } else {
                  context.read<PrintWorkflowCubit>().updateManufacturingDate(date);
                }
              },
            ),
            if (widget.showTemplateSelector) ...[
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
              // Template selection dropdown
              TemplateSelectorField(
                templates: widget.loadedState.templates,
                selectedTemplateId: widget.loadedState.selectedTemplate?.id,
                labelText: 'Label Template',
                onChanged: widget.loadedState.templates.isEmpty
                    ? (_) {}
                    : (val) {
                        if (val != null) {
                          final template = widget.loadedState.templates.firstWhere((t) => t.id == val);
                          if (widget.onTemplateChanged != null) {
                            widget.onTemplateChanged!(template);
                          } else {
                            context.read<PrintWorkflowCubit>().selectTemplate(template);
                          }
                        }
                      },
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Orientation',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.sheetConfig.pageWidth > widget.sheetConfig.pageHeight
                      ? 'Landscape'
                      : 'Portrait',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Sheet Controls',
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 42),
              ),
              onPressed: () {
                final select = !allFirstSheetSelected;
                if (widget.onToggleAllFirstSheet != null) {
                  widget.onToggleAllFirstSheet!(select);
                } else {
                  final cubit = context.read<PrintWorkflowCubit>();
                  if (allFirstSheetSelected) {
                    cubit.deselectAllFirstSheet();
                  } else {
                    cubit.selectAllFirstSheet();
                  }
                }
              },
              icon: Icon(
                allFirstSheetSelected ? Icons.deselect : Icons.select_all,
                size: 18,
              ),
              label: Text(
                allFirstSheetSelected ? 'Deselect All First Sheet' : 'Select All First Sheet',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Print from bottom',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: widget.loadedState.printFromBottom,
                  onChanged: (val) {
                    if (widget.onTogglePrintFromBottom != null) {
                      widget.onTogglePrintFromBottom!(val);
                    } else {
                      context.read<PrintWorkflowCubit>().togglePrintFromBottom(value: val);
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Reverse sheet order',
                    style: textTheme.bodyMedium,
                  ),
                ),
                Switch(
                  value: widget.loadedState.reverseSheetOrder,
                  onChanged: (val) {
                    if (widget.onToggleReverseSheetOrder != null) {
                      widget.onToggleReverseSheetOrder!(val);
                    } else {
                      context.read<PrintWorkflowCubit>().toggleReverseSheetOrder(value: val);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Header bar for Print Preview displaying title, summary badges, and primary Print button.
class PrintPreviewHeader extends StatelessWidget {
  /// Creates a [PrintPreviewHeader].
  const PrintPreviewHeader({
    required this.title,
    required this.subtitle,
    required this.totalQuantity,
    required this.totalSheets,
    this.onPrint,
    this.onBack,
    this.backButtonLabel = 'Back',
    this.isSubmitting = false,
    super.key,
  });

  /// Primary screen title.
  final String title;

  /// Subtitle detailing template or job info.
  final String subtitle;

  /// Total count of labels to print.
  final int totalQuantity;

  /// Total physical sheets required.
  final int totalSheets;

  /// Callback when primary Print button is clicked.
  final VoidCallback? onPrint;

  /// Callback when Back button is clicked.
  final VoidCallback? onBack;

  /// Custom label for Back button.
  final String backButtonLabel;

  /// Whether print job is submitting.
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      color: colorScheme.surfaceContainerLowest,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Wrap(
          spacing: 16,
          runSpacing: 12,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onBack != null) ...[
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                    label: Text(
                      backButtonLabel,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Summary Badge 1: Total Labels
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.label_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '$totalQuantity Label${totalQuantity == 1 ? "" : "s"}',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Summary Badge 2: Total Sheets
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.layers_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Text(
                        '$totalSheets Sheet${totalSheets == 1 ? "" : "s"}',
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Primary Print Button
                if (onPrint != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: isSubmitting ? null : onPrint,
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.print, size: 18),
                    label: Text(
                      isSubmitting ? 'Sending...' : 'Print Labels',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders the layout grid/bento preview of label sheets.
class SheetsPreview extends StatelessWidget {
  /// Creates a [SheetsPreview].
  const SheetsPreview({
    required this.loadedState,
    required this.totalSheets,
    required this.slotsPerSheet,
    required this.activePositions,
    required this.sheetConfig,
    required this.sticker,
    required this.template,
    required this.items,
    this.product,
    this.variant,
    this.onToggleSlot,
    this.onToggleRowSlots,
    this.onToggleAllFirstSheet,
    this.onTogglePrintFromBottom,
    this.onToggleReverseSheetOrder,
    super.key,
  });

  /// The active loaded workflow state metadata.
  final PrintWorkflowLoaded loadedState;

  /// Total calculated sheets.
  final int totalSheets;

  /// Slots per sheet.
  final int slotsPerSheet;

  /// Indexes of active printed labels.
  final Set<int> activePositions;

  /// Sheet configuration.
  final SheetConfig sheetConfig;

  /// Sticker layout dimensions.
  final StickerConfig sticker;

  /// Label template.
  final LabelTemplate template;

  /// Items list designated for slot filling.
  final List<PrintableItem> items;

  /// Optional fallback product entity.
  final Product? product;

  /// Optional fallback product variant entity.
  final ProductVariant? variant;

  /// Callback when a slot grid index toggle action is triggered.
  final ValueChanged<int>? onToggleSlot;

  /// Callback when a row checkbox toggle action is triggered.
  final void Function(int sheetIndex, int rowIndex, bool select)? onToggleRowSlots;

  /// Callback when select/deselect all first sheet action is triggered.
  final ValueChanged<bool>? onToggleAllFirstSheet;

  /// Callback when print from bottom toggle changes.
  final ValueChanged<bool>? onTogglePrintFromBottom;

  /// Callback when reverse sheet order toggle changes.
  final ValueChanged<bool>? onToggleReverseSheetOrder;

  /// Maximum number of sheet previews to render (prevents OOM for large jobs).
  static const int maxPreviewSheets = 15;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Map active slots sequentially to items in the list
    final sortedActivePositions = activePositions.toList()..sort();
    final slotItemMap = <int, PrintableItem>{};
    var currentItemIndex = 0;
    var currentItemUsedQty = 0;

    for (final absIndex in sortedActivePositions) {
      while (currentItemIndex < items.length &&
          currentItemUsedQty >= items[currentItemIndex].quantity) {
        currentItemIndex++;
        currentItemUsedQty = 0;
      }
      if (currentItemIndex < items.length) {
        slotItemMap[absIndex] = items[currentItemIndex];
        currentItemUsedQty++;
      }
    }

    final isResuming = loadedState.isResumingPartialSheet || loadedState.disabledSlots.isNotEmpty;
    final disabledCount = loadedState.disabledSlots.length;

    final partialSheetBadge = isResuming
        ? Tooltip(
            message: 'Click to reset pre-disabled slots to a fresh full sheet',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.read<PrintWorkflowCubit>().resetPartialSheet(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Resuming Partial Sheet ($disabledCount)',
                        style: textTheme.labelMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.refresh, size: 14, color: colorScheme.onSurfaceVariant),
                    ],
                  ),
                ),
              ),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Sheet Layout Preview',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isResuming) partialSheetBadge!,
          ],
        ),
        const SizedBox(height: 16),

        // Sheets scrollable container — capped to prevent OOM for large jobs
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: totalSheets > maxPreviewSheets
              ? maxPreviewSheets
              : totalSheets,
          separatorBuilder: (context, index) => const SizedBox(height: 24),
          itemBuilder: (context, sheetIndex) {
            final disabledOnSheet = loadedState.disabledSlots
                .where(
                  (s) =>
                      s >= sheetIndex * slotsPerSheet &&
                      s < (sheetIndex + 1) * slotsPerSheet,
                )
                .length;
            final activeOnSheet = activePositions
                .where(
                  (s) =>
                      s >= sheetIndex * slotsPerSheet &&
                      s < (sheetIndex + 1) * slotsPerSheet,
                )
                .length;

            final sheetTitle = 'Sheet ${sheetIndex + 1}';
            final statusLabel = disabledOnSheet > 0
                ? '$activeOnSheet Active, $disabledOnSheet Skipped'
                : '$activeOnSheet Labels';

            return Card(
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            sheetTitle.toUpperCase(),
                            style: textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: disabledOnSheet > 0
                                ? colorScheme.errorContainer.withValues(
                                    alpha: 0.3,
                                  )
                                : colorScheme.tertiaryContainer.withValues(
                                    alpha: 0.3,
                                  ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            statusLabel,
                            style: textTheme.labelSmall?.copyWith(
                              color: disabledOnSheet > 0
                                  ? colorScheme.error
                                  : colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // The Sheet Surface Container
                    Center(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: AspectRatio(
                          aspectRatio:
                              sheetConfig.pageWidth / sheetConfig.pageHeight,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final paddingLeft =
                                  (sheetConfig.marginLeft /
                                      sheetConfig.pageWidth) *
                                  constraints.maxWidth;
                              final paddingRight =
                                  (sheetConfig.marginRight /
                                      sheetConfig.pageWidth) *
                                  constraints.maxWidth;
                              final paddingTop =
                                  (sheetConfig.marginTop /
                                      sheetConfig.pageHeight) *
                                  constraints.maxHeight;
                              final paddingBottom =
                                  (sheetConfig.marginBottom /
                                      sheetConfig.pageHeight) *
                                  constraints.maxHeight;

                              return Padding(
                                padding: EdgeInsets.fromLTRB(
                                  paddingLeft,
                                  paddingTop,
                                  paddingRight,
                                  paddingBottom,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: List.generate(sheetConfig.rows, (rowIndex) {
                                          final rowSlots = List.generate(
                                            sheetConfig.columns,
                                            (c) => sheetIndex * slotsPerSheet + rowIndex * sheetConfig.columns + c,
                                          );
                                          final allEnabled = rowSlots.every(
                                            (slot) => !loadedState.disabledSlots.contains(slot),
                                          );
                                          final allDisabled = rowSlots.every(
                                            loadedState.disabledSlots.contains,
                                          );
                                          final checkboxValue = allEnabled
                                              ? true
                                              : (allDisabled ? false : null);

                                          return Expanded(
                                            child: Center(
                                              child: Checkbox(
                                                tristate: true,
                                                value: checkboxValue,
                                                activeColor: colorScheme.primary,
                                                onChanged: (val) {
                                                  final select = val == true;
                                                  if (onToggleRowSlots != null) {
                                                    onToggleRowSlots!(sheetIndex, rowIndex, select);
                                                  } else {
                                                    context.read<PrintWorkflowCubit>().toggleRowSlots(
                                                      sheetIndex,
                                                      rowIndex,
                                                      select: select,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: sheetConfig.columns,
                                              crossAxisSpacing:
                                                  (sheetConfig.columnGap /
                                                      sheetConfig.pageWidth) *
                                                  constraints.maxWidth,
                                              mainAxisSpacing:
                                                  (sheetConfig.rowGap /
                                                      sheetConfig.pageHeight) *
                                                  constraints.maxHeight,
                                              childAspectRatio:
                                                  sticker.widthMm / sticker.heightMm,
                                            ),
                                        itemCount: slotsPerSheet,
                                        itemBuilder: (context, slotGridIndex) {
                                          final absIndex =
                                              sheetIndex * slotsPerSheet +
                                              slotGridIndex;
                                          final isDisabled = loadedState.disabledSlots
                                              .contains(absIndex);
                                          final isActive = activePositions.contains(
                                            absIndex,
                                          );
      
                                          if (isDisabled) {
                                            return InkWell(
                                              onTap: () {
                                                if (onToggleSlot != null) {
                                                  onToggleSlot!(absIndex);
                                                } else {
                                                  context
                                                      .read<PrintWorkflowCubit>()
                                                      .toggleSlot(absIndex);
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color:
                                                      colorScheme.surfaceContainerLow,
                                                  border: Border.all(
                                                    color: colorScheme.outlineVariant,
                                                  ),
                                                  borderRadius: BorderRadius.circular(
                                                    4,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Icon(
                                                        Icons.block,
                                                        size: 14,
                                                        color: colorScheme.outline,
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Skipped',
                                                        style: textTheme.labelSmall?.copyWith(
                                                          color: colorScheme.outline,
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
      
                                          if (isActive) {
                                            final activeItem = slotItemMap[absIndex] ??
                                                (items.isNotEmpty ? items.first : null);
                                            final activeProduct = activeItem?.product ?? product!;
                                            final activeVariant = activeItem?.variant ?? variant!;

                                            return InkWell(
                                              onTap: () {
                                                if (onToggleSlot != null) {
                                                  onToggleSlot!(absIndex);
                                                } else {
                                                  context
                                                      .read<PrintWorkflowCubit>()
                                                      .toggleSlot(absIndex);
                                                }
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: colorScheme.primary,
                                                    width: 1.5,
                                                  ),
                                                  borderRadius: BorderRadius.circular(
                                                    4,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(
                                                    3,
                                                  ),
                                                  child: FittedBox(
                                                    child: SizedBox(
                                                      width: sticker.widthMm * 4,
                                                      height: sticker.heightMm * 4,
                                                      child: Stack(
                                                        children: template.elements.map((
                                                          bp,
                                                        ) {
                                                          final width =
                                                              bp.width * 4.0;
                                                          final height =
                                                              bp.height * 4.0;
                                                          final left = bp.x * 4.0;
                                                          final top = bp.y * 4.0;
                                                          final renderedChild =
                                                              ElementRendererRegistry.forBlueprint(
                                                                bp,
                                                              ).render(
                                                                context,
                                                                bp,
                                                                product: activeProduct,
                                                                variant: activeVariant,
                                                                manufacturingDate: loadedState.manufacturingDate,
                                                              );
      
                                                          return Positioned(
                                                            left: left,
                                                            top: top,
                                                            width: width,
                                                            height: height,
                                                            child: Transform.rotate(
                                                              angle:
                                                                  bp.rotation *
                                                                  (pi / 180),
                                                              child: SizedBox(
                                                                width: width,
                                                                height: height,
                                                                child: renderedChild,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
      
                                          // Unused/Empty slot at the end
                                          return Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: colorScheme.outlineVariant,
                                              ),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Center(
                                              child: Icon(
                                                Icons.radio_button_unchecked,
                                                color: Colors.grey,
                                                size: 16,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        if (totalSheets > maxPreviewSheets) ...[
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colorScheme.primary, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${totalSheets - maxPreviewSheets} additional sheet(s) will be printed. '
                      'All stickers will print correctly.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        // Help Box
        Card(
          color: colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.info, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'If you\'re using a label sheet that has already been partially printed, click on individual slots to mark them as "Used". LabelFlow will automatically adjust the printing sequence and calculate the required sheets.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
