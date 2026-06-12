import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';

/// Domain representation of an authenticated user.
class AppUser {
  /// Creates an [AppUser] instance.
  const AppUser({
    required this.uid,
    this.email,
  });

  /// The unique identifier of the user.
  final String uid;

  /// The email address of the user.
  final String? email;
}

/// Abstract interface for authentication.
///
/// Decouples repositories and cubits from the Firebase Auth SDK.
abstract class AuthService {
  /// Stream of the user's authentication state changes.
  Stream<AppUser?> get authStateChanges;

  /// The currently authenticated user, or null if signed out.
  AppUser? get currentUser;

  /// Signs in a user using email and password.
  Future<Result<AppUser, AppError>> signIn(String email, String password);

  /// Registers a new user using email and password.
  Future<Result<AppUser, AppError>> signUp(String email, String password);

  /// Sends a password reset email.
  Future<Result<void, AppError>> sendPasswordResetEmail(String email);

  /// Logs out the user.
  Future<Result<void, AppError>> signOut();
}
