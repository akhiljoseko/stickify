# Label Grid Routing Architecture Guide

> **Stack:** Flutter Desktop · `go_router ^17` · `go_router_builder ^4` · `flutter_bloc ^9` (Cubit)

---

## Table of Contents

1. [High-Level Architecture](#1-high-level-architecture)
2. [Auth Flow: Cubit → Stream → Router Redirect](#2-auth-flow-cubit--stream--router-redirect)
3. [StatefulShellRoute: Tab State Preservation](#3-statefulshellroute-tab-state-preservation)
4. [How to Add a New Top-Level Tab](#4-how-to-add-a-new-top-level-tab)
5. [How to Add a Nested Sub-Route](#5-how-to-add-a-nested-sub-route)
6. [File Map](#6-file-map)

---

## 1. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                          App Widget                          │
│                                                              │
│   BlocProvider<AuthCubit>                                    │
│   └── _AppView (StatefulWidget)                              │
│       └── MaterialApp.router(routerConfig: GoRouter)         │
│                                                              │
│   GoRouter                                                   │
│   ├── refreshListenable: GoRouterRefreshStream(              │
│   │       authCubit.stream)          ← listens for changes  │
│   ├── redirect: (context, state) → ...  ← guard logic       │
│   └── routes: $appRoutes            ← generated list        │
│                                                              │
│   Public Routes (no shell)                                   │
│   ├── /login         → LoginScreen                          │
│   ├── /register      → RegisterScreen                       │
│   └── /forgot-password → ForgotPasswordScreen               │
│                                                              │
│   Protected Shell (StatefulShellRoute)                       │
│   └── AppShell (NavigationRail + content area)               │
│       ├── Branch 0: /dashboard     → DashboardScreen        │
│       ├── Branch 1: /products      → ProductManagementScreen│
│       │              /products/:id → ProductDetailsScreen    │
│       ├── Branch 2: /templates     → TemplateManagement     │
│       └── Branch 3: /settings      → SettingsScreen         │
└──────────────────────────────────────────────────────────────┘
```

### Key Principle: Separation of Concerns

| Concern | Owner |
|---|---|
| Is the user logged in? | `AuthCubit` |
| Where should they go? | `GoRouter` redirect callback |
| How to trigger login/logout? | UI calls cubit methods |
| Route parameter extraction | `go_router_builder` (generated code) |
| Tab state preservation | `StatefulShellRoute` branch navigators |

---

## 2. Auth Flow: Cubit → Stream → Router Redirect

This is the most important piece of the architecture to understand.

### The Problem

GoRouter needs to re-evaluate its `redirect` callback whenever the authentication state changes. But GoRouter only knows about `Listenable` objects — it has no native support for Dart Streams or Bloc/Cubit.

### The Solution: `GoRouterRefreshStream`

```
AuthCubit.login()
    │
    ▼
AuthCubit emits AuthAuthenticated   ← Cubit stream emits
    │
    ▼
GoRouterRefreshStream._subscription.listen(...)
    │  receives the new value
    ▼
GoRouterRefreshStream.notifyListeners()   ← ChangeNotifier fires
    │
    ▼
GoRouter.refreshListenable detects change
    │
    ▼
GoRouter calls redirect(context, state)   ← re-evaluates guards
    │
    ▼
redirect reads authCubit.state → AuthAuthenticated
    │
    ▼
isAuthRoute = true (currently on /login)
    │
    ▼
return '/dashboard'   ← router navigates automatically
```

### The Redirect Logic (annotated)

```dart
redirect: (BuildContext context, GoRouterState state) {
  final authState = authCubit.state;          // synchronous read
  final uri = state.uri.toString();

  final isAuthRoute =
      uri.startsWith('/login') ||
      uri.startsWith('/register') ||
      uri.startsWith('/forgot-password');

  // Guard A: Unauthenticated → block protected routes
  if (authState is AuthUnauthenticated && !isAuthRoute) {
    return '/login';
  }

  // Guard B: Authenticated → block auth screens (no going back)
  if (authState is AuthAuthenticated && isAuthRoute) {
    return '/dashboard';
  }

  return null; // allow navigation
}
```

### Why Buttons Do NOT Call `context.go()`

The Login and Logout buttons call **only** `context.read<AuthCubit>().login()` / `.logout()`. The routing happens automatically as a side-effect of the state change. Benefits:

- **Testability:** The cubit can be tested in isolation with no router dependency.
- **Consistency:** Every path to `/dashboard` goes through the same redirect logic.
- **Deep-link safety:** If a user deep-links to `/dashboard` while unauthenticated, the redirect still fires.

---

## 3. StatefulShellRoute: Tab State Preservation

### How It Works

Each branch in a `StatefulShellRoute` gets its own **isolated Navigator**. When you switch tabs:

- The **outgoing** branch's Navigator is kept alive in memory (not unmounted).
- The **incoming** branch's Navigator is displayed.

This means:
- Scroll position in a list? Preserved.
- Text typed into a search field? Preserved.
- A pushed sub-route within a branch? Preserved.

### Branch Index ↔ Route Mapping

| Index | Branch Class | Root Path | Screen |
|---|---|---|---|
| 0 | `DashboardBranchData` | `/dashboard` | `DashboardScreen` |
| 1 | `ProductsBranchData` | `/products` | `ProductManagementScreen` |
| 2 | `TemplatesBranchData` | `/templates` | `TemplateManagementScreen` |
| 3 | `SettingsBranchData` | `/settings` | `SettingsScreen` |

The `currentIndex` exposed by `StatefulNavigationShell` maps directly to these indices.

### The `goBranch` Call

```dart
// In AppShell._onDestinationSelected:
navigationShell.goBranch(
  index,
  initialLocation: index == navigationShell.currentIndex,
);
```

`initialLocation: true` when re-tapping the active tab resets the branch to its root route — a common "tap logo to go home" UX pattern.

---

## 4. How to Add a New Top-Level Tab

> **Example:** Adding an "Analytics" tab as Branch 4.

### Step 1 — Create the screen

```dart
// lib/screens/analytics_screen.dart
class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});
  // ...
}
```

Add it to `lib/screens/screens.dart` exports.

### Step 2 — Add branch data class in `router.dart`

```dart
class AnalyticsBranchData extends StatefulShellBranchData {
  const AnalyticsBranchData();
}

class AnalyticsRoute extends GoRouteData {
  const AnalyticsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AnalyticsScreen();
}
```

### Step 3 — Add the branch to the `@TypedStatefulShellRoute` annotation

```dart
@TypedStatefulShellRoute<AppShellRouteData>(
  branches: [
    // ... existing branches ...
    TypedStatefulShellBranch<AnalyticsBranchData>(
      routes: [
        TypedGoRoute<AnalyticsRoute>(path: '/analytics'),
      ],
    ),
  ],
)
```

### Step 4 — Add the destination to `CustomNavigationRail`

In `app_shell.dart`, add to `_kDestinations`:

```dart
const NavigationRailDestination(
  icon: Icon(Icons.bar_chart_outlined),
  selectedIcon: Icon(Icons.bar_chart),
  label: Text('Analytics'),
),
```

### Step 5 — Regenerate the router

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 5. How to Add a Nested Sub-Route

> **Example:** Adding a `TemplateEditorRoute` under the Templates branch.

### Step 1 — Create the screen

```dart
// lib/screens/template_editor_screen.dart
class TemplateEditorScreen extends StatelessWidget {
  const TemplateEditorScreen({required this.id, super.key});
  final String id;
  // ...
}
```

### Step 2 — Add the route data class in `router.dart`

```dart
class TemplateEditorRoute extends GoRouteData {
  const TemplateEditorRoute({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TemplateEditorScreen(id: id);
}
```

### Step 3 — Nest the route in the annotation

```dart
TypedStatefulShellBranch<TemplatesBranchData>(
  routes: [
    TypedGoRoute<TemplateManagementRoute>(
      path: '/templates',
      routes: [
        TypedGoRoute<TemplateEditorRoute>(path: ':id'), // ← add this
      ],
    ),
  ],
),
```

### Step 4 — Navigate type-safely

```dart
// In TemplateManagementScreen:
TemplateEditorRoute(id: template.id).go(context);
```

### Step 5 — Regenerate

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 6. File Map

```
lib/
├── auth/
│   ├── auth_state.dart              Sealed state: Initial / Authenticated / Unauthenticated
│   ├── auth_cubit.dart              Cubit: login() / logout()
│   ├── go_router_refresh_stream.dart  Stream → ChangeNotifier bridge
│   └── auth.dart                    Barrel export
│
├── app/
│   ├── routing/
│   │   ├── router.dart              @TypedGoRoute / @TypedStatefulShellRoute annotations
│   │   ├── router.g.dart            ← AUTO-GENERATED (run build_runner)
│   │   ├── app_shell.dart           AppShell + CustomNavigationRail
│   │   └── routing.dart             Barrel export
│   ├── view/
│   │   └── app.dart                 BlocProvider<AuthCubit> + MaterialApp.router
│   ├── app_service_locator.dart     Manual service locator for repository/service injection
│   ├── app.dart                     Re-export
│   └── theme.dart                   AppTheme tokens
│
└── presentation/
    ├── login/
    │   └── login_screen.dart        AuthCubit.login() → router redirects
    ├── registration/
    │   └── registration_screen.dart
    ├── forgot_password/
    │   └── forgot_password_screen.dart
    ├── template_management/
    │   └── template_management_screen.dart
    ├── settings/
    │   └── settings_screen.dart     AuthCubit.logout() → router redirects
    ├── splash/
    │   └── splash_screen.dart       Initial splash loader screen
    ├── widgets/
    │   ├── widgets.dart             Barrel export primitive components
    │   └── app_image.dart           Reusable image renderer primitive
    └── features/
        ├── dashboard/
        │   └── dashboard_screen.dart
        ├── product/
        │   ├── product_management_screen.dart
        │   └── bloc/
        │       └── product_cubit.dart
        ├── print/
        │   ├── template_selection_page.dart
        │   └── print_workflow_page.dart
        └── template_editor/
            └── label_editor/
                └── label_editor_screen.dart

docs/
└── routing_guide.md                 ← you are here
```

---

> **Remember:** After any change to route annotations or route data classes, always run:
> ```bash
> dart run build_runner build --delete-conflicting-outputs
> ```
