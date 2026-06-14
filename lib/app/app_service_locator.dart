import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/platform/file_picker_service.dart';
import 'package:stickify/core/services/pdf_print_service.dart';
import 'package:stickify/core/services/print_job/timestamp_print_job_id_generator.dart';
import 'package:stickify/core/services/printing/label_pdf_layout_engine.dart';
import 'package:stickify/core/services/printing/windows/windows_devmode_manager.dart';
import 'package:stickify/core/services/printing/windows/windows_paper_validator.dart';
import 'package:stickify/core/services/printing/windows/windows_print_service.dart';
import 'package:stickify/data/repositories/database_print_job_repository.dart';
import 'package:stickify/data/repositories/database_product_repository.dart';
import 'package:stickify/data/repositories/database_search_repository.dart';
import 'package:stickify/data/repositories/database_template_repository.dart';
import 'package:stickify/data/repositories/firestore_print_job_repository.dart';
import 'package:stickify/data/repositories/firestore_product_repository.dart';
import 'package:stickify/data/repositories/firestore_template_repository.dart';
import 'package:stickify/data/repositories/syncing_print_job_repository.dart';
import 'package:stickify/data/repositories/syncing_product_repository.dart';
import 'package:stickify/data/repositories/syncing_template_repository.dart';
import 'package:stickify/data/services/firebase_auth_service.dart';
import 'package:stickify/data/services/firestore_remote_database_service.dart';
import 'package:stickify/data/services/hive_local_database.dart';
import 'package:stickify/data/services/hive_sync_queue.dart';
import 'package:stickify/domain/domain.dart';

/// Centralized Dependency Injection container and service locator.
class AppServiceLocator {
  AppServiceLocator._({
    required this.database,
    required this.authService,
    required this.productRepository,
    required this.templateRepository,
    required this.printJobRepository,
    required this.searchRepository,
    required this.printService,
    required this.filePickerService,
    required this.printJobIdGenerator,
    required this.featureAccessService,
    required StreamSubscription<AppUser?> authSubscription,
  }) : _authSubscription = authSubscription;

  /// Async factory to build and initialize all dependencies.
  static Future<AppServiceLocator> create({
    LocalDatabase? localDbOverride,
    AuthService? authServiceOverride,
    RemoteDatabaseService? remoteDbOverride,
  }) async {
    final database = localDbOverride ?? HiveLocalDatabase();
    await database.init();

    final authService = authServiceOverride ?? FirebaseAuthService(auth: FirebaseAuth.instance);
    final remoteDb = remoteDbOverride ?? FirestoreRemoteDatabaseService(firestore: FirebaseFirestore.instance);

    final localProductRepo = DatabaseProductRepository(database: database);
    final localTemplateRepo = DatabaseTemplateRepository(database: database);
    final localPrintJobRepo = DatabasePrintJobRepository(database: database);
    final syncQueue = HiveSyncQueue(database: database);

    final productRepository = SyncingProductRepository(
      local: localProductRepo,
      syncQueue: syncQueue,
    );
    final templateRepository = SyncingTemplateRepository(
      local: localTemplateRepo,
      syncQueue: syncQueue,
    );
    final printJobRepository = SyncingPrintJobRepository(
      local: localPrintJobRepo,
      syncQueue: syncQueue,
      localDatabase: database,
    );

    final searchRepository = DatabaseSearchRepository(
      productRepository: productRepository,
      templateRepository: templateRepository,
    );

    const layoutEngine = LabelPdfLayoutEngine();
    final PrintService printService = Platform.isWindows
        ? WindowsPrintService(
            layoutEngine: layoutEngine,
            paperValidator: WindowsPaperValidator(),
            devModeManager: WindowsDevModeManager(),
          )
        : const PdfPrintService(layoutEngine: layoutEngine);

    final filePickerService = ImagePickerServiceImpl(ImagePicker());
    final printJobIdGenerator = const TimestampPrintJobIdGenerator();
    const featureAccessService = FeatureAccessService();

    final authSubscription = authService.authStateChanges.listen((user) {
      if (user != null) {
        final uid = user.uid;
        productRepository.remote = FirestoreProductRepository(remoteDb: remoteDb, userId: uid);
        templateRepository.remote = FirestoreTemplateRepository(remoteDb: remoteDb, userId: uid);
        printJobRepository.remote = FirestorePrintJobRepository(remoteDb: remoteDb, userId: uid);
      } else {
        productRepository.remote = null;
        templateRepository.remote = null;
        printJobRepository.remote = null;
      }
    });

    // Initial auth sync state setup
    final currentUser = authService.currentUser;
    if (currentUser != null) {
      productRepository.remote = FirestoreProductRepository(remoteDb: remoteDb, userId: currentUser.uid);
      templateRepository.remote = FirestoreTemplateRepository(remoteDb: remoteDb, userId: currentUser.uid);
      printJobRepository.remote = FirestorePrintJobRepository(remoteDb: remoteDb, userId: currentUser.uid);
    }

    return AppServiceLocator._(
      database: database,
      authService: authService,
      productRepository: productRepository,
      templateRepository: templateRepository,
      printJobRepository: printJobRepository,
      searchRepository: searchRepository,
      printService: printService,
      filePickerService: filePickerService,
      printJobIdGenerator: printJobIdGenerator,
      featureAccessService: featureAccessService,
      authSubscription: authSubscription,
    );
  }

  /// The local database instance.
  final LocalDatabase database;

  /// The authentication service.
  final AuthService authService;

  /// The syncing product repository.
  final SyncableProductRepository productRepository;

  /// The syncing template repository.
  final SyncableTemplateRepository templateRepository;

  /// The syncing print job repository.
  final SyncablePrintJobRepository printJobRepository;

  /// The database search repository.
  final SearchRepository searchRepository;

  /// The printing service.
  final PrintService printService;

  /// The file picking service.
  final FilePickerService filePickerService;

  /// The printing job ID generator.
  final PrintJobIdGenerator printJobIdGenerator;

  /// The feature access service.
  final FeatureAccessService featureAccessService;

  final StreamSubscription<AppUser?> _authSubscription;

  /// Clean up subscriptions and release resources.
  void dispose() {
    _authSubscription.cancel();
  }
}
