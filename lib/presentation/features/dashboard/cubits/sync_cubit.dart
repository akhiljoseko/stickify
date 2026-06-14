import 'package:bloc/bloc.dart';
import 'package:stickify/core/core.dart';
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
  final SyncableProductRepository productRepo;

  /// Repository for managing templates.
  final SyncableTemplateRepository templateRepo;

  /// Repository for managing print jobs.
  final SyncablePrintJobRepository printJobRepo;

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
      final pResult = await productRepo.sync(uid);
      if (pResult is Failure<void, AppError>) {
        emit(SyncFailure(pResult.error.message));
        return;
      }

      // 2. Sync Templates
      final tResult = await templateRepo.sync(uid);
      if (tResult is Failure<void, AppError>) {
        emit(SyncFailure(tResult.error.message));
        return;
      }

      // 3. Sync Print Jobs
      final jResult = await printJobRepo.sync(uid);
      if (jResult is Failure<void, AppError>) {
        emit(SyncFailure(jResult.error.message));
        return;
      }

      emit(const SyncSuccess());
    } on Exception catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }
}
