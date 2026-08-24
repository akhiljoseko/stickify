import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print/cubits/print_workflow_cubit.dart';
import 'package:stickify/presentation/widgets/app_image.dart';
import 'package:stickify/presentation/widgets/sheet_selector_widget.dart';

/// Screen / View displaying the comprehensive summary of a completed batch print job.
class BatchPrintSummaryView extends StatelessWidget {
  /// Creates a [BatchPrintSummaryView].
  const BatchPrintSummaryView({
    required this.summary,
    this.onClose,
    super.key,
  });

  /// The batch print summary entity.
  final BatchPrintSummary summary;

  /// Optional close callback. If omitted, defaults to `context.go('/dashboard')`.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Card(
                color: colorScheme.surfaceContainerLowest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 36,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        summary.batchTitle,
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Batch Print Job Dispatched Successfully!',
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      // Metadata Chips
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 10,
                        children: [
                          _buildChip(
                            context,
                            icon: Icons.label_outlined,
                            label: '${summary.totalQuantity} Labels',
                          ),
                          _buildChip(
                            context,
                            icon: Icons.layers_outlined,
                            label: '${summary.totalSheets} Sheet${summary.totalSheets == 1 ? "" : "s"}',
                          ),
                          _buildChip(
                            context,
                            icon: Icons.description_outlined,
                            label: summary.templateName,
                          ),
                          _buildChip(
                            context,
                            icon: Icons.print_outlined,
                            label: summary.printerName,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Items Section Header
              Text(
                'Printed Product Variants (${summary.items.length})',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Variants List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: summary.items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = summary.items[index];
                  return Card(
                    color: colorScheme.surfaceContainerLowest,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          AppImage(
                            imageUrl: item.imageUrl,
                            placeholderIcon: Icons.inventory_2_outlined,
                            width: 44,
                            height: 44,
                            borderRadius: 8,
                            iconSize: 22,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.productName} (${item.variantName})',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'SKU: ${item.variantSku}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${item.quantity} Label${item.quantity == 1 ? "" : "s"}',
                              style: textTheme.labelLarge?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Action Buttons Row
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => _showReprintDialog(context),
                        icon: const Icon(Icons.print_rounded),
                        label: const Text(
                          'Reprint Selected Sheets',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        onPressed: onClose ?? () => context.go('/dashboard'),
                        icon: const Icon(Icons.dashboard_rounded),
                        label: const Text(
                          'Go to Dashboard',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReprintDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          width: 600,
          child: _ReprintSheetSelectionDialog(summary: summary),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReprintSheetSelectionDialog extends StatefulWidget {
  const _ReprintSheetSelectionDialog({required this.summary});

  final BatchPrintSummary summary;

  @override
  State<_ReprintSheetSelectionDialog> createState() =>
      __ReprintSheetSelectionDialogState();
}

class __ReprintSheetSelectionDialogState
    extends State<_ReprintSheetSelectionDialog> {
  late Set<int> _selectedSheets;
  List<PrinterDevice> _printers = [];
  PrinterDevice? _selectedPrinter;
  bool _isLoadingPrinters = true;
  bool _isReprinting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedSheets = Set<int>.from(
      List.generate(widget.summary.totalSheets, (i) => i + 1),
    );
    _loadPrinters();
  }

  Future<void> _loadPrinters() async {
    try {
      final discoveryService = context.read<PrinterDiscoveryService>();
      final printers = await discoveryService.getAvailablePrinters();
      if (mounted) {
        setState(() {
          _printers = printers;
          _selectedPrinter = printers.firstWhere(
            (p) => p.name == widget.summary.printerName,
            orElse: () => printers.firstWhere(
              (p) => p.isDefault,
              orElse: () => printers.isNotEmpty
                  ? printers.first
                  : PrinterDevice(name: widget.summary.printerName, url: ''),
            ),
          );
          _isLoadingPrinters = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _selectedPrinter =
              PrinterDevice(name: widget.summary.printerName, url: '');
          _isLoadingPrinters = false;
        });
      }
    }
  }

  Future<void> _executeReprint() async {
    if (_selectedSheets.isEmpty || _selectedPrinter == null) return;
    setState(() {
      _isReprinting = true;
      _errorMessage = null;
    });

    final cubit = context.read<PrintWorkflowCubit>();
    final result = await cubit.reprintBatchSheets(
      summary: widget.summary,
      selectedSheets: _selectedSheets,
      printer: _selectedPrinter!,
    );

    if (mounted) {
      if (result case Failure(error: final err)) {
        setState(() {
          _isReprinting = false;
          _errorMessage = err.message;
        });
      } else {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully dispatched reprinting of sheet(s) ${_selectedSheets.join(", ")} to ${_selectedPrinter!.name}',
            ),
            backgroundColor: Colors.green.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.print_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reprint Batch Sheets',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select specific sheets to reprint (e.g. to replace jammed or damaged pages)',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Standalone Sheet Selector Widget
          SheetSelectorWidget(
            totalSheets: widget.summary.totalSheets,
            initialSelectedSheets: _selectedSheets,
            onSelectionChanged: (updated) {
              setState(() {
                _selectedSheets = updated;
              });
            },
          ),
          const SizedBox(height: 20),

          // Target Printer Dropdown
          if (_isLoadingPrinters)
            const Center(child: CircularProgressIndicator())
          else if (_printers.isNotEmpty) ...[
            Text(
              'Target Printer',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<PrinterDevice>(
              initialValue: _selectedPrinter,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              items: _printers.map((p) {
                return DropdownMenuItem(
                  value: p,
                  child: Text(p.name),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedPrinter = val;
                  });
                }
              },
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
            ),
          ],
          const SizedBox(height: 24),

          // Submit Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onPressed: _selectedSheets.isEmpty || _isReprinting
                    ? null
                    : _executeReprint,
                icon: _isReprinting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.print_rounded, size: 18),
                label: Text(
                  _isReprinting
                      ? 'Reprinting...'
                      : 'Reprint ${_selectedSheets.length} Sheet${_selectedSheets.length == 1 ? "" : "s"}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
