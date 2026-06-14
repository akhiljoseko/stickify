import 'package:equatable/equatable.dart';

/// Base class for all application errors.
///
/// An error holds a user-friendly [message], an optional error [code],
/// and optional original error objects and stack traces for logging.
sealed class AppError extends Equatable {
  const AppError({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  /// A user-friendly message suitable for displaying in the UI.
  final String message;

  /// An optional system/SDK error code (e.g. Firebase Auth error codes).
  final String? code;

  /// The underlying exception or error object, if any.
  final Object? originalError;

  /// The stack trace associated with the error, if any.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code, originalError, stackTrace];

  @override
  String toString() => 'AppError(message: $message, code: $code)';
}

/// Represents errors related to database or local cache operations.
final class DatabaseError extends AppError {
  const DatabaseError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Represents errors related to network/HTTP operations.
final class NetworkError extends AppError {
  const NetworkError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Represents validation errors (e.g. input fields validations).
final class ValidationError extends AppError {
  const ValidationError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Represents unexpected/unhandled errors.
final class UnexpectedError extends AppError {
  const UnexpectedError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Base class for authentication-related errors.
sealed class AuthError extends AppError {
  const AuthError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Specific authentication error subclasses:

/// Emitted when login credentials (email/password) are incorrect or invalid.
final class InvalidCredentialsError extends AuthError {
  const InvalidCredentialsError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Emitted when the requested auth account is not found.
final class AccountNotFoundError extends AuthError {
  const AccountNotFoundError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Emitted when attempting to register an email that is already registered.
final class EmailAlreadyInUseError extends AuthError {
  const EmailAlreadyInUseError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Emitted when registration fails due to a weak password.
final class WeakPasswordError extends AuthError {
  const WeakPasswordError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Represents unexpected authentication errors.
final class AuthUnexpectedError extends AuthError {
  const AuthUnexpectedError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

// ---------------------------------------------------------------------------
// Not Found Error Group
// ---------------------------------------------------------------------------

/// Base sealed class for all "entity not found" errors.
///
/// Use the specific subtype (e.g. [ProductNotFoundError]) for narrow catches
/// and [NotFoundError] as the group base for broad catches:
///
/// ```dart
/// on ProductNotFoundError catch (e) { /* product-specific handling */ }
/// on NotFoundError catch (e) { /* any not-found handling */ }
/// ```
sealed class NotFoundError extends AppError {
  const NotFoundError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Emitted when a product entity cannot be located by its identifier.
final class ProductNotFoundError extends NotFoundError {
  /// Creates a [ProductNotFoundError] for the given [productId].
  // ignore: prefer_const_constructors_in_immutables
  ProductNotFoundError({required String productId})
      : super(message: 'Product "$productId" could not be found.');
}

/// Emitted when a label template entity cannot be located by its identifier.
final class TemplateNotFoundError extends NotFoundError {
  /// Creates a [TemplateNotFoundError] for the given [templateId].
  // ignore: prefer_const_constructors_in_immutables
  TemplateNotFoundError({required String templateId})
      : super(message: 'Template "$templateId" could not be found.');
}

/// Emitted when a print job entity cannot be located by its identifier.
final class PrintJobNotFoundError extends NotFoundError {
  /// Creates a [PrintJobNotFoundError] for the given [jobId].
  // ignore: prefer_const_constructors_in_immutables
  PrintJobNotFoundError({required String jobId})
      : super(message: 'Print job "$jobId" could not be found.');
}

// ---------------------------------------------------------------------------
// Conflict Error Group
// ---------------------------------------------------------------------------

/// Base sealed class for all data conflict errors.
///
/// A conflict occurs when an operation cannot proceed because the target
/// resource is in a state that contradicts the requested change (e.g. a
/// duplicate ID, a stale write, or a merge conflict during sync).
sealed class ConflictError extends AppError {
  const ConflictError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Emitted when a sync write conflicts with a more recent remote version.
final class SyncConflictError extends ConflictError {
  /// Creates a [SyncConflictError] for a [collection] item with [id].
  // ignore: prefer_const_constructors_in_immutables
  SyncConflictError({required String collection, required String id})
      : super(
          message:
              'Sync conflict detected for "$id" in "$collection". '
              'The remote version may be newer — please sync and retry.',
        );
}

// ---------------------------------------------------------------------------
// Permission Error Group
// ---------------------------------------------------------------------------

/// Base sealed class for all permission / access-denied errors.
///
/// Distinct from [AuthError] (which represents authentication failures).
/// Permission errors occur when the user is authenticated but lacks the
/// required rights to perform an operation.
sealed class PermissionError extends AppError {
  const PermissionError({
    required super.message,
    super.code,
    super.originalError,
    super.stackTrace,
  });
}

/// Emitted when a Firestore operation is rejected by security rules.
final class FirestorePermissionError extends PermissionError {
  /// Creates a [FirestorePermissionError].
  const FirestorePermissionError({
    super.code,
    super.originalError,
    super.stackTrace,
  }) : super(
          message:
              'You do not have permission to perform this operation. '
              'Please contact your administrator.',
        );
}
