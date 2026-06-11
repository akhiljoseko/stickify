import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/auth/auth_state.dart';
import 'package:stickify/core/services/document_database.dart';

/// Manages the application-wide authentication state.
class AuthCubit extends Cubit<AuthState> {
  /// Creates the [AuthCubit] and listens to the Firebase authentication state.
  AuthCubit({
    required FirebaseAuth auth,
    required DocumentDatabase localDatabase,
  })  : _auth = auth,
        _localDb = localDatabase,
        super(const AuthInitial()) {
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  final FirebaseAuth _auth;
  final DocumentDatabase _localDb;
  late final StreamSubscription<User?> _authStateSubscription;

  void _onAuthStateChanged(User? user) {
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
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Authentication failed'));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Registers a new user using email and password.
  Future<void> register(String email, String password) async {
    emit(const AuthLoading());
    try {
      // Clear local database to start fresh
      await _clearLocalDatabase();
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Registration failed'));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    emit(const AuthLoading());
    try {
      await _auth.sendPasswordResetEmail(email: email);
      emit(const AuthUnauthenticated());
    } on FirebaseAuthException catch (e) {
      emit(AuthFailure(e.message ?? 'Password reset failed'));
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Logs out the user from Firebase.
  Future<void> logout() async {
    emit(const AuthLoading());
    try {
      await _auth.signOut();
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _clearLocalDatabase() async {
    try {
      await _localDb.clear();
    } catch (_) {
      // Ignore directory cleanup exceptions silently
    }
  }

  @override
  Future<void> close() {
    _authStateSubscription.cancel();
    return super.close();
  }
}
