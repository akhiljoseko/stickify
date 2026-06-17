import 'package:flutter/material.dart';
import 'package:stickify/presentation/navigation/adaptive_app_shell.dart';

/// Navigation app shell tailored specifically for mobile phone viewports.
class MobileAppShell extends StatelessWidget {
  /// Creates a [MobileAppShell].
  const MobileAppShell({
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// Screen content body.
  final Widget body;

  /// Active navigation destination index.
  final int selectedIndex;

  /// Callback when a destination tab is clicked.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(kAppNavDestinations[selectedIndex].label),
      ),
      body: SafeArea(child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        indicatorColor: theme.colorScheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: kAppNavDestinations.map((d) {
          return NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(
              d.selectedIcon,
              color: theme.colorScheme.primary,
            ),
            label: d.label,
          );
        }).toList(),
      ),
    );
  }
}
