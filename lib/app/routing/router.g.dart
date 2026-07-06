// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $splashRoute,
  $loginRoute,
  $registerRoute,
  $forgotPasswordRoute,
  $printHistoryRoute,
  $printTemplateSelectRoute,
  $printSetupRoute,
  $appShellRouteData,
];

RouteBase get $splashRoute => GoRouteData.$route(
  path: '/splash',
  parentNavigatorKey: SplashRoute.$parentNavigatorKey,
  factory: $SplashRoute._fromState,
);

mixin $SplashRoute on GoRouteData {
  static SplashRoute _fromState(GoRouterState state) => const SplashRoute();

  @override
  String get location => GoRouteData.$location('/splash');

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

RouteBase get $printHistoryRoute => GoRouteData.$route(
  path: '/print-history',
  parentNavigatorKey: PrintHistoryRoute.$parentNavigatorKey,
  factory: $PrintHistoryRoute._fromState,
);

mixin $PrintHistoryRoute on GoRouteData {
  static PrintHistoryRoute _fromState(GoRouterState state) =>
      const PrintHistoryRoute();

  @override
  String get location => GoRouteData.$location('/print-history');

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

RouteBase get $printTemplateSelectRoute => GoRouteData.$route(
  path: '/print/:productId/variants/:variantSku/templates',
  parentNavigatorKey: PrintTemplateSelectRoute.$parentNavigatorKey,
  factory: $PrintTemplateSelectRoute._fromState,
);

mixin $PrintTemplateSelectRoute on GoRouteData {
  static PrintTemplateSelectRoute _fromState(GoRouterState state) =>
      PrintTemplateSelectRoute(
        productId: state.pathParameters['productId']!,
        variantSku: state.pathParameters['variantSku']!,
      );

  PrintTemplateSelectRoute get _self => this as PrintTemplateSelectRoute;

  @override
  String get location => GoRouteData.$location(
    '/print/${Uri.encodeComponent(_self.productId)}/variants/${Uri.encodeComponent(_self.variantSku)}/templates',
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

RouteBase get $printSetupRoute => GoRouteData.$route(
  path: '/print/:productId/variants/:variantSku/setup/:templateId',
  parentNavigatorKey: PrintSetupRoute.$parentNavigatorKey,
  factory: $PrintSetupRoute._fromState,
);

mixin $PrintSetupRoute on GoRouteData {
  static PrintSetupRoute _fromState(GoRouterState state) => PrintSetupRoute(
    productId: state.pathParameters['productId']!,
    variantSku: state.pathParameters['variantSku']!,
    templateId: state.pathParameters['templateId']!,
    quantity: _$convertMapValue(
      'quantity',
      state.uri.queryParameters,
      int.tryParse,
    ),
  );

  PrintSetupRoute get _self => this as PrintSetupRoute;

  @override
  String get location => GoRouteData.$location(
    '/print/${Uri.encodeComponent(_self.productId)}/variants/${Uri.encodeComponent(_self.variantSku)}/setup/${Uri.encodeComponent(_self.templateId)}',
    queryParams: {
      if (_self.quantity != null) 'quantity': _self.quantity!.toString(),
    },
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

T? _$convertMapValue<T>(
  String key,
  Map<String, String> map,
  T? Function(String) converter,
) {
  final value = map[key];
  return value == null ? null : converter(value);
}

RouteBase get $appShellRouteData => StatefulShellRouteData.$route(
  factory: $AppShellRouteDataExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/dashboard',
          factory: $DashboardRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/products',
          factory: $ProductManagementRoute._fromState,
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
              parentNavigatorKey: SheetConfigRoute.$parentNavigatorKey,
              factory: $SheetConfigRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'new/stickers',
              parentNavigatorKey: StickerSetupRoute.$parentNavigatorKey,
              factory: $StickerSetupRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':templateId/editor',
              parentNavigatorKey: LabelEditorRoute.$parentNavigatorKey,
              factory: $LabelEditorRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':templateId/preview',
              parentNavigatorKey: PreviewRoute.$parentNavigatorKey,
              factory: $PreviewRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/printers',
          factory: $PrinterManagementRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'new',
              parentNavigatorKey: PrinterConfigurationRoute.$parentNavigatorKey,
              factory: $PrinterConfigurationRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':profileId',
              parentNavigatorKey:
                  PrinterConfigurationEditRoute.$parentNavigatorKey,
              factory: $PrinterConfigurationEditRoute._fromState,
            ),
            GoRouteData.$route(
              path: ':profileId/calibrate/:trayId',
              parentNavigatorKey: CalibrationWizardRoute.$parentNavigatorKey,
              factory: $CalibrationWizardRoute._fromState,
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

mixin $PrinterManagementRoute on GoRouteData {
  static PrinterManagementRoute _fromState(GoRouterState state) =>
      const PrinterManagementRoute();

  @override
  String get location => GoRouteData.$location('/printers');

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

mixin $PrinterConfigurationRoute on GoRouteData {
  static PrinterConfigurationRoute _fromState(GoRouterState state) =>
      PrinterConfigurationRoute(
        systemPrinterName: state.uri.queryParameters['system-printer-name'],
        manufacturer: state.uri.queryParameters['manufacturer'],
        model: state.uri.queryParameters['model'],
        driverName: state.uri.queryParameters['driver-name'],
      );

  PrinterConfigurationRoute get _self => this as PrinterConfigurationRoute;

  @override
  String get location => GoRouteData.$location(
    '/printers/new',
    queryParams: {
      if (_self.systemPrinterName != null)
        'system-printer-name': _self.systemPrinterName,
      if (_self.manufacturer != null) 'manufacturer': _self.manufacturer,
      if (_self.model != null) 'model': _self.model,
      if (_self.driverName != null) 'driver-name': _self.driverName,
    },
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

mixin $PrinterConfigurationEditRoute on GoRouteData {
  static PrinterConfigurationEditRoute _fromState(GoRouterState state) =>
      PrinterConfigurationEditRoute(
        profileId: state.pathParameters['profileId']!,
      );

  PrinterConfigurationEditRoute get _self =>
      this as PrinterConfigurationEditRoute;

  @override
  String get location => GoRouteData.$location(
    '/printers/${Uri.encodeComponent(_self.profileId)}',
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

mixin $CalibrationWizardRoute on GoRouteData {
  static CalibrationWizardRoute _fromState(GoRouterState state) =>
      CalibrationWizardRoute(
        profileId: state.pathParameters['profileId']!,
        trayId: state.pathParameters['trayId']!,
        paperConfigurationId:
            state.uri.queryParameters['paper-configuration-id']!,
      );

  CalibrationWizardRoute get _self => this as CalibrationWizardRoute;

  @override
  String get location => GoRouteData.$location(
    '/printers/${Uri.encodeComponent(_self.profileId)}/calibrate/${Uri.encodeComponent(_self.trayId)}',
    queryParams: {'paper-configuration-id': _self.paperConfigurationId},
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
