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
import 'dart:io';
import 'package:stickify/core/services/pdf_print_service.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart';
import 'package:stickify/core/services/printing/windows/windows_devmode_manager.dart';
import 'package:stickify/core/services/printing/windows/windows_paper_validator.dart';
import 'package:stickify/core/services/printing/windows/windows_print_service.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/database_search_repository.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/data/repositories/syncing_print_job_repository.dart';
import 'package:stickify/data/repositories/syncing_product_repository.dart';
import 'package:stickify/data/repositories/syncing_template_repository.dart';
import 'package:stickify/data/services/firebase_auth_service.dart';
import 'package:stickify/data/services/firestore_remote_database_service.dart';
import 'package:stickify/data/services/hive_local_database.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/l10n/l10n.dart';

/// Root application widget.
class App extends StatefulWidget {
  const App({
    super.key,
    this.auth,
    this.remoteDb,
    this.localDb,
  });

  final AuthService? auth;
  final RemoteDatabaseService? remoteDb;
  final LocalDatabase? localDb;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final LocalDatabase _database;
  late final AuthService _authService;
  late final ProductRepository _productRepository;
  late final TemplateRepository _templateRepository;
  late final PrintJobRepository _printJobRepository;
  late final SearchRepository _searchRepository;
  late final PrintService _printService;
  late final FilePickerService _filePickerService;

  @override
  void initState() {
    super.initState();
    _database = widget.localDb ?? HiveLocalDatabase();
    _database.init();

    _authService = widget.auth ?? FirebaseAuthService(auth: FirebaseAuth.instance);
    final remoteDb = widget.remoteDb ?? FirestoreRemoteDatabaseService(firestore: FirebaseFirestore.instance);

    final localProductRepo = DatabaseProductRepository(database: _database);
    final localTemplateRepo = DatabaseTemplateRepository(database: _database);
    final localPrintJobRepo = DatabasePrintJobRepository(database: _database);

    _productRepository = SyncingProductRepository(
      local: localProductRepo,
      auth: _authService,
      remoteDb: remoteDb,
      localDatabase: _database,
    );
    _templateRepository = SyncingTemplateRepository(
      local: localTemplateRepo,
      auth: _authService,
      remoteDb: remoteDb,
      localDatabase: _database,
    );
    _printJobRepository = SyncingPrintJobRepository(
      local: localPrintJobRepo,
      auth: _authService,
      remoteDb: remoteDb,
      localDatabase: _database,
    );

    _searchRepository = DatabaseSearchRepository(
      productRepository: _productRepository,
      templateRepository: _templateRepository,
    );
    final layoutEngine = const LabelPdfLayoutEngine();
    _printService = Platform.isWindows
        ? WindowsPrintService(
            layoutEngine: layoutEngine,
            paperValidator: WindowsPaperValidator(),
            devModeManager: WindowsDevModeManager(),
          )
        : PdfPrintService(layoutEngine: layoutEngine);
    _filePickerService = ImagePickerServiceImpl(ImagePicker());
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LocalDatabase>.value(value: _database),
        RepositoryProvider<AuthService>.value(value: _authService),
        RepositoryProvider<ProductRepository>.value(value: _productRepository),
        RepositoryProvider<TemplateRepository>.value(value: _templateRepository),
        RepositoryProvider<PrintJobRepository>.value(value: _printJobRepository),
        RepositoryProvider<SearchRepository>.value(value: _searchRepository),
        RepositoryProvider<PrintService>.value(value: _printService),
        RepositoryProvider<PrinterDiscoveryService>.value(value: _printService as PrinterDiscoveryService),
        RepositoryProvider<FilePickerService>.value(value: _filePickerService),
        RepositoryProvider<FeatureAccessService>(
          create: (_) => const FeatureAccessService(),
        ),
      ],
      child: BlocProvider(
        // Create the AuthCubit once for the entire app lifetime.
        create: (_) => AuthCubit(
          auth: _authService,
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
