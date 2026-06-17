import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stickify/app/routing/app_shell.dart';
import 'package:stickify/auth/auth.dart';
import 'package:stickify/presentation/features/dashboard/presentation/dashboard_entry.dart';
import 'package:stickify/presentation/features/print/presentation/print_setup_entry.dart';
import 'package:stickify/presentation/features/print/presentation/template_selection_page.dart';
import 'package:stickify/presentation/features/product/presentation/product_details_screen.dart';
import 'package:stickify/presentation/features/product/presentation/product_management_entry.dart';
import 'package:stickify/presentation/features/template_editor/label_editor/label_editor_screen.dart';
import 'package:stickify/presentation/features/template_editor/preview/preview_screen.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/sheet_config_screen.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/sticker_setup_screen.dart';
import 'package:stickify/presentation/features/print_history/presentation/print_history_screen.dart';
import 'package:stickify/presentation/forgot_password/forgot_password_screen.dart';
import 'package:stickify/presentation/login/login_screen.dart';
import 'package:stickify/presentation/registration/register_screen.dart';
import 'package:stickify/presentation/settings/settings_screen.dart';
import 'package:stickify/presentation/template_management/template_management_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PART DIRECTIVE
// The `go_router_builder` code generator reads the annotations below and
// emits helpers into the file referenced by this `part` directive. Run:
//
//   dart run build_runner build
//
// to regenerate `router.g.dart` after any route change.
//
// go_router_builder ^4 mixin rules:
//  • GoRouteData subclasses  → generated as `mixin $ClassName on GoRouteData`
//                              → must declare `with $ClassName`
//  • StatefulShellRouteData  → generated as `extension $ClassNameExtension`
//                              → NO `with` clause needed
//  • StatefulShellBranchData → nothing generated
//                              → NO `with` clause needed
// ─────────────────────────────────────────────────────────────────────────────
part 'router.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AUTH / PUBLIC ROUTES
// These routes are accessible without authentication. They live outside the
// AppShellRouteData so they render full-screen without the navigation rail.
// ─────────────────────────────────────────────────────────────────────────────

/// The login screen route — entry point for unauthenticated users.
@TypedGoRoute<LoginRoute>(path: '/login')
@immutable
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const LoginScreen();
  }
}

/// Registration screen route.
@TypedGoRoute<RegisterRoute>(path: '/register')
@immutable
class RegisterRoute extends GoRouteData with $RegisterRoute {
  const RegisterRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const RegisterScreen();
  }
}

/// Forgot-password screen route.
@TypedGoRoute<ForgotPasswordRoute>(path: '/forgot-password')
@immutable
class ForgotPasswordRoute extends GoRouteData with $ForgotPasswordRoute {
  const ForgotPasswordRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const ForgotPasswordScreen();
  }
}

/// The print history screen route — full-screen overlay outside the shell.
@TypedGoRoute<PrintHistoryRoute>(path: '/print-history')
@immutable
class PrintHistoryRoute extends GoRouteData with $PrintHistoryRoute {
  const PrintHistoryRoute();

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const PrintHistoryScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROTECTED SHELL — StatefulShellRoute
//
// StatefulShellRoute wraps a set of "branches", each representing one tab in
// the navigation rail. Key properties:
//
//  • Each branch maintains its own Navigator stack. Navigating to a sub-route
//    within a branch does NOT affect the other branches' stacks.
//  • maintainState: true (default) keeps the branch alive (its subtree stays
//    mounted) even when you switch to a different tab. This preserves scroll
//    position, form input, and any in-memory state.
//  • The shell's builder receives a StatefulNavigationShell which exposes
//    goBranch(index) to programmatically switch tabs and currentIndex to know
//    which branch is active.
//
// The @TypedStatefulShellRoute annotation on the outer route and
// @TypedStatefulShellBranch on each branch are required by go_router_builder
// to generate type-safe helpers.
// ─────────────────────────────────────────────────────────────────────────────

/// The top-level typed annotation wiring the shell to its 4 branches.
@TypedStatefulShellRoute<AppShellRouteData>(
  branches: [
    // Branch 0 — Dashboard
    TypedStatefulShellBranch<DashboardBranchData>(
      routes: [
        TypedGoRoute<DashboardRoute>(
          path: '/dashboard',
        ),
      ],
    ),
    // Branch 1 — Product Management (with a nested sub-route for details)
    TypedStatefulShellBranch<ProductsBranchData>(
      routes: [
        TypedGoRoute<ProductManagementRoute>(
          path: '/products',
          routes: [
            // Sub-route demonstrating type-safe path parameters.
            // The `:id` segment is mapped to the `id` field of
            TypedGoRoute<ProductDetailsRoute>(path: ':id'),
            TypedGoRoute<PrintTemplateSelectRoute>(
              path: ':productId/variants/:variantSku/print/templates',
            ),
            TypedGoRoute<PrintSetupRoute>(
              path: ':productId/variants/:variantSku/print/setup/:templateId',
            ),
          ],
        ),
      ],
    ),
    // Branch 2 — Template Management
    TypedStatefulShellBranch<TemplatesBranchData>(
      routes: [
        TypedGoRoute<TemplateManagementRoute>(
          path: '/templates',
          routes: [
            TypedGoRoute<SheetConfigRoute>(path: 'new/sheets'),
            TypedGoRoute<StickerSetupRoute>(path: 'new/stickers'),
            TypedGoRoute<LabelEditorRoute>(path: ':templateId/editor'),
            TypedGoRoute<PreviewRoute>(path: ':templateId/preview'),
          ],
        ),
      ],
    ),
    // Branch 3 — Settings
    TypedStatefulShellBranch<SettingsBranchData>(
      routes: [
        TypedGoRoute<SettingsRoute>(path: '/settings'),
      ],
    ),
  ],
)
/// Route data class for the StatefulShellRoute shell itself.
///
/// Its [builder] method is called by GoRouter with the live
/// StatefulNavigationShell instance. We delegate to AppShell which renders
/// the CustomNavigationRail alongside the active branch widget.
///
/// Note: go_router_builder ^4 emits an extension (not a mixin) for
/// StatefulShellRouteData subclasses, so no `with` clause is needed here.
class AppShellRouteData extends StatefulShellRouteData {
  const AppShellRouteData();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) {
    // Hand the shell off to the reusable AppShell widget.
    // AppShell owns the Scaffold + NavigationRail layout.
    return AppShell(navigationShell: navigationShell);
  }
}

// ─────────────── Branch data classes ────────────────────────────────────────
// These are required by go_router_builder to tie each branch to its routes.
// They hold no state — they exist purely for the type annotations.
// go_router_builder ^4 generates nothing for StatefulShellBranchData
// subclasses, so no `with $ClassName` clause is needed.

/// Branch data for the Dashboard tab.
class DashboardBranchData extends StatefulShellBranchData {
  const DashboardBranchData();
}

/// Branch data for the Product Management tab.
class ProductsBranchData extends StatefulShellBranchData {
  const ProductsBranchData();
}

/// Branch data for the Template Management tab.
class TemplatesBranchData extends StatefulShellBranchData {
  const TemplatesBranchData();
}

/// Branch data for the Settings tab.
class SettingsBranchData extends StatefulShellBranchData {
  const SettingsBranchData();
}

// ─────────────── Individual screen route data classes ───────────────────────

/// Route data for the Dashboard screen (Branch 0, root route).
@immutable
class DashboardRoute extends GoRouteData with $DashboardRoute {
  const DashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const DashboardPage();
  }
}

/// Route data for the Product Management screen (Branch 1, root route).
@immutable
class ProductManagementRoute extends GoRouteData with $ProductManagementRoute {
  const ProductManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final subView = state.uri.queryParameters['subView'];
    return ProductManagementScreen(initialSubView: subView);
  }
}

/// Route data for the Product Details screen — a nested sub-route of
/// [ProductManagementRoute].
///
/// ## Type-Safe Navigation
///
/// Because this class is generated with `go_router_builder`, you navigate
/// to it like this (no string paths!):
///
/// ```dart
/// ProductDetailsRoute(id: '123').go(context);
/// ```
///
/// The code generator maps the [id] field to the `:id` path parameter
/// declared in the `@TypedGoRoute` annotation on the shell.
@immutable
class ProductDetailsRoute extends GoRouteData with $ProductDetailsRoute {
  const ProductDetailsRoute({required this.id});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  /// The product identifier extracted from the URL path segment `:id`.
  ///
  /// Example URL: `/products/abc-123` → `id == 'abc-123'`
  final String id;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return ProductDetailsScreen(id: id);
  }
}

@immutable
class PrintTemplateSelectRoute extends GoRouteData with $PrintTemplateSelectRoute {
  const PrintTemplateSelectRoute({
    required this.productId,
    required this.variantSku,
  });

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String productId;
  final String variantSku;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return TemplateSelectionPage(
      productId: productId,
      variantSku: variantSku,
    );
  }
}

@immutable
class PrintSetupRoute extends GoRouteData with $PrintSetupRoute {
  const PrintSetupRoute({
    required this.productId,
    required this.variantSku,
    required this.templateId,
    this.quantity,
  });

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String productId;
  final String variantSku;
  final String templateId;

  /// Optional initial quantity to pre-fill in the print setup.
  final int? quantity;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PrintSetupPage(
      productId: productId,
      variantSku: variantSku,
      templateId: templateId,
      quantity: quantity,
    );
  }
}

/// Route data for the Template Management screen (Branch 2, root route).
@immutable
class TemplateManagementRoute extends GoRouteData
    with $TemplateManagementRoute {
  const TemplateManagementRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final action = state.uri.queryParameters['action'];
    return TemplateManagementScreen(initialAction: action);
  }
}

/// Route data for the Sheet Configuration screen.
@immutable
class SheetConfigRoute extends GoRouteData with $SheetConfigRoute {
  const SheetConfigRoute({required this.templateId});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String templateId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return SheetConfigScreen(templateId: templateId);
  }
}

/// Route data for the Sticker Setup screen.
@immutable
class StickerSetupRoute extends GoRouteData with $StickerSetupRoute {
  const StickerSetupRoute({required this.templateId});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String templateId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return StickerSetupScreen(templateId: templateId);
  }
}

/// Route data for the Label Editor / Designer screen.
@immutable
class LabelEditorRoute extends GoRouteData with $LabelEditorRoute {
  const LabelEditorRoute({required this.templateId});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String templateId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return LabelEditorScreen(templateId: templateId);
  }
}

/// Route data for the Final Preview & Finalize screen.
@immutable
class PreviewRoute extends GoRouteData with $PreviewRoute {
  const PreviewRoute({required this.templateId});

  static final GlobalKey<NavigatorState> $parentNavigatorKey = rootNavigatorKey;

  final String templateId;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return PreviewScreen(templateId: templateId);
  }
}

/// Route data for the Settings screen (Branch 3, root route).
@immutable
class SettingsRoute extends GoRouteData with $SettingsRoute {
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    return const SettingsScreen();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ROUTER FACTORY
// AppRouter is a pure factory — call AppRouter.createRouter once at the top
// of your widget tree and provide the returned GoRouter via routerConfig.
// ─────────────────────────────────────────────────────────────────────────────

/// The global root navigator key to navigate outside the shell.
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Factory that constructs and configures the application's [GoRouter].
///
/// Inject the [AuthCubit] here so the router can:
/// 1. Wrap its stream in a `GoRouterRefreshStream` to listen for auth changes.
/// 2. Read the current auth state synchronously inside the `redirect` callback.
class AppRouter {
  AppRouter._();

  /// Creates a fully configured [GoRouter] for the application.
  ///
  /// Pass the application-wide [AuthCubit]. It must already be provided
  /// as a BlocProvider ancestor in the widget tree so that screens can call
  /// `context.read<AuthCubit>()` to trigger login/logout.
  static GoRouter createRouter(AuthCubit authCubit) {
    return GoRouter(
      navigatorKey: rootNavigatorKey,
      // ── Initial Location ──────────────────────────────────────────────────
      // GoRouter always runs the `redirect` callback on the initial location,
      // so even if we start at `/dashboard`, an unauthenticated user will be
      // correctly redirected to `/login` on first frame.
      initialLocation: '/login',

      // ── Refresh Listenable ────────────────────────────────────────────────
      // GoRouterRefreshStream wraps the cubit's stream. Every time the cubit
      // emits a new AuthState, it calls notifyListeners(), which causes the
      // router to re-evaluate the `redirect` callback below. This is the
      // mechanism that makes login → auto-navigate-to-dashboard and
      // logout → auto-navigate-to-login work without explicit go() calls.
      refreshListenable: GoRouterRefreshStream(authCubit.stream),

      // ── Routes ───────────────────────────────────────────────────────────
      // $appRoutes is generated by go_router_builder. It collects all
      // top-level @TypedGoRoute and @TypedStatefulShellRoute annotated classes
      // into a single List<RouteBase>.
      routes: $appRoutes,

      // ── Redirect Callback ─────────────────────────────────────────────────
      // Called on every navigation attempt AND whenever refreshListenable
      // fires. Return a path string to redirect, or null to allow navigation.
      redirect: (context, state) {
        // ── Step 1: Determine the current auth status ──────────────────────
        // We read the cubit's state synchronously. This is safe because
        // AuthCubit is provided above MaterialApp.router in the widget tree.
        final authState = authCubit.state;

        // ── Step 2: Classify the route the user is trying to reach ─────────
        // Auth routes are the three public screens. All other routes (the
        // shell and its branches) are considered protected.
        final uri = state.uri.toString();
        final isAuthRoute =
            uri.startsWith('/login') ||
            uri.startsWith('/register') ||
            uri.startsWith('/forgot-password');

        // ── Step 3: Apply guard logic ──────────────────────────────────────
        // Rule A — Unauthenticated user trying to access a protected route:
        //          Redirect to login.
        if (authState is AuthUnauthenticated && !isAuthRoute) {
          return '/login';
        }

        // Rule B — Authenticated user trying to access an auth route:
        //          Redirect to dashboard (avoid showing login when logged in).
        if (authState is AuthAuthenticated && isAuthRoute) {
          return '/dashboard';
        }

        // Rule C — No redirect needed (happy path).
        // Returning null tells GoRouter to proceed with the requested route.
        return null;
      },
    );
  }
}
