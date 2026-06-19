import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';
import 'package:stickify/domain/services/file_storage_service.dart';
import 'package:uuid/uuid.dart';

/// Local filesystem implementation of [FileStorageService] (primarily used on Windows).
class LocalFileStorageService implements FileStorageService {
  /// Creates a [LocalFileStorageService] instance.
  const LocalFileStorageService();

  @override
  Future<Result<String, AppError>> uploadProductImage(File file) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}label-grid${Platform.pathSeparator}product-images',
      );

      // If the file already lives in the target directory, return it directly to avoid duplicate copying
      if (file.path.startsWith(targetDir.path)) {
        return Result.success(file.path);
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final extension = file.path.contains('.') ? file.path.split('.').last : 'png';
      final fileName = 'img_${const Uuid().v4()}.$extension';
      final targetPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

      final targetFile = await file.copy(targetPath);
      return Result.success(targetFile.path);
    } on Exception catch (e) {
      return Result.failure(UnexpectedError(message: e.toString()));
    }
  }

  @override
  Future<Result<String, AppError>> uploadTemplateImage(File file) async {
    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(
        '${docsDir.path}${Platform.pathSeparator}label-grid${Platform.pathSeparator}template-images',
      );

      // If the file already lives in the target directory, return it directly to avoid duplicate copying
      if (file.path.startsWith(targetDir.path)) {
        return Result.success(file.path);
      }

      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final extension = file.path.contains('.') ? file.path.split('.').last : 'png';
      final fileName = 'tpl_${const Uuid().v4()}.$extension';
      final targetPath = '${targetDir.path}${Platform.pathSeparator}$fileName';

      final targetFile = await file.copy(targetPath);
      return Result.success(targetFile.path);
    } on Exception catch (e) {
      return Result.failure(UnexpectedError(message: e.toString()));
    }
  }
}
