import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/app.dart';
import 'package:stickify/app/routing/routing.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/auth/auth.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/platform/file_picker_service.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/l10n/l10n.dart';

/// Root application widget.
class App extends StatefulWidget {
  const App({
    required this.locator,
    super.key,
  });

  final AppServiceLocator locator;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  void dispose() {
    widget.locator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locator = widget.locator;
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalDatabase>.value(value: locator.database),
        RepositoryProvider<AuthService>.value(value: locator.authService),
        RepositoryProvider<ProductRepository>.value(value: locator.productRepository),
        RepositoryProvider<SyncableProductRepository>.value(value: locator.productRepository),
        RepositoryProvider<TemplateRepository>.value(value: locator.templateRepository),
        RepositoryProvider<SyncableTemplateRepository>.value(value: locator.templateRepository),
        RepositoryProvider<PrintJobRepository>.value(value: locator.printJobRepository),
        RepositoryProvider<VariantPrintStatsRepository>.value(value: locator.variantPrintStatsRepository),
        RepositoryProvider<SearchRepository>.value(value: locator.searchRepository),
        RepositoryProvider<PrintService>.value(value: locator.printService),
        RepositoryProvider<PrinterDiscoveryService>.value(value: locator.printService as PrinterDiscoveryService),
        RepositoryProvider<PrintJobIdGenerator>.value(value: locator.printJobIdGenerator),
        RepositoryProvider<FilePickerService>.value(value: locator.filePickerService),
        RepositoryProvider<FeatureAccessService>.value(value: locator.featureAccessService),
        RepositoryProvider<NotificationService>.value(value: locator.notificationService),
      ],
      child: BlocProvider(
        // Create the AuthCubit once for the entire app lifetime.
        create: (_) => AuthCubit(
          auth: locator.authService,
          localDatabase: locator.database,
        ),
        child: const _AppView(),
      ),
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
      themeMode: ThemeMode.light,

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
        child: Builder(
          builder: (context) {
            final environment = AppEnvironmentResolver.resolve(context);
            return RepositoryProvider<AppEnvironment>.value(
              value: environment,
              child: child,
            );
          },
        ),
        breakpoints: AppBreakpoints.breakpoints,
      ),
    );
  }
}
