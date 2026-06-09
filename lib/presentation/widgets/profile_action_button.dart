import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// A styled profile action button that adapts to screen breakpoints.
///
/// On Desktop / widescreen layouts, it renders the avatar image alongside
/// the user's name and role. On smaller devices, it renders only the avatar.
/// Uses [MouseRegion] to apply a light surface tint on hover.
class ProfileActionButton extends StatefulWidget {
  const ProfileActionButton({super.key});

  @override
  State<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends State<ProfileActionButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.isDesktop || bp.breakpoint.name == '4K';

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile settings clicked')),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _isHovered
                ? colorScheme.surfaceContainerHigh
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.network(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBqNDgzMCNn1yB_lXkjwLsHu-65es3Qshb620ibPKD1XxEIAteRKunu42hB2z1Zv8tB0hWFqJLFn5TcJFqW88IO4yzCzHt8HFtSNxPircSBuiDCX4-HOrMA6BhJmS8RiSeD0_48ZD-d6BPjvMtvLLxAd3BLi5PA8z29i0QKDc0nC9FR443kSy2bClVvHU7H0mcQO7jFnZ4MCC51CbsgB7XEruuQNZZjB-0nH-FUZSNzvCf5abG62N7L_zQimkr3V5I0d2c_EE0acyU',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.person, size: 18);
                    },
                  ),
                ),
              ),
              if (isDesktop) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Alex Miller',
                      style: textTheme.labelMedium?.copyWith(
                        fontFamily: 'JetBrains Mono',
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ADMIN LEVEL 4',
                      style: textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
