/// Authentication layer — barrel export.
///
/// Import this file to access the full auth subsystem:
/// - `AuthCubit` — state manager for login/logout
/// - `AuthState` and its subtypes — sealed state hierarchy
/// - `GoRouterRefreshStream` — stream-to-listenable bridge for GoRouter
library;

export 'auth_cubit.dart';
export 'auth_state.dart';
export 'go_router_refresh_stream.dart';
