import 'package:flutter/material.dart';
import 'package:stickify/presentation/navigation/adaptive_app_shell.dart';

/// Custom sidebar navigation pane used on tablet and desktop viewports.
class CustomSidebar extends StatelessWidget {
  /// Creates a [CustomSidebar].
  const CustomSidebar({
    required this.isExtended,
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  });

  /// Whether the sidebar is expanded (desktop style) or compact (tablet style).
  final bool isExtended;

  /// Active selected branch index.
  final int selectedIndex;

  /// Callback to switch navigation branches.
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
              // Header branding logo
              if (showText) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
              ] else ...[
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
              const SizedBox(height: 40),

              // Navigation Links
              Expanded(
                child: ListView.builder(
                  itemCount: kAppNavDestinations.length,
                  itemBuilder: (context, i) {
                    final d = kAppNavDestinations[i];
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

              // Powered by tag at the bottom
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showText ? 24.0 : 4.0,
                  vertical: showText ? 16.0 : 8.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: showText
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    Text(
                      'POWERED BY',
                      style: textTheme.labelSmall?.copyWith(
                        fontSize: showText ? 9.0 : 7.5,
                        letterSpacing: showText ? 1.0 : 0.5,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                      ),
                      textAlign: showText ? TextAlign.left : TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Image.asset(
                      Theme.of(context).brightness == Brightness.dark
                          ? 'assets/inevitable-logo-dark.png'
                          : 'assets/inevitable-logo.png',
                      height: showText ? 40 : 16,
                      width: showText ? null : 56,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

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
                color: widget.isSelected
                    ? colorScheme.primary
                    : Colors.transparent,
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
                      fontWeight: widget.isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
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
