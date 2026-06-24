import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/firestore/printer_profile_firestore_model.dart';
import 'package:stickify/domain/domain.dart';

/// Remote repository implementation of [PrinterProfileRepository] backed by [RemoteDatabaseService].
class FirestorePrinterProfileRepository implements PrinterProfileRepository {
  /// Creates a [FirestorePrinterProfileRepository] instance.
  FirestorePrinterProfileRepository({
    required this.remoteDb,
    required this.userId,
  });

  /// The abstract remote database service.
  final RemoteDatabaseService remoteDb;

  /// The unique identifier of the authenticated user.
  final String userId;

  String get _collectionPath => 'users/$userId/printer_profiles';

  @override
  Future<Result<PrinterProfile?, AppError>> getProfileById(String id) async {
    try {
      final data = await remoteDb.getData('$_collectionPath/$id');
      if (data == null) return const Result.success(null);
      return Result.success(PrinterProfileFirestoreModel.fromMap(id, data).toDomain());
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to retrieve printer profile from remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<List<PrinterProfile>, AppError>> getAllProfiles() async {
    try {
      final list = await remoteDb.getCollection(_collectionPath);
      final mapped = list.map((json) {
        return PrinterProfileFirestoreModel.fromMap(json['id'] as String, json).toDomain();
      }).toList();
      return Result.success(mapped);
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to retrieve printer profiles from remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> saveProfile(PrinterProfile profile) async {
    try {
      await remoteDb.setData(
        '$_collectionPath/${profile.id}',
        PrinterProfileFirestoreModel.fromDomain(profile).toMap(),
      );
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to save printer profile to remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> deleteProfile(String id) async {
    try {
      await remoteDb.deleteData('$_collectionPath/$id');
      return const Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(NetworkError(
        message: 'Failed to delete printer profile from remote server.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
