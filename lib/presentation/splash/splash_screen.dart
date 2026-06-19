import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/auth/auth.dart';

/// Splash screen displayed on initial application load.
/// Shows the logo for at least 2 seconds while checking the auth status.
class SplashScreen extends StatefulWidget {
  /// Creates a [SplashScreen] instance.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
    _initializeAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeAndNavigate() async {
    final startTime = DateTime.now();

    // Wait until AuthCubit state is not AuthInitial
    final authCubit = context.read<AuthCubit>();
    if (authCubit.state is AuthInitial) {
      final completer = Completer<void>();
      final subscription = authCubit.stream.listen((state) {
        if (state is! AuthInitial && !completer.isCompleted) {
          completer.complete();
        }
      });
      if (authCubit.state is! AuthInitial && !completer.isCompleted) {
        completer.complete();
      }
      await completer.future;
      unawaited(subscription.cancel());
    }

    // Calculate remaining time for the 2-second minimum splash
    final elapsed = DateTime.now().difference(startTime);
    final remaining = const Duration(seconds: 2) - elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    if (!mounted) return;

    final finalState = authCubit.state;
    if (finalState is AuthAuthenticated) {
      context.go('/dashboard');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Stack(
              children: [
                // Center Content
                Align(
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Larger Logo Image in the Center
                          Image.asset(
                            'assets/logo.png',
                            width: 260,
                            height: 260,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.grid_view_rounded,
                                size: 160,
                                color: colorScheme.primary,
                              );
                            },
                          ),
                          const SizedBox(height: 48),
                          // Modern, subtle progress indicator
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.primary.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Powered by tag at the bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'POWERED BY',
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 8.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Image.asset(
                            Theme.of(context).brightness == Brightness.dark
                                ? 'assets/inevitable-logo-dark.png'
                                : 'assets/inevitable-logo.png',
                            height: 20,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
