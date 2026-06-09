import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/presentation/widgets/notification_action_button.dart';
import 'package:stickify/presentation/widgets/profile_action_button.dart';
import 'package:stickify/presentation/widgets/search_bar_widget.dart';

/// The global top header bar widget common across all screens.
///
/// Wraps search input and user actions (Notifications, Profile) in a 64px tall
/// row with a bottom divider matching the design specifications.
class GlobalHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  const GlobalHeaderBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bp = ResponsiveBreakpoints.of(context);
    final isMobile = bp.isMobile;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Search bar (collapses dynamically internally)
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: SearchBarWidget(),
            ),
          ),
          const SizedBox(width: 12),
          // Right side: Action icons + Profile
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Notification bell
              const NotificationActionButton(),
              if (!isMobile) ...[
                const SizedBox(width: 16),
                // Help button
                IconButton(
                  icon: Icon(
                    Icons.help_outline,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  tooltip: 'Help & Documentation',
                  onPressed: () {},
                ),
              ],
              const SizedBox(width: 12),
              // Profile container with vertical divider
              Container(
                height: 32,
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: colorScheme.outlineVariant,
                    ),
                  ),
                ),
                padding: const EdgeInsets.only(left: 12),
                child: const ProfileActionButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
