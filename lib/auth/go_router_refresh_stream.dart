import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adapts a [Stream] into a [Listenable] so that `GoRouter` can react to
/// stream emissions without knowing anything about streams.
///
/// ## Why this wrapper is needed
///
/// `GoRouter` exposes a `refreshListenable` parameter that accepts a
/// [Listenable]. Every time the listenable calls `notifyListeners()`, the
/// router re-evaluates its `redirect` callback. This is how the router knows
/// to run the redirect logic again after an auth state change.
///
/// Blocs and Cubits expose their state changes as a [Stream]. There is no
/// built-in bridge between [Stream] and [Listenable], so we build one here.
///
/// ## How it works
///
/// 1. `GoRouter` is constructed with:
///    `refreshListenable: GoRouterRefreshStream(authCubit.stream)`.
/// 2. In the constructor, we subscribe to the provided stream via
///    `stream.listen(...)`.
/// 3. Every time the stream emits a new value (i.e. a new auth state is
///    emitted by the cubit), the listener calls [notifyListeners].
/// 4. `GoRouter` receives this notification and immediately re-runs its
///    `redirect` callback with the current navigation state.
/// 5. The `redirect` callback reads the latest `AuthCubit` state directly
///    (synchronously) and returns the appropriate path string or `null`.
///
/// ## Disposal
///
/// The [StreamSubscription] is cancelled in [dispose] to prevent memory leaks.
/// `GoRouter` calls [dispose] on its `refreshListenable` when the router
/// itself is disposed, so this is handled automatically as long as the router
/// is properly disposed (which `MaterialApp.router` guarantees).
///
/// ## Usage
///
/// ```dart
/// GoRouter(
///   refreshListenable: GoRouterRefreshStream(authCubit.stream),
///   redirect: (context, state) { ... },
/// )
/// ```
class GoRouterRefreshStream extends ChangeNotifier {
  /// The [stream] should be the `stream` property of a `Bloc` or `Cubit`.
  GoRouterRefreshStream(Stream<dynamic> stream) {
    // Begin listening immediately. We do not need the emitted value here
    // because the redirect callback reads state synchronously from the cubit.
    // The emission itself is the signal — "something changed, re-check".
    _subscription = stream.listen(
      (_) => notifyListeners(), // Ping the router on every state change.
    );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    // Cancel the subscription to avoid memory leaks when the router is
    // removed from the widget tree.
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
