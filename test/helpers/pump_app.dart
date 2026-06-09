import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';
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
          child: child!,
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
