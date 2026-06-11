import 'package:bloc/bloc.dart';
import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/data/repositories/syncing_print_job_repository.dart';
import 'package:stickify/data/repositories/syncing_product_repository.dart';
import 'package:stickify/data/repositories/syncing_template_repository.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';

/// Cubit responsible for managing manual local-remote synchronization workflow.
class SyncCubit extends Cubit<SyncState> {
  /// Creates a [SyncCubit] instance.
  SyncCubit({
    required this.productRepo,
    required this.templateRepo,
    required this.printJobRepo,
    required this.auth,
  }) : super(const SyncInitial());

  /// Repository for managing products.
  final ProductRepository productRepo;

  /// Repository for managing templates.
  final TemplateRepository templateRepo;

  /// Repository for managing print jobs.
  final PrintJobRepository printJobRepo;

  /// Interface for managing auth states.
  final AuthService auth;

  /// Pulls remote Firestore updates and overwrites the local cache database.
  Future<void> syncData() async {
    final uid = auth.currentUser?.uid;
    if (uid == null) {
      emit(const SyncFailure('User is not authenticated.'));
      return;
    }

    emit(const SyncLoading());

    try {
      // 1. Sync Products
      final pRepo = productRepo;
      if (pRepo is SyncingProductRepository) {
        await pRepo.sync(uid);
      }

      // 2. Sync Templates
      final tRepo = templateRepo;
      if (tRepo is SyncingTemplateRepository) {
        await tRepo.sync(uid);
      }

      // 3. Sync Print Jobs
      final jRepo = printJobRepo;
      if (jRepo is SyncingPrintJobRepository) {
        await jRepo.sync(uid);
      }

      emit(const SyncSuccess());
    } on Exception catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }
}
