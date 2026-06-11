import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:stickify/auth/auth_state.dart';
import 'package:stickify/core/services/auth_service.dart';
import 'package:stickify/core/services/local_database.dart';

/// Manages the application-wide authentication state.
class AuthCubit extends Cubit<AuthState> {
  /// Creates the [AuthCubit] and listens to the authentication state.
  AuthCubit({
    required AuthService auth,
    required LocalDatabase localDatabase,
  })  : _auth = auth,
        _localDb = localDatabase,
        super(const AuthInitial()) {
    _authStateSubscription = _auth.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _auth;
  final LocalDatabase _localDb;
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
    try {
      // Clear local database to start fresh and avoid guest data leaks
      await _clearLocalDatabase();
      await _auth.signIn(email, password);
    } on Exception catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Registers a new user using email and password.
  Future<void> register(String email, String password) async {
    emit(const AuthLoading());
    try {
      // Clear local database to start fresh
      await _clearLocalDatabase();
      await _auth.signUp(email, password);
    } on Exception catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email);
      emit(const AuthUnauthenticated());
    } on Exception catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Logs out the user.
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _auth.signOut();
    } on Exception catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _clearLocalDatabase() async {
    try {
      await _localDb.clear();
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
