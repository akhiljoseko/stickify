import 'dart:io';
import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';
import 'package:stickify/domain/services/file_storage_service.dart';

/// Fallback implementation of [FileStorageService] that throws an UnimplementedError on other platforms.
class UnimplementedFileStorageService implements FileStorageService {
  /// Creates an [UnimplementedFileStorageService] instance.
  const UnimplementedFileStorageService();

  @override
  Future<Result<String, AppError>> uploadProductImage(File file) {
    throw UnimplementedError('FileStorageService is only implemented for Windows.');
  }
}
