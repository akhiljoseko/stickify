import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';

/// A desktop-first scroll wrapper that resolves two common Flutter desktop
/// scrolling pitfalls in a single, composable primitive:
///
/// 1. **Assertion crash prevention** — Flutter's [Scrollbar] requires the
///    underlying scrollable to share the same [ScrollController]. When both
///    are created internally here, the pairing is guaranteed safe.
///
/// 2. **Platform-appropriate UX** — Desktop/4K gets a visible, draggable
///    scrollbar. Mobile gets smooth touch-scroll with no visible scrollbar
///    (standard mobile convention).
///
/// ## The Builder Pattern
/// The internal [ScrollController] is exposed to the child via [builder],
/// allowing the consumer ([ListView.builder], [GridView.builder], etc.) to
/// share the exact same controller without storing it externally.
///
/// ## Usage
/// ```dart
/// AdaptiveScrollWrapper(
///   builder: (context, controller) => ListView.builder(
///     controller: controller,
///     itemCount: products.length,
///     itemBuilder: (context, i) => ProductCard(product: products[i]),
///   ),
/// )
/// ```
///
/// ## Column usage (for arbitrary widget children)
/// ```dart
/// AdaptiveScrollWrapper(
///   builder: (context, controller) => SingleChildScrollView(
///     controller: controller,
///     child: Column(children: [ /* ... */ ]),
///   ),
/// )
/// ```
class AdaptiveScrollWrapper extends StatefulWidget {
  /// Creates an [AdaptiveScrollWrapper].
  ///
  /// [builder] receives a managed [ScrollController] that is already paired
  /// with the enclosing [Scrollbar] on Desktop / 4K platforms.
  const AdaptiveScrollWrapper({
    required this.builder,
    super.key,
    this.thumbVisibility,
    this.trackVisibility,
  });

  /// Builder that receives a [BuildContext] and the managed [ScrollController].
  /// Pass this controller directly to your [ListView], [GridView], or
  /// [SingleChildScrollView].
  final Widget Function(BuildContext context, ScrollController controller)
      builder;

  /// Whether the scrollbar thumb is always visible on Desktop.
  /// Defaults to `true` (recommended for dense data tables and lists).
  final bool? thumbVisibility;

  /// Whether the scrollbar track is always visible on Desktop.
  /// Defaults to `false` (thumb-on-hover is less visually noisy).
  final bool? trackVisibility;

  @override
  State<AdaptiveScrollWrapper> createState() => _AdaptiveScrollWrapperState();
}

class _AdaptiveScrollWrapperState extends State<AdaptiveScrollWrapper> {
  // Owned by this State so it is created once and disposed correctly.
  // Sharing this with the child via builder() guarantees the Scrollbar
  // assertion ("ScrollController has no ScrollPosition attached") can never
  // fire — the controller is attached before the Scrollbar builds.
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final isDesktopOrLarger =
        bp.breakpoint.name == AppBreakpoints.desktop ||
        bp.breakpoint.name == AppBreakpoints.fourK;

    final child = widget.builder(context, _scrollController);

    if (isDesktopOrLarger) {
      // Desktop & 4K: visible, draggable scrollbar paired with the controller.
      // thumbVisibility defaults to true for dense industrial data views.
      return Scrollbar(
        controller: _scrollController,
        thumbVisibility: widget.thumbVisibility ?? true,
        trackVisibility: widget.trackVisibility ?? false,
        child: child,
      );
    }

    // Mobile & Tablet: standard touch-scroll. ScrollConfiguration removes the
    // glow overscroll effect on non-web/desktop targets and hides the scrollbar
    // to match native mobile conventions.
    return ScrollConfiguration(
      behavior: _NoScrollbarBehavior(),
      child: child,
    );
  }
}

/// A [ScrollBehavior] that suppresses the scrollbar indicator on mobile/tablet.
/// The underlying [ScrollPhysics] is left to Flutter's platform defaults so
/// that momentum-based touch scrolling is unaffected.
class _NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Return child unwrapped — no scrollbar widget is inserted.
    return child;
  }
}
