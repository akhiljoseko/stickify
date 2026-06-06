import 'package:bloc/bloc.dart';
import 'package:stickify/auth/auth_state.dart';

/// Manages the application-wide authentication state.
///
/// ## Architecture Contract
///
/// The [AuthCubit] is the **single source of truth** for whether the current
/// user is logged in or not. It intentionally knows nothing about routing:
/// it only emits state. The `GoRouter` (configured in `router.dart`) listens
/// to this cubit's stream via a `GoRouterRefreshStream` and calls its
/// `redirect` callback every time a new [AuthState] is emitted. This
/// separation of concerns keeps business logic out of navigation code and
/// navigation code out of business logic.
///
/// ## Usage
///
/// ```dart
/// // Provide at the top of the widget tree:
/// BlocProvider(create: (_) => AuthCubit())
///
/// // Trigger login from a button:
/// context.read<AuthCubit>().login();
///
/// // Trigger logout from settings:
/// context.read<AuthCubit>().logout();
/// ```
///
/// The router observes these state changes and automatically redirects —
/// callers never need to call `context.go(...)` themselves.
class AuthCubit extends Cubit<AuthState> {
  /// Creates the [AuthCubit] starting in the [AuthUnauthenticated] state.
  ///
  /// In a real application the constructor would accept an `AuthRepository`
  /// dependency and call `checkSession()` to restore a persisted login. For
  /// this mock, we default to unauthenticated so the user always lands on
  /// the login screen first.
  AuthCubit() : super(const AuthUnauthenticated());

  /// Simulates a successful login flow.
  ///
  /// In production this method would call the auth repository, await a token,
  /// and then emit [AuthAuthenticated]. For the mock, we transition
  /// immediately.
  ///
  /// **Do NOT add `context.go(...)` here.** Navigation is the router's job;
  /// this method's only responsibility is to update state.
  void login() {
    emit(const AuthAuthenticated());
  }

  /// Simulates a logout.
  ///
  /// Clears session state and emits [AuthUnauthenticated]. The router's
  /// redirect callback will detect the state change and send the user back
  /// to `/login` automatically.
  ///
  /// **Do NOT add `context.go(...)` here.**
  void logout() {
    emit(const AuthUnauthenticated());
  }
}
