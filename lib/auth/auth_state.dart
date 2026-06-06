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
///
/// Use this to show a splash / loading screen before the real auth status
/// has been determined (e.g. while reading a persisted token from storage).
/// In this mock implementation the cubit immediately transitions to
/// `AuthUnauthenticated`, so this state is transient.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Emitted when the user has successfully authenticated.
///
/// Carry any user-specific data you need throughout the app here, e.g.
/// a `User` model with the display name and avatar URL. For now it is
/// kept intentionally minimal to focus on routing architecture.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated();
}

/// Emitted when the user is not authenticated (logged out or session expired).
///
/// The `GoRouter` redirect callback checks for this state and sends the
/// user to the `/login` route whenever they try to reach a protected path.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}
