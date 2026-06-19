// Decoupled storage service interface meant to be swapped for cloud-based
// storage in the future, hence keeping it as a class.
// ignore_for_file: one_member_abstracts

import 'dart:io';
import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';

/// Service interface for file storage and uploads.
abstract class FileStorageService {
  /// Uploads or stores a local product image file and returns the resulting file path or URL.
  Future<Result<String, AppError>> uploadProductImage(File file);
}
