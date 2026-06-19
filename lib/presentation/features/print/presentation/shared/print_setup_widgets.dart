import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_state.dart';
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
      if (mounted) {
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Print Parameters',
              style: textTheme.titleSmall?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 20),
            // Quantity
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
                context.read<PrintWorkflowCubit>().updateQuantity(parsed);
              },
            ),
            const SizedBox(height: 20),
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
                  context.read<PrintWorkflowCubit>().updatePrinter(val);
                }
              },
            ),
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
                        context.read<PrintWorkflowCubit>().selectTemplate(template);
                      }
                    },
            ),
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
            const SizedBox(height: 24),
            // Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Total Labels',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.loadedState.quantity.toString(),
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Sheets Required',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.totalSheets.toString(),
                        style: textTheme.headlineMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Print button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                onPressed: widget.state is PrintWorkflowSubmitting
                    ? null
                    : () => context.read<PrintWorkflowCubit>().startPrintJob(),
                icon: widget.state is PrintWorkflowSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print),
                label: Text(
                  widget.state is PrintWorkflowSubmitting
                      ? 'Sending to Printer...'
                      : 'Print',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
    required this.product,
    required this.variant,
    super.key,
  });

  /// The active loaded workflow state.
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

  /// Product entity.
  final Product product;

  /// Product variant entity.
  final ProductVariant variant;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final useVerticalHeader = constraints.maxWidth < 600;
            final legendRow = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    border: Border.all(color: colorScheme.primary),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 4),
                Text('Active', style: textTheme.bodySmall),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Icon(Icons.close, size: 8, color: Colors.grey),
                ),
                const SizedBox(width: 4),
                Text('Used/Skipped', style: textTheme.bodySmall),
              ],
            );

            if (useVerticalHeader) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sheet Layout Preview',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  legendRow,
                ],
              );
            } else {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sheet Layout Preview',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  legendRow,
                ],
              );
            }
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Builder(
              builder: (context) {
                final allFirstSheetSelected = Iterable<int>.generate(slotsPerSheet)
                    .every((slot) => !loadedState.disabledSlots.contains(slot));

                return OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    final cubit = context.read<PrintWorkflowCubit>();
                    if (allFirstSheetSelected) {
                      cubit.deselectAllFirstSheet();
                    } else {
                      cubit.selectAllFirstSheet();
                    }
                  },
                  icon: Icon(
                    allFirstSheetSelected ? Icons.deselect : Icons.select_all,
                    size: 16,
                  ),
                  label: Text(
                    allFirstSheetSelected ? 'Deselect All First Sheet' : 'Select All First Sheet',
                  ),
                );
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Print from bottom',
                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: loadedState.printFromBottom,
                  onChanged: (val) {
                    context.read<PrintWorkflowCubit>().togglePrintFromBottom(value: val);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

          // Sheets scrollable container
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: totalSheets,
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
                                        onTap: () => context
                                            .read<PrintWorkflowCubit>()
                                            .toggleSlot(absIndex),
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
                                          child: const Center(
                                            child: Icon(
                                              Icons.close,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      );
                                    }

                                    if (isActive) {
                                      return InkWell(
                                        onTap: () => context
                                            .read<PrintWorkflowCubit>()
                                            .toggleSlot(absIndex),
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
                                                          product: product,
                                                          variant: variant,
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
        const SizedBox(height: 24),
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
