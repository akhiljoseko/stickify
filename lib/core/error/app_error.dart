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
