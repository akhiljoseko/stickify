import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stickify/core/presentation/notifications/notification_widget.dart';
import 'package:stickify/presentation/features/print/widgets/product_variant_selection_dialog.dart';
import 'package:stickify/presentation/navigation/shared_sidebar.dart';

/// Navigation app shell for desktop/ultra-wide viewports, featuring an expanded sidebar layout.
class DesktopAppShell extends StatefulWidget {
  /// Creates a [DesktopAppShell].
  const DesktopAppShell({
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// Screen content body.
  final Widget body;

  /// Active navigation destination index.
  final int selectedIndex;

  /// Callback when a destination item is clicked.
  final ValueChanged<int> onDestinationSelected;

  @override
  State<DesktopAppShell> createState() => _DesktopAppShellState();
}

class _DesktopAppShellState extends State<DesktopAppShell> {
  final FocusNode _focusNode = FocusNode();

  @override
  void didUpdateWidget(DesktopAppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isCtrl = HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          if (isCtrl && event.logicalKey == LogicalKeyboardKey.keyP) {
            if (widget.selectedIndex == 0) {
              ProductVariantSelectionDialog.show(context);
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Stack(
          children: [
            Row(
              children: [
                CustomSidebar(
                  isExtended: true,
                  selectedIndex: widget.selectedIndex,
                  onDestinationSelected: widget.onDestinationSelected,
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: theme.colorScheme.outlineVariant,
                ),
                Expanded(child: widget.body),
              ],
            ),
            const NotificationListenerWidget(),
          ],
        ),
      ),
    );
  }
}
