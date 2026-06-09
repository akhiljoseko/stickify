import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/presentation/widgets/adaptive_navigation_shell.dart';

/// The root layout scaffold for authenticated users.
///
/// Delegates layout rendering to the global [AdaptiveNavigationShell] component.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  /// The live shell provided by [GoRouter] containing the active branch
  /// widget and the branch-switching API.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return AdaptiveNavigationShell(
      body: navigationShell,
      selectedIndex: navigationShell.currentIndex,
      onDestinationSelected: _onDestinationSelected,
    );
  }

  /// Switches to [index], resetting to branch root when the already-active
  /// tab is tapped.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
