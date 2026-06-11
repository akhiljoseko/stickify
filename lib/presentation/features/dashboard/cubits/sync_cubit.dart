import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/data/repositories/syncing_print_job_repository.dart';
import 'package:stickify/data/repositories/syncing_product_repository.dart';
import 'package:stickify/data/repositories/syncing_template_repository.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';

/// Cubit responsible for managing manual local-remote synchronization workflow.
class SyncCubit extends Cubit<SyncState> {
  /// Creates a [SyncCubit] instance.
  SyncCubit({
    required ProductRepository productRepository,
    required TemplateRepository templateRepository,
    required PrintJobRepository printJobRepository,
    required FirebaseAuth auth,
  })  : _productRepo = productRepository,
        _templateRepo = templateRepository,
        _printJobRepo = printJobRepository,
        _auth = auth,
        super(const SyncInitial());

  final ProductRepository _productRepo;
  final TemplateRepository _templateRepo;
  final PrintJobRepository _printJobRepo;
  final FirebaseAuth _auth;

  /// Pulls remote Firestore updates and overwrites the local cache database.
  Future<void> syncData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(const SyncFailure('User is not authenticated.'));
      return;
    }

    emit(const SyncLoading());

    try {
      // 1. Sync Products
      final pRepo = _productRepo;
      if (pRepo is SyncingProductRepository) {
        await pRepo.sync(uid);
      }

      // 2. Sync Templates
      final tRepo = _templateRepo;
      if (tRepo is SyncingTemplateRepository) {
        await tRepo.sync(uid);
      }

      // 3. Sync Print Jobs
      final jRepo = _printJobRepo;
      if (jRepo is SyncingPrintJobRepository) {
        await jRepo.sync(uid);
      }

      emit(const SyncSuccess());
    } catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }
}
