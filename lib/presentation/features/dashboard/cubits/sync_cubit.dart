import 'package:bloc/bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';

/// Cubit responsible for managing manual local-remote synchronization workflow.
class SyncCubit extends Cubit<SyncState> {
  /// Creates a [SyncCubit] instance.
  SyncCubit({
    required this._productRepo,
    required this._templateRepo,
    required this._printerProfileRepo,
    required this._auth,
  })  : super(const SyncInitial());

  final SyncableProductRepository _productRepo;
  final SyncableTemplateRepository _templateRepo;
  final SyncablePrinterProfileRepository _printerProfileRepo;
  final AuthService _auth;

  /// Pulls remote Firestore updates and overwrites the local cache database.
  Future<void> syncData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(const SyncFailure('User is not authenticated.'));
      return;
    }

    emit(const SyncLoading());

    try {
      final pResult = await _productRepo.sync(uid);
      if (pResult is Failure<void, AppError>) {
        emit(SyncFailure(pResult.error.message));
        return;
      }

      final tResult = await _templateRepo.sync(uid);
      if (tResult is Failure<void, AppError>) {
        emit(SyncFailure(tResult.error.message));
        return;
      }

      final printerResult = await _printerProfileRepo.sync(uid);
      if (printerResult is Failure<void, AppError>) {
        emit(SyncFailure(printerResult.error.message));
        return;
      }

      emit(const SyncSuccess());
    } on Exception catch (e) {
      emit(SyncFailure(e.toString()));
    }
  }
}
