// Connectivity chip: doc comments reference types outside doc scope.
// prefer_int_literals: opacity is typed double and cannot use int literals.
// ignore_for_file: comment_references
import 'dart:async';

import 'package:flutter/material.dart';

/// A small status chip showing the printer network connectivity state.
///
/// Displays a pulsing green dot with "Online" text when connected, or a
/// static amber/red dot with corresponding text for warning/offline states.
///
/// **Stitch spec:** `bg-surface-container-lowest border border-outline-variant
/// p-4 rounded-xl` with `cloud_done` icon in emerald, pulsing status dot.
///
/// This widget is stateless and fully driven by the [isOnline] flag. Future
/// versions can accept a [ConnectivityStatus] enum from the domain layer.
class ConnectivityStatusChip extends StatefulWidget {
  const ConnectivityStatusChip({
    required this.isOnline,
    super.key,
  });

  /// Whether the printer network is currently reachable.
  final bool isOnline;

  @override
  State<ConnectivityStatusChip> createState() => _ConnectivityStatusChipState();
}

class _ConnectivityStatusChipState extends State<ConnectivityStatusChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    unawaited(_pulseController.repeat(reverse: true));

    _pulseAnimation = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Emerald green for online, amber for offline
    const onlineColor = Color(0xFF10B981);
    const offlineColor = Color(0xFFF59E0B);
    final dotColor = widget.isOnline ? onlineColor : offlineColor;
    final statusLabel = widget.isOnline ? 'Online' : 'Offline';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cloud / connectivity icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: onlineColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              widget.isOnline ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color: onlineColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connectivity',
                style: textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  // Pulsing dot — only animates when online
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, _) {
                      return Opacity(
                        opacity: widget.isOnline ? _pulseAnimation.value : 1,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusLabel,
                    style: textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
