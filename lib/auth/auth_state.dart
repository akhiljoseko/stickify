/// Defines all possible authentication states for the application.
///
/// This is a sealed class, meaning the compiler knows all possible subtypes.
/// This enables exhaustive pattern-matching in switch expressions elsewhere
/// in the app (e.g. the GoRouter redirect callback) without needing a default
/// case — the compiler will warn if a subtype is unhandled.
sealed class AuthState {
  const AuthState();
}

/// The initial state emitted when the `AuthCubit` is first created.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Emitted when an authentication operation is in progress (e.g. logging in or registering).
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Emitted when the user has successfully authenticated.
final class AuthAuthenticated extends AuthState {
  final String uid;
  final String? email;

  const AuthAuthenticated({
    required this.uid,
    this.email,
  });
}

/// Emitted when the user is not authenticated (logged out or session expired).
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Emitted when an authentication operation fails with an error.
final class AuthFailure extends AuthState {
  final String message;

  const AuthFailure(this.message);
}
