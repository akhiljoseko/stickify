import 'package:flutter/material.dart';
import 'package:stickify/domain/entities/discovered_printer.dart';

class PrinterSelectionSheet extends StatelessWidget {
  const PrinterSelectionSheet({
    required this.printers,
    super.key,
  });

  final List<DiscoveredPrinter> printers;

  static Future<DiscoveredPrinter?> show({
    required BuildContext context,
    required List<DiscoveredPrinter> printers,
  }) {
    return showModalBottomSheet<DiscoveredPrinter>(
      context: context,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => PrinterSelectionSheet(printers: printers),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
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
                      'Select Printer',
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose a system printer to configure as a new printer profile.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: printers.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.print_disabled_outlined,
                              size: 48,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No printers discovered',
                              style: textTheme.titleSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ensure a printer is connected and powered on.',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.outline,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: printers.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                      ),
                      itemBuilder: (context, index) {
                        final printer = printers[index];
                        final isOnline = printer.status ==
                            DiscoveredPrinterStatus.online;

                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.print,
                              color: isOnline
                                  ? colorScheme.primary
                                  : colorScheme.outline,
                            ),
                          ),
                          title: Text(
                            printer.systemPrinterName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: printer.manufacturer.isNotEmpty ||
                                  printer.model.isNotEmpty
                              ? Text(
                                  '${printer.manufacturer} ${printer.model}',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? colorScheme.tertiaryContainer
                                  : colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isOnline ? 'Online' : 'Offline',
                              style: textTheme.labelSmall?.copyWith(
                                color: isOnline
                                    ? colorScheme.tertiary
                                    : colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: isOnline
                              ? () =>
                                  Navigator.of(context).pop(printer)
                              : null,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
