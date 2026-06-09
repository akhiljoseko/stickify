// Doc-comment code blocks in this file omit language tags intentionally
// for readability; suppressed at file level to avoid per-block noise.
// ignore_for_file: missing_code_block_language_in_doc_comment
import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';

/// A declarative, cascading layout selector that completely eliminates
/// inline `if (bp.isDesktop)` conditionals from feature view code.
///
/// ## Cascading Fallback Order (highest → lowest)
/// ```
/// 4K  →  desktop  →  tablet  →  mobile (always required)
/// ```
/// If the active viewport tier has no corresponding layout widget, the widget
/// automatically falls back to the next available configuration downward.
///
/// ## Mandatory / Optional children
/// | Parameter | Required? | Notes                          |
/// |-----------|-----------|--------------------------------|
/// | [mobile]  | ✅ YES    | Structural baseline / fallback |
/// | [tablet]  | Optional  | Overrides mobile at 451–800 px |
/// | [desktop] | Optional  | Overrides tablet at 801–1920 px|
/// | [fourK]   | Optional  | Overrides desktop at 1921 px+  |
///
/// ## Usage — split pane on desktop, stacked on mobile:
/// ```dart
/// AdaptiveLayoutSwitcher(
///   mobile: const _MobileStack(),
///   desktop: const _DesktopSplitPane(),
/// )
/// ```
///
/// ## Performance note
/// Each tier widget is a **const** subtree in practice. Because only the
/// active tier is in the widget tree (the others are simply not built),
/// this avoids unnecessary layout work for hidden form factors.
class AdaptiveLayoutSwitcher extends StatelessWidget {
  /// Creates an [AdaptiveLayoutSwitcher].
  ///
  /// [mobile] is the mandatory structural baseline and acts as the final
  /// fallback for all breakpoints that lack a specific layout override.
  const AdaptiveLayoutSwitcher({
    required this.mobile,
    super.key,
    this.tablet,
    this.desktop,
    this.fourK,
  });

  /// Required baseline — used for Mobile (0–450 px) and as the final
  /// cascading fallback for any higher-tier viewport where an override is null.
  final Widget mobile;

  /// Optional layout for Tablet (451–800 px).
  /// Falls back to [mobile] when null.
  final Widget? tablet;

  /// Optional layout for Desktop (801–1920 px).
  /// Falls back to [tablet] → [mobile] when null.
  final Widget? desktop;

  /// Optional layout for 4K / ultra-wide (1921 px+).
  /// Falls back to [desktop] → [tablet] → [mobile] when null.
  final Widget? fourK;

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final breakpointName = bp.breakpoint.name;

    // ── 4K: check own tier, then cascade down ───────────────────────────────
    if (breakpointName == AppBreakpoints.fourK) {
      return fourK ?? desktop ?? tablet ?? mobile;
    }

    // ── Desktop: check own tier, then cascade down ──────────────────────────
    if (breakpointName == AppBreakpoints.desktop) {
      return desktop ?? tablet ?? mobile;
    }

    // ── Tablet: check own tier, then fall back to mobile ────────────────────
    if (breakpointName == AppBreakpoints.tablet) {
      return tablet ?? mobile;
    }

    // ── Mobile: always return the baseline ──────────────────────────────────
    return mobile;
  }
}
