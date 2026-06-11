import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/routing/routing.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/auth/auth.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/platform/file_picker_service.dart';
import 'package:stickify/core/services/document_database.dart';
import 'package:stickify/core/services/pdf_print_service.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/database_search_repository.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/data/repositories/syncing_print_job_repository.dart';
import 'package:stickify/data/repositories/syncing_product_repository.dart';
import 'package:stickify/data/repositories/syncing_template_repository.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/l10n/l10n.dart';

/// Root application widget.
///
/// ## Provider Hierarchy
///
/// ```dart
/// App
/// └── MultiRepositoryProvider
///     ├── RepositoryProvider<DocumentDatabase>
///     ├── RepositoryProvider<ProductRepository>
///     ├── RepositoryProvider<TemplateRepository>
///     ├── RepositoryProvider<PrintJobRepository>
///     └── RepositoryProvider<SearchRepository>
///         └── BlocProvider<AuthCubit>   // provides auth state to the whole tree
///             └── _AppView              // builds the router and MaterialApp
/// ```
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final DocumentDatabase _database;
  late final ProductRepository _productRepository;
  late final TemplateRepository _templateRepository;
  late final PrintJobRepository _printJobRepository;
  late final SearchRepository _searchRepository;
  late final PrintService _printService;
  late final FilePickerService _filePickerService;

  @override
  void initState() {
    super.initState();
    _database = DocumentDatabase();
    
    final localProductRepo = DatabaseProductRepository(database: _database);
    final localTemplateRepo = DatabaseTemplateRepository(database: _database);
    final localPrintJobRepo = DatabasePrintJobRepository(database: _database);

    _productRepository = SyncingProductRepository(
      local: localProductRepo,
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );
    _templateRepository = SyncingTemplateRepository(
      local: localTemplateRepo,
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      localDatabase: _database,
    );
    _printJobRepository = SyncingPrintJobRepository(
      local: localPrintJobRepo,
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
      localDatabase: _database,
    );

    _searchRepository = DatabaseSearchRepository(
      productRepository: _productRepository,
      templateRepository: _templateRepository,
    );
    _printService = const PdfPrintService();
    _filePickerService = ImagePickerServiceImpl(ImagePicker());
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<DocumentDatabase>.value(value: _database),
        RepositoryProvider<ProductRepository>.value(value: _productRepository),
        RepositoryProvider<TemplateRepository>.value(value: _templateRepository),
        RepositoryProvider<PrintJobRepository>.value(value: _printJobRepository),
        RepositoryProvider<SearchRepository>.value(value: _searchRepository),
        RepositoryProvider<PrintService>.value(value: _printService),
        RepositoryProvider<FilePickerService>.value(value: _filePickerService),
        RepositoryProvider<FeatureAccessService>(
          create: (_) => const FeatureAccessService(),
        ),
      ],
      child: BlocProvider(
        // Create the AuthCubit once for the entire app lifetime.
        create: (_) => AuthCubit(
          auth: FirebaseAuth.instance,
          localDatabase: _database,
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
