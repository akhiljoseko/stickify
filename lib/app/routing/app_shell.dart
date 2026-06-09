import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NAVIGATION DESTINATIONS
//
// A single source of truth for both the NavigationRail (desktop) and the
// BottomNavigationBar (mobile). Keeping them co-located ensures that the
// label, icon, and index always stay in sync across both layouts.
// ─────────────────────────────────────────────────────────────────────────────

/// One navigation destination shared by both the desktop rail and mobile bar.
class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const List<_NavDestination> _kDestinations = [
  _NavDestination(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
  ),
  _NavDestination(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Products',
  ),
  _NavDestination(
    icon: Icons.layers_outlined,
    selectedIcon: Icons.layers,
    label: 'Templates',
  ),
  _NavDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Settings',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// DESKTOP NAVIGATION RAIL
// ─────────────────────────────────────────────────────────────────────────────

/// Desktop left-side navigation rail.
///
/// Rendered exclusively on Tablet and Desktop breakpoints via
/// [AdaptiveLayoutSwitcher] inside [AppShell]. Never shown on Mobile.
///
/// Accepts the currently active [currentIndex] and an [onDestinationSelected]
/// callback so this widget remains stateless and testable in isolation.
class CustomNavigationRail extends StatelessWidget {
  const CustomNavigationRail({
    required this.currentIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// The index of the currently selected destination (0-based).
  final int currentIndex;

  /// Called when the user taps a destination. Receives the tapped index.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationRail(
      // ── Styling ───────────────────────────────────────────────────────────
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedIconTheme: IconThemeData(color: colorScheme.primary),
      unselectedIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
      indicatorColor: colorScheme.primaryContainer,

      // ── State ─────────────────────────────────────────────────────────────
      selectedIndex: currentIndex,

      // ── Layout ────────────────────────────────────────────────────────────
      labelType: NavigationRailLabelType.all,

      // ── Leading widget (app logo / branding) ──────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.sticky_note_2_rounded,
            color: colorScheme.onPrimaryContainer,
            size: 22,
          ),
        ),
      ),

      // ── Destinations ──────────────────────────────────────────────────────
      destinations: _kDestinations.map((d) {
        return NavigationRailDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon),
          label: Text(d.label),
        );
      }).toList(),

      // ── Callback ──────────────────────────────────────────────────────────
      onDestinationSelected: onDestinationSelected,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MOBILE BOTTOM NAVIGATION BAR
// ─────────────────────────────────────────────────────────────────────────────

/// Mobile bottom navigation bar.
///
/// Rendered exclusively on the Mobile breakpoint via [AdaptiveLayoutSwitcher]
/// inside [AppShell]. Never shown on Tablet or Desktop.
class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onDestinationSelected,
      backgroundColor: colorScheme.surfaceContainerLow,
      indicatorColor: colorScheme.primaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: _kDestinations.map((d) {
        return NavigationDestination(
          icon: Icon(d.icon),
          selectedIcon: Icon(d.selectedIcon, color: colorScheme.primary),
          label: d.label,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SHELL
//
// The shell is stateless — all state lives in StatefulNavigationShell (which
// branch is active) and in each branch's own Navigator stack.
//
// Layout strategy (via AdaptiveLayoutSwitcher — no inline bp.isDesktop):
//   - Mobile:  Scaffold with bottomNavigationBar = NavigationBar
//   - Desktop: Scaffold with body = Row[ NavigationRail | content ]
// ─────────────────────────────────────────────────────────────────────────────

/// The root layout scaffold for authenticated users.
///
/// Uses [AdaptiveLayoutSwitcher] to switch between the desktop
/// [CustomNavigationRail] + content [Row] layout and the mobile
/// [NavigationBar] + content [Column] layout — with zero inline
/// breakpoint conditionals in this widget's [build] method.
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
    return AdaptiveLayoutSwitcher(
      // ── Mobile: bottom nav layout ─────────────────────────────────────────
      mobile: _MobileShell(
        navigationShell: navigationShell,
        onDestinationSelected: _onDestinationSelected,
      ),
      // ── Tablet: compact rail (labels on selected only) ────────────────────
      tablet: _DesktopShell(
        navigationShell: navigationShell,
        onDestinationSelected: _onDestinationSelected,
      ),
      // ── Desktop: full rail with all labels ────────────────────────────────
      desktop: _DesktopShell(
        navigationShell: navigationShell,
        onDestinationSelected: _onDestinationSelected,
      ),
    );
  }

  /// Switches to [index], resetting to branch root when the already-active
  /// tab is tapped — a standard mobile and desktop UX pattern.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE LAYOUT VARIANTS
// Extracted into separate stateless widgets so each variant is const and
// only the active one is ever in the widget tree.
// ─────────────────────────────────────────────────────────────────────────────

/// Desktop shell: NavigationRail on the left, content on the right.
class _DesktopShell extends StatelessWidget {
  const _DesktopShell({
    required this.navigationShell,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left navigation rail
          CustomNavigationRail(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          // Vertical divider
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          // Active branch content
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

/// Mobile shell: content fills the body, NavigationBar at the bottom.
class _MobileShell extends StatelessWidget {
  const _MobileShell({
    required this.navigationShell,
    required this.onDestinationSelected,
  });

  final StatefulNavigationShell navigationShell;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _MobileBottomNav(
        currentIndex: navigationShell.currentIndex,
        onDestinationSelected: onDestinationSelected,
      ),
    );
  }
}
