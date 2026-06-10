import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/presentation/widgets/global_header_bar.dart';
import 'package:stickify/presentation/features/print/widgets/product_variant_selection_dialog.dart';

/// The active navigation destinations.
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

/// A responsive structural shell that wraps screen content.
///
/// Implements three layouts:
/// 1. **Desktop/4K**: Expanded sidebar (280px) + Header + Content.
/// 2. **Tablet**: Compact sidebar (72px) + Header + Content.
/// 3. **Mobile**: Top Header (AppBar) + Bottom Navigation Bar + Content.
class AdaptiveNavigationShell extends StatelessWidget {
  const AdaptiveNavigationShell({
    required this.body,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// The active view content to render.
  final Widget body;

  /// Index of the currently selected navigation branch.
  final int selectedIndex;

  /// Callback triggered when a navigation destination is selected.
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final isMobile = bp.isMobile;

    if (isMobile) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: const PreferredSize(
          preferredSize: Size.fromHeight(64),
          child: GlobalHeaderBar(),
        ),
        body: SafeArea(child: body),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          indicatorColor: Theme.of(context).colorScheme.primaryContainer,
          labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
          destinations: _kDestinations.map((d) {
            return NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon, color: Theme.of(context).colorScheme.primary),
              label: d.label,
            );
          }).toList(),
        ),
      );
    }

    final isExpanded = bp.isDesktop || bp.breakpoint.name == '4K';

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Row(
        children: [
          // Left Sidebar (Custom responsive layout matching specs)
          _CustomSidebar(
            isExtended: isExpanded,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          // Right content container
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

/// A custom responsive navigation sidebar widget.
class _CustomSidebar extends StatelessWidget {
  const _CustomSidebar({
    required this.isExtended,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final bool isExtended;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isExtended ? 280 : 72,
      color: colorScheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showText = constraints.maxWidth > 200;

          return Column(
            crossAxisAlignment: showText
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              // ── Header Branding ────────────────────────────────────────────────
              if (showText) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LabelFlow Pro',
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Warehouse Admin',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Center(
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.sticky_note_2_rounded,
                      color: colorScheme.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // ── Navigation Items ───────────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  itemCount: _kDestinations.length,
                  itemBuilder: (context, i) {
                    final d = _kDestinations[i];
                    final isSelected = selectedIndex == i;

                    return _SidebarItem(
                      icon: d.icon,
                      selectedIcon: d.selectedIcon,
                      label: d.label,
                      isExtended: showText,
                      isSelected: isSelected,
                      onTap: () => onDestinationSelected(i),
                    );
                  },
                ),
              ),

              // ── Bottom Actions ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: showText
                    ? FilledButton.icon(
                        onPressed: () => ProductVariantSelectionDialog.show(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          minimumSize: const Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.print_outlined, size: 18),
                        label: Text(
                          'Start New Print',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : FloatingActionButton(
                        onPressed: () => ProductVariantSelectionDialog.show(context),
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.print_outlined),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// An individual navigation row or tile in the custom sidebar.
class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.isExtended,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isExtended;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final itemBg = widget.isSelected
        ? colorScheme.secondaryContainer
        : _isHovered
            ? colorScheme.surfaceContainerHigh
            : Colors.transparent;

    final textColor = widget.isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          decoration: BoxDecoration(
            color: itemBg,
            border: Border(
              right: BorderSide(
                color: widget.isSelected ? colorScheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: widget.isExtended
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.isSelected ? widget.selectedIcon : widget.icon,
                color: textColor,
                size: 22,
              ),
              if (widget.isExtended) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.label,
                    style: textTheme.labelMedium?.copyWith(
                      fontFamily: 'JetBrains Mono',
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
