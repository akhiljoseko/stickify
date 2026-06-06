import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM NAVIGATION RAIL
//
// A reusable, stateless widget that renders the desktop left-side navigation
// rail. Keeping this separate from [AppShell] means:
//   • It can be tested in isolation.
//   • It can be swapped for a [NavigationDrawer] on smaller screens without
//     touching the shell layout logic.
//   • It has a clean, declarative API — it knows nothing about routing.
// ─────────────────────────────────────────────────────────────────────────────

/// The destinations shown in the navigation rail, in branch index order.
///
/// The index of each entry **must** match the branch index declared in the
/// `@TypedStatefulShellRoute` annotation inside `router.dart`. If you add or
/// reorder branches, update this list to match.
const List<NavigationRailDestination> _kDestinations = [
  NavigationRailDestination(
    icon: Icon(Icons.dashboard_outlined),
    selectedIcon: Icon(Icons.dashboard),
    label: Text('Dashboard'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    label: Text('Products'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.layers_outlined),
    selectedIcon: Icon(Icons.layers),
    label: Text('Templates'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.settings_outlined),
    selectedIcon: Icon(Icons.settings),
    label: Text('Settings'),
  ),
];

/// A reusable, stateless navigation rail for the desktop shell layout.
///
/// Accepts the currently active [currentIndex] and an [onDestinationSelected]
/// callback. It renders a [NavigationRail] styled with the app's [ColorScheme]
/// tokens.
///
/// ## Responsibilities
///
/// This widget owns **only** the visual rendering of the rail. Branch switching
/// logic lives in [AppShell] which calls [StatefulNavigationShell.goBranch].
///
/// ## Example
///
/// ```dart
/// CustomNavigationRail(
///   currentIndex: navigationShell.currentIndex,
///   onDestinationSelected: (i) => navigationShell.goBranch(i),
/// )
/// ```
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
      // Show labels for all destinations (desktop has space).
      labelType: NavigationRailLabelType.all,
      // Extended rails show a full-width label next to the icon.
      // Set to false here to keep it compact; flip to true if you want a
      // sidebar-style rail.

      // ── Leading widget (app logo / branding) ──────────────────────────────
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
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
          ],
        ),
      ),

      // ── Destinations ──────────────────────────────────────────────────────
      destinations: _kDestinations,

      // ── Callback ──────────────────────────────────────────────────────────
      onDestinationSelected: onDestinationSelected,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// APP SHELL
//
// [AppShell] is the persistent layout widget rendered by [AppShellRouteData].
// It owns the outer [Scaffold] with [CustomNavigationRail] on the left and
// the active branch widget on the right.
//
// ## Why StatelessWidget?
//
// The shell itself is stateless — all state lives either in:
//   • [StatefulNavigationShell] (which branch is active)
//   • The branch navigators themselves (scroll position, form data, etc.)
//
// The shell just wires everything together.
// ─────────────────────────────────────────────────────────────────────────────

/// The root layout scaffold for authenticated users.
///
/// Renders a [CustomNavigationRail] on the left and the currently active
/// branch widget (provided by [StatefulNavigationShell]) on the right.
///
/// ## Branch Switching
///
/// Tab switching is handled by [StatefulNavigationShell.goBranch]:
///
/// ```dart
/// navigationShell.goBranch(
///   index,
///   // initialLocation: true  ← pass this to return to branch root when
///   //                          tapping the already-active tab (optional UX).
/// );
/// ```
///
/// `goBranch` is smarter than a raw `context.go(...)`: it preserves the
/// branch's own navigator stack, so switching away from a tab and back
/// keeps any nested routes you pushed inside that tab intact.
class AppShell extends StatelessWidget {
  const AppShell({
    required this.navigationShell,
    super.key,
  });

  /// The live shell provided by [GoRouter] containing the active branch widget
  /// and branch-switching API.
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Left rail ─────────────────────────────────────────────────────
          CustomNavigationRail(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
          ),

          // ── Vertical divider between rail and content ──────────────────────
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),

          // ── Content area — the currently active branch ─────────────────────
          // [Expanded] takes all remaining horizontal space. [navigationShell]
          // renders the active branch's widget tree.
          Expanded(child: navigationShell),
        ],
      ),
    );
  }

  /// Switches the active branch to [index].
  ///
  /// Passes `initialLocation: index == navigationShell.currentIndex` so that
  /// tapping the already-active tab resets it to its root route — a common
  /// UX pattern on mobile that also works well on desktop.
  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      // When the user taps the tab they're already on, jump back to the
      // branch's initial route (e.g. from ProductDetails back to
      // ProductManagement). Remove this flag if you prefer to stay put.
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
