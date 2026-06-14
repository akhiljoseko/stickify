// The initializer list pattern `_field = param` is intentional: constructor
// parameter names must stay public (e.g. `productRepo`) to provide a clean
// named-parameter API for call sites, while field names are private (`_productRepo`)
// to enforce encapsulation. Using `this._field` initializing formals would
// expose underscore-prefixed names in the public constructor API.
// ignore_for_file: prefer_initializing_formals
import 'package:bloc/bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/cubits/sync_state.dart';

/// Cubit responsible for managing manual local-remote synchronization workflow.
class SyncCubit extends Cubit<SyncState> {
  /// Creates a [SyncCubit] instance.
  SyncCubit({
    required SyncableProductRepository productRepo,
    required SyncableTemplateRepository templateRepo,
    required SyncablePrintJobRepository printJobRepo,
    required AuthService auth,
  })  : _productRepo = productRepo,
        _templateRepo = templateRepo,
        _printJobRepo = printJobRepo,
        _auth = auth,
        super(const SyncInitial());

  /// Repository for managing products.
  final SyncableProductRepository _productRepo;

  /// Repository for managing templates.
  final SyncableTemplateRepository _templateRepo;

  /// Repository for managing print jobs.
  final SyncablePrintJobRepository _printJobRepo;

  /// Interface for managing auth states.
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
      // 1. Sync Products
      final pResult = await _productRepo.sync(uid);
      if (pResult is Failure<void, AppError>) {
        emit(SyncFailure(pResult.error.message));
        return;
      }

      // 2. Sync Templates
      final tResult = await _templateRepo.sync(uid);
      if (tResult is Failure<void, AppError>) {
        emit(SyncFailure(tResult.error.message));
        return;
      }

      // 3. Sync Print Jobs
      final jResult = await _printJobRepo.sync(uid);
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
