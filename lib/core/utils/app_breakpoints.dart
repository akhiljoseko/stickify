// Breakpoint doc comments reference framework types not in the doc scope;
// prefer_int_literals is suppressed because Breakpoint.end is typed double.
// ignore_for_file: comment_references, prefer_int_literals
import 'package:responsive_framework/responsive_framework.dart';

/// Canonical breakpoint name constants and configuration for Stickify.
///
/// **Always import and reference these constants** — never hardcode raw
/// breakpoint strings or pixel values in widget code.
///
/// ## Standard Breakpoints
///
/// | Constant  | Min Width | Max Width | Target Platform   |
/// |-----------|-----------|-----------|-------------------|
/// | [mobile]  | 0 px      | 450 px    | Phones            |
/// | [tablet]  | 451 px    | 800 px    | Tablets / compact |
/// | [desktop] | 801 px    | 1920 px   | MacOS / Windows   |
/// | [fourK]   | 1921 px   | ∞         | Ultra-wide / 4K   |
///
/// ## Usage in widgets — use [AdaptiveLayoutSwitcher] or [AdaptiveValue]
/// For the rare case where raw breakpoint access is needed:
/// ```dart
/// final bp = ResponsiveBreakpoints.of(context);
/// if (bp.breakpoint.name == AppBreakpoints.desktop) { ... }
/// ```
abstract final class AppBreakpoints {
  AppBreakpoints._();

  // ── Breakpoint name constants ─────────────────────────────────────────────
  // These match the `name` field on [Breakpoint] and [ResponsiveBreakpoints].

  /// Mobile breakpoint name: 0–450 px.
  static const String mobile = 'MOBILE';

  /// Tablet breakpoint name: 451–800 px.
  static const String tablet = 'TABLET';

  /// Desktop breakpoint name: 801–1920 px.
  static const String desktop = 'DESKTOP';

  /// 4K / ultra-wide breakpoint name: 1921 px+.
  static const String fourK = '4K';

  // ── Ordered breakpoint list ───────────────────────────────────────────────
  // Register this list exactly once in the root [ResponsiveBreakpoints.builder]
  // call inside lib/app/view/app.dart.

  /// The ordered list of [Breakpoint] definitions to pass to
  /// [ResponsiveBreakpoints.builder].
  static const List<Breakpoint> breakpoints = [
    Breakpoint(start: 0, end: 450, name: mobile),
    Breakpoint(start: 451, end: 800, name: tablet),
    Breakpoint(start: 801, end: 1920, name: desktop),
    Breakpoint(start: 1921, end: double.maxFinite, name: fourK),
  ];

  // ── Design canvas constraint ──────────────────────────────────────────────

  /// Maximum canvas width enforced on 4K / ultra-wide viewports.
  /// Matches the 1440px grid defined in docs/design.md.
  static const double maxContentWidth = 1440.0;
}
