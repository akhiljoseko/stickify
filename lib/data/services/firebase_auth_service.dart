import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/core/services/auth_service.dart';

/// Concrete implementation of [AuthService] powered by the Firebase Auth SDK.
class FirebaseAuthService implements AuthService {
  /// Creates a [FirebaseAuthService] backed by [auth].
  FirebaseAuthService({required FirebaseAuth auth}) : _auth = auth;

  final FirebaseAuth _auth;

  @override
  Stream<AppUser?> get authStateChanges =>
      _auth.authStateChanges().map(_mapFirebaseUser);

  @override
  AppUser? get currentUser => _mapFirebaseUser(_auth.currentUser);

  @override
  Future<AppUser?> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user);
  }

  @override
  Future<AppUser?> signUp(String email, String password) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
    );
  }
}
