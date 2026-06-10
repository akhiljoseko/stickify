// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $loginRoute,
  $registerRoute,
  $forgotPasswordRoute,
  $appShellRouteData,
];

RouteBase get $loginRoute =>
    GoRouteData.$route(path: '/login', factory: $LoginRoute._fromState);

mixin $LoginRoute on GoRouteData {
  static LoginRoute _fromState(GoRouterState state) => const LoginRoute();

  @override
  String get location => GoRouteData.$location('/login');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $registerRoute =>
    GoRouteData.$route(path: '/register', factory: $RegisterRoute._fromState);

mixin $RegisterRoute on GoRouteData {
  static RegisterRoute _fromState(GoRouterState state) => const RegisterRoute();

  @override
  String get location => GoRouteData.$location('/register');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $forgotPasswordRoute => GoRouteData.$route(
  path: '/forgot-password',
  factory: $ForgotPasswordRoute._fromState,
);

mixin $ForgotPasswordRoute on GoRouteData {
  static ForgotPasswordRoute _fromState(GoRouterState state) =>
      const ForgotPasswordRoute();

  @override
  String get location => GoRouteData.$location('/forgot-password');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appShellRouteData => StatefulShellRouteData.$route(
  factory: $AppShellRouteDataExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/dashboard',
          factory: $DashboardRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'search',
              factory: $SearchRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/products',
          factory: $ProductManagementRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: ':id',
              factory: $ProductDetailsRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':productId/variants/:variantSku/print/templates',
              factory: $PrintTemplateSelectRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':productId/variants/:variantSku/print/setup/:templateId',
              factory: $PrintSetupRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/templates',
          factory: $TemplateManagementRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new/sheets',
              factory: $SheetConfigRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'new/stickers',
              factory: $StickerSetupRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':templateId/editor',
              factory: $LabelEditorRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':templateId/preview',
              factory: $PreviewRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settings',
          factory: $SettingsRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $AppShellRouteDataExtension on AppShellRouteData {
  static AppShellRouteData _fromState(GoRouterState state) =>
      const AppShellRouteData();
}

mixin $DashboardRoute on GoRouteData {
  static DashboardRoute _fromState(GoRouterState state) =>
      const DashboardRoute();

  @override
  String get location => GoRouteData.$location('/dashboard');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SearchRoute on GoRouteData {
  static SearchRoute _fromState(GoRouterState state) =>
      SearchRoute(q: state.uri.queryParameters['q']);

  SearchRoute get _self => this as SearchRoute;

  @override
  String get location => GoRouteData.$location(
    '/dashboard/search',
    queryParams: {if (_self.q != null) 'q': _self.q},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProductManagementRoute on GoRouteData {
  static ProductManagementRoute _fromState(GoRouterState state) =>
      const ProductManagementRoute();

  @override
  String get location => GoRouteData.$location('/products');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProductDetailsRoute on GoRouteData {
  static ProductDetailsRoute _fromState(GoRouterState state) =>
      ProductDetailsRoute(id: state.pathParameters['id']!);

  ProductDetailsRoute get _self => this as ProductDetailsRoute;

  @override
  String get location =>
      GoRouteData.$location('/products/${Uri.encodeComponent(_self.id)}');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PrintTemplateSelectRoute on GoRouteData {
  static PrintTemplateSelectRoute _fromState(GoRouterState state) =>
      PrintTemplateSelectRoute(
        productId: state.pathParameters['productId']!,
        variantSku: state.pathParameters['variantSku']!,
      );

  PrintTemplateSelectRoute get _self => this as PrintTemplateSelectRoute;

  @override
  String get location => GoRouteData.$location(
    '/products/${Uri.encodeComponent(_self.productId)}/variants/${Uri.encodeComponent(_self.variantSku)}/print/templates',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PrintSetupRoute on GoRouteData {
  static PrintSetupRoute _fromState(GoRouterState state) => PrintSetupRoute(
    productId: state.pathParameters['productId']!,
    variantSku: state.pathParameters['variantSku']!,
    templateId: state.pathParameters['templateId']!,
  );

  PrintSetupRoute get _self => this as PrintSetupRoute;

  @override
  String get location => GoRouteData.$location(
    '/products/${Uri.encodeComponent(_self.productId)}/variants/${Uri.encodeComponent(_self.variantSku)}/print/setup/${Uri.encodeComponent(_self.templateId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TemplateManagementRoute on GoRouteData {
  static TemplateManagementRoute _fromState(GoRouterState state) =>
      const TemplateManagementRoute();

  @override
  String get location => GoRouteData.$location('/templates');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SheetConfigRoute on GoRouteData {
  static SheetConfigRoute _fromState(GoRouterState state) =>
      SheetConfigRoute(templateId: state.uri.queryParameters['template-id']!);

  SheetConfigRoute get _self => this as SheetConfigRoute;

  @override
  String get location => GoRouteData.$location(
    '/templates/new/sheets',
    queryParams: {'template-id': _self.templateId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $StickerSetupRoute on GoRouteData {
  static StickerSetupRoute _fromState(GoRouterState state) =>
      StickerSetupRoute(templateId: state.uri.queryParameters['template-id']!);

  StickerSetupRoute get _self => this as StickerSetupRoute;

  @override
  String get location => GoRouteData.$location(
    '/templates/new/stickers',
    queryParams: {'template-id': _self.templateId},
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LabelEditorRoute on GoRouteData {
  static LabelEditorRoute _fromState(GoRouterState state) =>
      LabelEditorRoute(templateId: state.pathParameters['templateId']!);

  LabelEditorRoute get _self => this as LabelEditorRoute;

  @override
  String get location => GoRouteData.$location(
    '/templates/${Uri.encodeComponent(_self.templateId)}/editor',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PreviewRoute on GoRouteData {
  static PreviewRoute _fromState(GoRouterState state) =>
      PreviewRoute(templateId: state.pathParameters['templateId']!);

  PreviewRoute get _self => this as PreviewRoute;

  @override
  String get location => GoRouteData.$location(
    '/templates/${Uri.encodeComponent(_self.templateId)}/preview',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}
