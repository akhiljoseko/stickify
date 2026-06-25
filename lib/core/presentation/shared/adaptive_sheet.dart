import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';

/// Shows a bottom sheet on mobile/tablet, or a dialog on desktop.
///
/// [builder] receives a [BuildContext] and should return the widget to show.
/// Returns the value popped via `Navigator.pop()`.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool useSafeArea = true,
  bool isScrollControlled = false,
}) {
  final bp = ResponsiveBreakpoints.of(context);
  final isDesktop = bp.breakpoint.name == AppBreakpoints.desktop ||
      bp.breakpoint.name == AppBreakpoints.fourK;

  if (isDesktop) {
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 40),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: builder(context),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: useSafeArea,
    isScrollControlled: isScrollControlled,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: builder,
  );
}
