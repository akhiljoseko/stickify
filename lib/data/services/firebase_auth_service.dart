import 'package:firebase_auth/firebase_auth.dart';
import 'package:stickify/core/services/auth_service.dart';

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
  Future<AppUser?> signIn(String email, String password) async {
    final credential = await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user);
  }

  @override
  Future<AppUser?> signUp(String email, String password) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _mapFirebaseUser(credential.user);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await auth.signOut();
  }

  AppUser? _mapFirebaseUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email,
    );
  }
}
