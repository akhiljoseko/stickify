// Doc-comment code blocks reference Flutter types that aren't imported in
// doc context; suppressed for clarity of usage examples.
// ignore_for_file: missing_code_block_language_in_doc_comment, comment_references
import 'package:flutter/widgets.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/core/utils/app_breakpoints.dart';

/// A lightweight, declarative utility that maps the current viewport
/// breakpoint to a typed value (padding, font-size, color, etc.) with
/// automatic cascading fallback toward [defaultValue].
///
/// ## Cascading Fallback Order (highest → lowest)
/// ```
/// 4K  →  desktop  →  tablet  →  defaultValue (mobile)
/// ```
/// If a higher-tier value is omitted, the next available lower value is used.
///
/// ## Usage
///
/// **Inline padding swap:**
/// ```dart
/// final padding = AdaptiveValue<EdgeInsets>(
///   context,
///   defaultValue: const EdgeInsets.all(16),
///   tablet:        const EdgeInsets.all(24),
///   desktop:       const EdgeInsets.all(48),
/// ).value;
/// ```
///
/// **Text size swap:**
/// ```dart
/// final fontSize = AdaptiveValue<double>(
///   context,
///   defaultValue: 24,   // mobile: design.md Display LG scales to 24px
///   desktop: 32,        // desktop: full Display LG token
/// ).value;
/// ```
///
/// **No conditional blocks, no [MediaQuery] math — ever.**
@immutable
class AdaptiveValue<T> {
  /// Creates an [AdaptiveValue] anchored to the given [context].
  ///
  /// [defaultValue] is mandatory and acts as the mobile (0–450 px) baseline.
  /// All higher-tier overrides are optional.
  const AdaptiveValue(
    this._context, {
    required this.defaultValue,
    this.tablet,
    this.desktop,
    this.fourK,
  });

  final BuildContext _context;

  /// The fallback value used for the **Mobile** breakpoint (0–450 px).
  /// Also used whenever a higher-tier override is not supplied.
  final T defaultValue;

  /// Override for the **Tablet** breakpoint (451–800 px).
  final T? tablet;

  /// Override for the **Desktop** breakpoint (801–1920 px).
  final T? desktop;

  /// Override for the **4K** breakpoint (1921 px+).
  final T? fourK;

  /// Resolves and returns the correct value for the current breakpoint,
  /// applying cascading fallback toward [defaultValue] when a tier is omitted.
  T get value {
    final bp = ResponsiveBreakpoints.of(_context);

    if (bp.breakpoint.name == AppBreakpoints.fourK) {
      return fourK ?? desktop ?? tablet ?? defaultValue;
    }
    if (bp.breakpoint.name == AppBreakpoints.desktop) {
      return desktop ?? tablet ?? defaultValue;
    }
    if (bp.breakpoint.name == AppBreakpoints.tablet) {
      return tablet ?? defaultValue;
    }

    // Mobile (default)
    return defaultValue;
  }
}
