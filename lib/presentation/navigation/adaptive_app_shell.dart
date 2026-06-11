import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/navigation/desktop_app_shell.dart';
import 'package:stickify/presentation/navigation/mobile_app_shell.dart';
import 'package:stickify/presentation/navigation/tablet_app_shell.dart';

/// Active navigation destinations.
class AppNavDestination {
  /// Creates an [AppNavDestination].
  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  /// Visual icon for unselected states.
  final IconData icon;

  /// Visual icon for selected states.
  final IconData selectedIcon;

  /// Human-readable tab label.
  final String label;
}

/// The list of primary destinations across app shells.
const List<AppNavDestination> kAppNavDestinations = [
  AppNavDestination(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  AppNavDestination(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Products',
  ),
  AppNavDestination(
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers,
    label: 'Templates',
  ),
  AppNavDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

/// Adaptive navigation app shell routing context.
///
/// Automatically switches between platform navigation patterns based on resolved [AppEnvironment].
class AdaptiveAppShell extends StatelessWidget {
  /// Creates an [AdaptiveAppShell].
  const AdaptiveAppShell({
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// The active view content to render.
  final Widget body;

  /// Index of the active navigation branch.
  final int selectedIndex;

  /// Callback triggered when a navigation destination is selected.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final env = context.watch<AppEnvironment>();

    switch (env.experience) {
      case AppExperience.mobile:
        return MobileAppShell(
          body: body,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );
      case AppExperience.tablet:
        return TabletAppShell(
          body: body,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );
      case AppExperience.desktop:
        return DesktopAppShell(
          body: body,
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
        );
    }
  }
}
