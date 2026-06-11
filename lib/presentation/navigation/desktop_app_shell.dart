import 'package:flutter/material.dart';
import 'package:stickify/presentation/navigation/shared_sidebar.dart';
import 'package:stickify/presentation/widgets/global_header_bar.dart';

/// Navigation app shell for desktop/ultra-wide viewports, featuring an expanded sidebar layout.
class DesktopAppShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Row(
        children: [
          CustomSidebar(
            isExtended: true,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
          Expanded(
            child: Column(
              children: [
                const GlobalHeaderBar(),
                Expanded(child: body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
