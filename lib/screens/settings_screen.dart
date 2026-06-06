import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/auth/auth.dart';

/// Settings screen — the designated place for the Logout action.
///
/// ## Architecture Note
///
/// The **Logout** button calls [AuthCubit.logout]. It does NOT call
/// `context.go(...)`. The router's `redirect` callback detects the
/// resulting [AuthUnauthenticated] state via [GoRouterRefreshStream] and
/// automatically navigates to `/login`. This pattern enforces the rule:
/// *business logic never navigates; the router does*.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Manage your account and application preferences.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Settings sections
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text('Account'),
                    subtitle: const Text('Manage your profile and credentials'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(you): Navigate to account details.
                    },
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: const Text('Appearance'),
                    subtitle: const Text('Theme and display preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(you): Navigate to appearance settings.
                    },
                  ),
                  Divider(
                    height: 1,
                    color: colorScheme.outlineVariant,
                  ),
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined),
                    title: const Text('Notifications'),
                    subtitle: const Text('Configure alerts and reminders'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO(you): Navigate to notification settings.
                    },
                  ),
                ],
              ),
            ),

            const Spacer(),

            // ── Logout Section ─────────────────────────────────────────────
            // Separated at the bottom for clear visual hierarchy.
            Card(
              child: ListTile(
                leading: Icon(Icons.logout, color: colorScheme.error),
                title: Text(
                  'Sign Out',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'You will be redirected to the login screen',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                // ── Logout Button ──────────────────────────────────────────
                // Only calls AuthCubit.logout(). The router's redirect
                // callback detects the AuthUnauthenticated state change and
                // navigates to /login automatically.
                onTap: () => context.read<AuthCubit>().logout(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
