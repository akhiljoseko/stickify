import 'package:flutter/material.dart';

/// Dashboard screen — the default landing page after login.
///
/// Replace the placeholder content with real dashboard widgets (charts,
/// KPI cards, activity feeds, etc.) as the product evolves.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
            Text('Dashboard', style: textTheme.displayLarge),
            const SizedBox(height: 8),
            Text(
              'Welcome back! Here is your overview.',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            // Placeholder KPI cards
            Row(
              children: [
                _KpiCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Products',
                  value: '128',
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: Icons.layers_outlined,
                  label: 'Templates',
                  value: '34',
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 16),
                _KpiCard(
                  icon: Icons.check_circle_outline,
                  label: 'Active Jobs',
                  value: '7',
                  color: colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: textTheme.headlineMedium),
                  Text(
                    label,
                    style: textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
