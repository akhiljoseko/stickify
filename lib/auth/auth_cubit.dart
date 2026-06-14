import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:stickify/auth/auth_state.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';

/// Manages the application-wide authentication state.
class AuthCubit extends Cubit<AuthState> {
  /// Creates the [AuthCubit] and listens to the authentication state.
  AuthCubit({
    required this.auth,
    required this.localDatabase,
  })  : super(const AuthInitial()) {
    _authStateSubscription = auth.authStateChanges.listen(_onAuthStateChanged);
  }

  /// Interface for managing auth states.
  final AuthService auth;

  /// Interface for managing local database operations.
  final LocalDatabase localDatabase;

  late final StreamSubscription<AppUser?> _authStateSubscription;

  void _onAuthStateChanged(AppUser? user) {
    if (user != null) {
      emit(AuthAuthenticated(uid: user.uid, email: user.email));
    } else {
      emit(const AuthUnauthenticated());
    }
  }

  /// Signs in a user using email and password.
  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    // Clear local database to start fresh and avoid guest data leaks
    await _clearLocalDatabase();
    final result = await auth.signIn(email, password);
    switch (result) {
      case Success():
        // authStateChanges will trigger and emit AuthAuthenticated
        break;
      case Failure(error: final err):
        emit(AuthFailure(err.message));
    }
  }

  /// Registers a new user using email and password.
  Future<void> register(String email, String password) async {
    emit(const AuthLoading());
    // Clear local database to start fresh
    await _clearLocalDatabase();
    final result = await auth.signUp(email, password);
    switch (result) {
      case Success():
        // authStateChanges will trigger and emit AuthAuthenticated
        break;
      case Failure(error: final err):
        emit(AuthFailure(err.message));
    }
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());
    final result = await auth.sendPasswordResetEmail(email);
    switch (result) {
      case Success():
        emit(const AuthUnauthenticated());
      case Failure(error: final err):
        emit(AuthFailure(err.message));
    }
  }

  /// Logs out the user.
  Future<void> logout() async {
    emit(const AuthLoading());
    final result = await auth.signOut();
    switch (result) {
      case Success():
        // authStateChanges will trigger and emit AuthUnauthenticated
        break;
      case Failure(error: final err):
        emit(AuthFailure(err.message));
    }
  }

  Future<void> _clearLocalDatabase() async {
    try {
      await localDatabase.clear();
    } on Exception catch (_) {
      // Ignore directory cleanup exceptions silently
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
