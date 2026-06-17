import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/core.dart';

/// Adaptive notification consumer that listens to [NotificationService]
/// and renders the notification using the appropriate platform pattern.
///
/// In desktop viewports the notification appears as an animated overlay in the
/// bottom-right corner.  In mobile and tablet viewports it is shown as a
/// floating [SnackBar] via [ScaffoldMessenger].
class NotificationListenerWidget extends StatefulWidget {
  /// Creates a [NotificationListenerWidget].
  const NotificationListenerWidget({super.key});

  @override
  State<NotificationListenerWidget> createState() => _NotificationListenerWidgetState();
}

class _NotificationListenerWidgetState extends State<NotificationListenerWidget>
    with SingleTickerProviderStateMixin {
  StreamSubscription<NotificationEvent>? _subscription;
  NotificationEvent? _currentEvent;
  bool _didInit = false;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      try {
        _subscription = context.read<NotificationService>().events.listen(_onEvent);
      } catch (_) {
        // NotificationService not available; skip notifications silently.
      }
    }
  }

  void _onEvent(NotificationEvent event) {
    _autoDismissTimer?.cancel();
    if (event.message.isEmpty) {
      _dismissImmediately();
      return;
    }

    setState(() => _currentEvent = event);
    _animController.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 4), _dismissAnimating);
  }

  void _dismissImmediately() {
    _animController.reset();
    setState(() => _currentEvent = null);
  }

  void _dismissAnimating() {
    _animController.reverse().then((_) {
      if (mounted) {
        setState(() => _currentEvent = null);
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _subscription?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktop = bp.breakpoint.name == AppBreakpoints.desktop ||
        bp.breakpoint.name == AppBreakpoints.fourK;

    if (isDesktop) {
      return _buildDesktopOverlay();
    }
    return _buildSnackBarListener();
  }

  Widget _buildDesktopOverlay() {
    if (_currentEvent == null) return const SizedBox.shrink();

    return Stack(
      children: [
        Positioned(
          right: 24,
          bottom: 24,
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _NotificationCard(
                event: _currentEvent!,
                onDismiss: _dismissAnimating,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSnackBarListener() {
    if (_currentEvent == null) return const SizedBox.shrink();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(_buildSnackBar(_currentEvent!));
      setState(() => _currentEvent = null);
    });

    return const SizedBox.shrink();
  }

  SnackBar _buildSnackBar(NotificationEvent event) {
    return SnackBar(
      content: Row(
        children: [
          Icon(_iconForLevel(event.level), size: 20, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(child: Text(event.message)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
            child: const Icon(Icons.close, size: 18, color: Colors.white70),
          ),
        ],
      ),
      backgroundColor: _colorForLevel(event.level),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

/// Desktop card-style notification popup.
class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.event, required this.onDismiss});

  final NotificationEvent event;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _colorForLevel(event.level);
    final icon = _iconForLevel(event.level);

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: color,
      surfaceTintColor: color,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (event.title != null)
                    Text(
                      event.title!,
                      style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
                    ),
                  Text(
                    event.message,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: Colors.white.withValues(alpha: 0.8), size: 20),
            ),
          ],
        ),
      ),
    );
  }
}

Color _colorForLevel(NotificationLevel level) {
  // Return a semi-transparent color; the caller can wrap in Material for
  // the actual surface tint.  These are all dark-ish so white text works.
  switch (level) {
    case NotificationLevel.success:
      return const Color(0xFF2E7D32); // green 800
    case NotificationLevel.info:
      return const Color(0xFF1565C0); // blue 800
    case NotificationLevel.warning:
      return const Color(0xFFF57F17); // amber 900
    case NotificationLevel.error:
      return const Color(0xFFC62828); // red 800
  }
}

IconData _iconForLevel(NotificationLevel level) {
  switch (level) {
    case NotificationLevel.success:
      return Icons.check_circle;
    case NotificationLevel.info:
      return Icons.info_outline;
    case NotificationLevel.warning:
      return Icons.warning_amber_rounded;
    case NotificationLevel.error:
      return Icons.error_outline;
  }
}
