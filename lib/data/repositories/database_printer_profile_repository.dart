import 'package:stickify/core/core.dart';
import 'package:stickify/data/models/hive/printer_profile_hive_model.dart';
import 'package:stickify/domain/domain.dart';

/// Local storage implementation of [PrinterProfileRepository] backed by [LocalDatabase].
class DatabasePrinterProfileRepository implements PrinterProfileRepository {
  /// Creates a [DatabasePrinterProfileRepository] instance.
  DatabasePrinterProfileRepository({required LocalDatabase database}) : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'printer_profiles';

  @override
  Future<Result<PrinterProfile?, AppError>> getProfileById(String id) async {
    try {
      final model = await _db.get<PrinterProfileHiveModel>(_collection, id);
      return Result.success(model?.toDomain());
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve printer profile from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<List<PrinterProfile>, AppError>> getAllProfiles() async {
    try {
      final allModels = await _db.getAll<PrinterProfileHiveModel>(_collection);
      return Result.success(allModels.map((m) => m.toDomain()).toList());
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to retrieve printer profiles from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> saveProfile(PrinterProfile profile) async {
    try {
      await _db.save<PrinterProfileHiveModel>(
        _collection,
        profile.id,
        PrinterProfileHiveModel.fromDomain(profile),
      );
      return const Result.success(null);
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to save printer profile to database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }

  @override
  Future<Result<void, AppError>> deleteProfile(String id) async {
    try {
      await _db.delete(_collection, id);
      return const Result.success(null);
    } on AppError catch (e) {
      return Result.failure(e);
    } catch (e, stackTrace) {
      return Result.failure(DatabaseError(
        message: 'Failed to delete printer profile from database.',
        originalError: e,
        stackTrace: stackTrace,
      ));
    }
  }
}
