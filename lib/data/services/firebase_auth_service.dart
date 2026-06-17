import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/core/error/app_error.dart';
import 'package:stickify/core/error/result.dart';
import 'package:stickify/domain/domain.dart';

/// Concrete implementation of [AuthService] powered by the Firebase Auth SDK.
class FirebaseAuthService implements AuthService {
  /// Creates a [FirebaseAuthService].
  FirebaseAuthService({required this.auth});

  final FirebaseAuth auth;

  @override
  Stream<AppUser?> get authStateChanges =>
      auth.authStateChanges().map(_mapFirebaseUser);

  @override
  AppUser? get currentUser => _mapFirebaseUser(auth.currentUser);

  @override
  Future<Result<AppUser, AppError>> signIn(
    String email,
    String password,
  ) async {
    try {
      final credential = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final mapped = _mapFirebaseUser(credential.user);
      if (mapped != null) {
        return Result.success(mapped);
      } else {
        return const Result.failure(
          AuthUnexpectedError(
            message: 'User session could not be established after login.',
          ),
        );
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(_mapGenericException(e, stackTrace));
    }
  }

  @override
  Future<Result<AppUser, AppError>> signUp(
    String email,
    String password,
  ) async {
    try {
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final mapped = _mapFirebaseUser(credential.user);
      if (mapped != null) {
        return Result.success(mapped);
      } else {
        return const Result.failure(
          AuthUnexpectedError(
            message: 'User session could not be established after sign up.',
          ),
        );
      }
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(_mapGenericException(e, stackTrace));
    }
  }

  @override
  Future<Result<void, AppError>> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      return const Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(_mapGenericException(e, stackTrace));
    }
  }

  @override
  Future<Result<void, AppError>> signOut() async {
    try {
      await auth.signOut();
      return const Result.success(null);
    } on FirebaseAuthException catch (e, stackTrace) {
      return Result.failure(_mapFirebaseAuthException(e, stackTrace));
    } catch (e, stackTrace) {
      return Result.failure(_mapGenericException(e, stackTrace));
    }
  }

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
    );
  }

  AppError _mapFirebaseAuthException(
    FirebaseAuthException e,
    StackTrace stackTrace,
  ) {
    final message = e.message ?? 'Authentication failed';
    switch (e.code) {
      case 'invalid-email':
      case 'wrong-password':
      case 'invalid-credential':
        return InvalidCredentialsError(
          message: 'Invalid email or password. Please try again.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'user-not-found':
        return AccountNotFoundError(
          message: 'No account found with this email.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'email-already-in-use':
        return EmailAlreadyInUseError(
          message: 'This email address is already in use by another account.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      case 'weak-password':
        return WeakPasswordError(
          message: 'The password is too weak. Please use a stronger password.',
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
      default:
        return AuthUnexpectedError(
          message: message,
          code: e.code,
          originalError: e,
          stackTrace: stackTrace,
        );
    }
  }

  AppError _mapGenericException(Object e, StackTrace stackTrace) {
    return AuthUnexpectedError(
      message: 'An unexpected authentication error occurred. Please try again.',
      originalError: e,
      stackTrace: stackTrace,
    );
  }
}
