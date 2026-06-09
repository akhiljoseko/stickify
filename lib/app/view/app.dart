import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/routing/routing.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/auth/auth.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';
import 'package:stickify/l10n/l10n.dart';

/// Root application widget.
///
/// ## Provider Hierarchy
///
/// ```dart
/// App
/// └── BlocProvider<AuthCubit>   // provides auth state to the whole tree
///     └── _AppView              // builds the router and MaterialApp
/// ```
///
/// The [AuthCubit] must be provided **above** [MaterialApp.router] so that:
///   1. The `redirect` callback in [AppRouter.createRouter] can read the cubit
///      synchronously via the injected reference.
///   2. Screens (`LoginScreen`, `SettingsScreen`) can call
///      `context.read<AuthCubit>()` to trigger login/logout.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Create the AuthCubit once for the entire app lifetime.
      create: (_) => AuthCubit(),
      child: const _AppView(),
    );
  }
}

/// Internal widget that owns the [GoRouter] instance.
///
/// We use a separate [StatefulWidget] here so that the router is created once
/// and held in [State], avoiding re-creation on every rebuild of the parent.
/// Rebuilds of [App] (e.g. theme changes) do NOT recreate the router.
class _AppView extends StatefulWidget {
  const _AppView();

  @override
  State<_AppView> createState() => _AppViewState();
}

class _AppViewState extends State<_AppView> {
  // The router is created once in initState. It holds a reference to the
  // AuthCubit and the GoRouterRefreshStream that wraps its stream.
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // context.read is safe inside initState because the BlocProvider ancestor
    // is already mounted at this point.
    _router = AppRouter.createRouter(context.read<AuthCubit>());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stickify Industrial Canvas',

      // ── Theme ────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      // ── Localization ─────────────────────────────────────────────────────
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // ── Router ───────────────────────────────────────────────────────────
      // routerConfig is the modern API — it accepts a GoRouter directly.
      routerConfig: _router,

      // ── Responsive Framework ─────────────────────────────────────────────
      // Registers the canonical breakpoint definitions from AppBreakpoints
      // so that AdaptiveLayoutSwitcher and AdaptiveValue work in every widget
      // without any per-screen setup.
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: AppBreakpoints.breakpoints,
      ),
    );
  }
}
