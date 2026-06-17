import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/l10n/l10n.dart';

extension PumpApp on WidgetTester {
  /// Pumps a widget wrapped in MaterialApp, AppLocalizations, and ResponsiveBreakpoints.
  ///
  /// Optionally sets a custom viewport size [size] for responsive widget testing.
  Future<void> pumpApp(
    Widget widget, {
    Size? size,
  }) async {
    if (size != null) {
      // Clear the widget tree first to avoid laying out the old tree with the new size
      await pumpWidget(const SizedBox());
      
      // Set the physical size and pixel ratio for MediaQuery
      view
        ..physicalSize = size
        ..devicePixelRatio = 1.0;
      // Set the surface size for layout constraints
      await binding.setSurfaceSize(size);
      
      addTearDown(() async {
        view
          ..resetPhysicalSize()
          ..resetDevicePixelRatio();
        await binding.setSurfaceSize(null);
      });
    }

    await pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: Builder(
            builder: (context) {
              final environment = AppEnvironmentResolver.resolve(context);
              return RepositoryProvider<AppEnvironment>.value(
                value: environment,
                child: RepositoryProvider<NotificationService>.value(
                  value: NotificationService(),
                  child: child,
                ),
              );
            },
          ),
          breakpoints: AppBreakpoints.breakpoints,
        ),
        home: widget,
      ),
    );

    if (size != null) {
      await pump();
    }
  }
}
