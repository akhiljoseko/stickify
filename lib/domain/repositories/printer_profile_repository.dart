import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/printer_profile.dart';

/// Abstract repository interface for printer profile operations.
abstract interface class PrinterProfileRepository {
  /// Returns a single printer profile by its unique [id], or `null` if not found.
  Future<Result<PrinterProfile?, AppError>> getProfileById(String id);

  /// Returns all printer profiles.
  Future<Result<List<PrinterProfile>, AppError>> getAllProfiles();

  /// Saves (creates or updates) a printer profile.
  Future<Result<void, AppError>> saveProfile(PrinterProfile profile);

  /// Deletes a printer profile by its unique [id].
  Future<Result<void, AppError>> deleteProfile(String id);
}
