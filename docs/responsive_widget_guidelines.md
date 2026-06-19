# Label Grid Responsive Widget Guidelines

> **Stack:** Flutter Desktop · `responsive_framework ^1` · `flutter_bloc ^9`
>
> **Core Principle:** No inline breakpoint conditionals in feature views.
> All form-factor logic lives in declarative framework primitives.

---

## Table of Contents

1. [Breakpoint System](#1-breakpoint-system)
2. [Core Principle: Declarative over Imperative](#2-core-principle-declarative-over-imperative)
3. [Framework Primitive: `AdaptiveLayoutSwitcher`](#3-framework-primitive-adaptivelayoutswitcher)
4. [Framework Primitive: `AdaptiveValue<T>`](#4-framework-primitive-adaptivevaluet)
5. [Framework Primitive: `AdaptiveScrollWrapper`](#5-framework-primitive-adaptivescrollwrapper)
6. [Optimization Rules](#6-optimization-rules)
7. [App-Level Setup](#7-app-level-setup)
8. [Banned Patterns](#8-banned-patterns)
9. [Quick Reference Cheatsheet](#9-quick-reference-cheatsheet)

---

## 1. Breakpoint System

Label Grid uses four named breakpoints, defined once in [`AppBreakpoints`](../lib/core/utils/app_breakpoints.dart).
**These are the only official breakpoint values.** Do not invent custom ones.

| Constant              | Value           | Min Width | Max Width | Target Platform   |
|-----------------------|-----------------|-----------|-----------|-------------------|
| `AppBreakpoints.mobile`  | `'MOBILE'`   | 0 px      | 450 px    | Phones            |
| `AppBreakpoints.tablet`  | `'TABLET'`   | 451 px    | 800 px    | Tablets / compact |
| `AppBreakpoints.desktop` | `'DESKTOP'`  | 801 px    | 1920 px   | MacOS / Windows   |
| `AppBreakpoints.fourK`   | `'4K'`       | 1921 px   | ∞         | Ultra-wide / 4K   |

> **Priority:** Desktop is the primary design target. All layouts must be designed desktop-first and gracefully degrade for smaller breakpoints.

### Cascading Fallback Order

When a tier-specific layout or value is omitted, the framework **always cascades downward**:

```
4K  →  desktop  →  tablet  →  mobile (always mandatory)
```

This is enforced automatically by all three primitives described below.

---

## 2. Core Principle: Declarative over Imperative

### ❌ Old Imperative Style (BANNED)

```dart
// In a feature View — violates the "zero spaghetti" rule
Widget build(BuildContext context) {
  final bp = ResponsiveBreakpoints.of(context);
  if (bp.isDesktop) {
    return Row(children: [filterPane, contentPane]);
  }
  return Column(children: [filterPane, contentPane]);
}
```

### ✅ New Declarative Style (REQUIRED)

```dart
// In a feature View — clean, readable, zero conditionals
Widget build(BuildContext context) {
  return AdaptiveLayoutSwitcher(
    mobile: Column(children: [filterPane, contentPane]),
    desktop: Row(children: [filterPane, contentPane]),
  );
}
```

The three framework primitives — `AdaptiveLayoutSwitcher`, `AdaptiveValue<T>`, and `AdaptiveScrollWrapper` — completely own all breakpoint logic. Feature views declare **what** to show; the framework decides **which** variant to render.

---

## 3. Framework Primitive: `AdaptiveLayoutSwitcher`

**File:** [`lib/presentation/widgets/adaptive_layout_switcher.dart`](../lib/presentation/widgets/adaptive_layout_switcher.dart)

### API

```dart
AdaptiveLayoutSwitcher({
  required Widget mobile,   // ← mandatory structural baseline
  Widget? tablet,           // ← optional
  Widget? desktop,          // ← optional
  Widget? fourK,            // ← optional
})
```

### Cascading Fallback Behaviour

| Active Viewport | fourK provided? | desktop provided? | tablet provided? | Widget rendered |
|-----------------|-----------------|-------------------|------------------|-----------------|
| 4K              | ✅              | —                 | —                | `fourK`         |
| 4K              | ❌              | ✅                | —                | `desktop`       |
| 4K              | ❌              | ❌                | ✅               | `tablet`        |
| 4K              | ❌              | ❌                | ❌               | `mobile`        |
| Desktop         | —               | ✅                | —                | `desktop`       |
| Desktop         | —               | ❌                | ✅               | `tablet`        |
| Desktop         | —               | ❌                | ❌               | `mobile`        |
| Tablet          | —               | —                 | ✅               | `tablet`        |
| Tablet          | —               | —                 | ❌               | `mobile`        |
| Mobile          | —               | —                 | —                | `mobile`        |

### Example 1 — Multi-Pane Split Layout

```dart
/// In _ProductDashboardView — no breakpoint logic, ever.
AdaptiveLayoutSwitcher(
  mobile: const _MobileStack(),     // Column: filter on top, list below
  desktop: const _DesktopSplitPane(), // Row: 280px sidebar + content
)
```

```dart
/// _DesktopSplitPane (feature-private widget)
class _DesktopSplitPane extends StatelessWidget {
  const _DesktopSplitPane();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 280, child: ProductFilterBar()),
        const VerticalDivider(width: 1),
        const Expanded(child: ProductGrid()),
      ],
    );
  }
}
```

### Example 2 — Navigation Shell

```dart
AdaptiveLayoutSwitcher(
  mobile: BottomNavShell(body: child),
  tablet: SideRailShell(labelType: NavigationRailLabelType.selected, body: child),
  desktop: SideRailShell(labelType: NavigationRailLabelType.all, body: child),
)
```

### Example 3 — Three-Column Dashboard (4K only)

```dart
AdaptiveLayoutSwitcher(
  mobile: const _SingleColumn(),
  tablet: const _TwoColumn(),
  desktop: const _TwoColumn(),   // same as tablet — 4K gets a dedicated layout
  fourK: const _ThreeColumn(),
)
```

### Performance Note

Only the **active tier widget** is present in the widget tree. Non-active tier widgets are never built. This is structurally cheaper than `Visibility(visible: false)` wrappers, which still participate in layout.

---

## 4. Framework Primitive: `AdaptiveValue<T>`

**File:** [`lib/core/utils/adaptive_value.dart`](../lib/core/utils/adaptive_value.dart)

A lightweight utility for mapping the current breakpoint to a typed design token — padding, font size, color, constraint — **without any conditional code block**.

### API

```dart
AdaptiveValue<T>(
  context,
  defaultValue: T,   // ← mandatory mobile baseline
  tablet: T?,        // ← optional
  desktop: T?,       // ← optional
  fourK: T?,         // ← optional
).value               // ← returns the resolved T
```

### Example 1 — Adaptive Padding (the most common use case)

```dart
// OLD (banned):
final padding = bp.isDesktop
    ? const EdgeInsets.all(48)
    : const EdgeInsets.all(16);

// NEW (required):
final padding = AdaptiveValue<EdgeInsets>(
  context,
  defaultValue: const EdgeInsets.all(16),
  tablet:  const EdgeInsets.all(24),
  desktop: const EdgeInsets.all(48),
).value;
```

### Example 2 — Adaptive Font Size (design.md Display LG token)

```dart
final fontSize = AdaptiveValue<double>(
  context,
  defaultValue: 24,   // mobile: Display LG scales to 24px per design.md
  desktop: 32,        // desktop: full 32px Display LG token
).value;

Text(
  'Print Queue',
  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w700),
)
```

### Example 3 — Sidebar Width Constraint

```dart
/// Resolves 0 (hidden on mobile) to the 280px spec on desktop.
final sidebarWidth = AdaptiveValue<double>(
  context,
  defaultValue: 0,     // no sidebar on mobile
  tablet:  240,
  desktop: 280,        // matches design.md sidebar spec
).value;

if (sidebarWidth > 0)
  SizedBox(width: sidebarWidth, child: const FilterSidebar()),
```

### Example 4 — Max Content Width Constraint (4K guard)

```dart
/// Prevents content from stretching beyond 1440px on ultra-wide displays.
/// Uses AppBreakpoints.maxContentWidth (1440.0) as defined in design.md.
Center(
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: AdaptiveValue<double>(
        context,
        defaultValue: double.infinity,
        desktop: AppBreakpoints.maxContentWidth,   // 1440px cap kicks in
        fourK: AppBreakpoints.maxContentWidth,
      ).value,
    ),
    child: child,
  ),
)
```

---

## 5. Framework Primitive: `AdaptiveScrollWrapper`

**File:** [`lib/presentation/widgets/adaptive_scroll_wrapper.dart`](../lib/presentation/widgets/adaptive_scroll_wrapper.dart)

Resolves two critical desktop scrolling pitfalls:

1. **Flutter assertion crash prevention** — `Scrollbar` requires the underlying scrollable to share the *same* `ScrollController`. `AdaptiveScrollWrapper` creates and pairs them internally, making the crash impossible.
2. **Platform-appropriate UX** — Desktop/4K gets a visible, draggable scrollbar. Mobile gets clean touch-scroll with no scrollbar (standard mobile UX).

### API

```dart
AdaptiveScrollWrapper({
  required Widget Function(BuildContext, ScrollController) builder,
  bool? thumbVisibility,   // default: true on desktop
  bool? trackVisibility,   // default: false on desktop
})
```

### Example 1 — List View

```dart
AdaptiveScrollWrapper(
  builder: (context, controller) => ListView.builder(
    controller: controller,          // ← shared controller, crash-safe
    itemCount: jobs.length,
    itemBuilder: (_, i) => PrintJobRow(job: jobs[i]),
  ),
)
```

### Example 2 — Grid View

```dart
AdaptiveScrollWrapper(
  builder: (context, controller) => GridView.builder(
    controller: controller,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      childAspectRatio: 4 / 3,
    ),
    itemCount: products.length,
    itemBuilder: (_, i) => ProductCard(product: products[i]),
  ),
)
```

### Example 3 — Arbitrary Column Children

```dart
AdaptiveScrollWrapper(
  builder: (context, controller) => SingleChildScrollView(
    controller: controller,
    child: Column(
      children: [
        const SettingsSection(),
        const PrinterConfigSection(),
        const AccountSection(),
      ],
    ),
  ),
)
```

### Example 4 — Data Table with Always-Visible Track

```dart
/// For dense industrial data tables, both thumb and track are visible.
AdaptiveScrollWrapper(
  thumbVisibility: true,
  trackVisibility: true,
  builder: (context, controller) => ListView.builder(
    controller: controller,
    itemCount: rows.length,
    itemBuilder: (_, i) => DataRow(row: rows[i]),
  ),
)
```

---

## 6. Optimization Rules

### Rule 1 — Isolated Rebuild Scopes

Layout shifts must **never** trigger a full screen rebuild. Each adaptive component is a self-contained sub-tree. Combined with `const` constructors on the tier widgets, this means only the root `AdaptiveLayoutSwitcher` rebuilds on a window resize event — not the content inside.

```dart
// ✅ Correct — tier children are const; only the switcher itself rebuilds
AdaptiveLayoutSwitcher(
  mobile: const _MobileStack(),   // const — not rebuilt during resize
  desktop: const _DesktopPane(),  // const — not rebuilt during resize
)

// ❌ Incorrect — inline widget construction re-runs on every resize
AdaptiveLayoutSwitcher(
  mobile: Column(children: [FilterBar(), ProductList()]),   // rebuilds everything
  desktop: Row(children: [FilterBar(), ProductList()]),     // rebuilds everything
)
```

### Rule 2 — Input Accentuation Guards (Hover Effects)

`MouseRegion` must **always** guard `onEnter`/`onExit` against mobile/touch viewports.

```dart
class ProductCard extends StatefulWidget { /* ... */ }

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // Resolve once per build, not inside the hover callback
    final isDesktopOrLarger = AdaptiveValue<bool>(
      context,
      defaultValue: false,     // mobile: no hover tracking
      desktop: true,           // desktop: hover tracking active
      fourK: true,
    ).value;

    return MouseRegion(
      // Guard: only wire up hover events on desktop
      onEnter: isDesktopOrLarger ? (_) => setState(() => _isHovered = true) : null,
      onExit:  isDesktopOrLarger ? (_) => setState(() => _isHovered = false) : null,
      cursor:  isDesktopOrLarger ? SystemMouseCursors.click : MouseCursor.defer,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: _isHovered && isDesktopOrLarger
              ? Theme.of(context).colorScheme.surfaceContainerHigh
              : Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(4), // design.md: DEFAULT 0.25rem
        ),
        child: /* card content */,
      ),
    );
  }
}
```

**Rule:** Never use hover state as the **sole** affordance of interactivity — elements must always be visually distinguishable as tappable/clickable independent of hover state.

### Rule 3 — The Dynamic Layout Boundary Rule

All list/grid wrappers must enforce explicit constraints. Never allow unbounded layout to cascade up the tree.

```dart
// ✅ Correct — explicit bounds + max-width cap
Expanded(
  child: Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppBreakpoints.maxContentWidth),
      child: AdaptiveScrollWrapper(
        builder: (context, controller) => GridView.builder(
          controller: controller,
          /* ... */
        ),
      ),
    ),
  ),
)

// ❌ Incorrect — unbounded Column child causes RenderBox layout error
Column(
  children: [
    GridView.builder(/* ... */),  // CRASH: unbounded height in Column
  ],
)
```

**Guideline:** Any `ListView`, `GridView`, or `SingleChildScrollView` placed inside a `Column` or `Row` must be wrapped in `Expanded` or `Flexible` — never naked.

---

## 7. App-Level Setup

`ResponsiveBreakpoints.builder` is configured **once** at the root and propagates to the entire widget tree. No per-screen setup is required.

### [`lib/core/utils/app_breakpoints.dart`](../lib/core/utils/app_breakpoints.dart)

```dart
abstract final class AppBreakpoints {
  static const String mobile  = 'MOBILE';
  static const String tablet  = 'TABLET';
  static const String desktop = 'DESKTOP';
  static const String fourK   = '4K';

  static const List<Breakpoint> breakpoints = [
    Breakpoint(start: 0,    end: 450,              name: mobile),
    Breakpoint(start: 451,  end: 800,              name: tablet),
    Breakpoint(start: 801,  end: 1920,             name: desktop),
    Breakpoint(start: 1921, end: double.maxFinite, name: fourK),
  ];

  static const double maxContentWidth = 1440.0;
}
```

### [`lib/app/view/app.dart`](../lib/app/view/app.dart) — root builder

```dart
MaterialApp.router(
  // ... theme, routing, l10n ...
  builder: (context, child) => ResponsiveBreakpoints.builder(
    child: child!,
    breakpoints: AppBreakpoints.breakpoints,
  ),
)
```

> **Critical:** `ResponsiveBreakpoints.builder` wraps the outermost widget so that all three primitives work throughout the entire tree without any per-screen boilerplate.

---

## 8. Banned Patterns

| ❌ Anti-Pattern                                       | ✅ Correct Replacement                               |
|-------------------------------------------------------|------------------------------------------------------|
| `MediaQuery.of(context).size.width > 800`             | `AdaptiveLayoutSwitcher` or `AdaptiveValue<T>`       |
| `bp.isDesktop ? widgetA : widgetB` in a View class    | `AdaptiveLayoutSwitcher(desktop: widgetA, mobile: widgetB)` |
| `if (bp.largerThan(TABLET)) { ... }` in build()       | `AdaptiveLayoutSwitcher` declarative selection       |
| Padding hardcoded to a single value                   | `AdaptiveValue<EdgeInsets>(...).value`               |
| `Scrollbar(controller: _ctrl)` without pairing        | `AdaptiveScrollWrapper(builder: ...)` always         |
| `ListView.builder()` with no explicit controller      | `AdaptiveScrollWrapper` provides the controller      |
| `onEnter: (_) => setState(...)` without desktop guard | Guard with `AdaptiveValue<bool>(desktop: true).value`|
| Unbounded `GridView` inside a `Column`                | Wrap in `Expanded` + `ConstrainedBox(maxWidth: ...)`  |
| `Visibility(visible: false, child: widget)`           | Use `AdaptiveLayoutSwitcher` — unused tiers aren't built |

---

## 9. Quick Reference Cheatsheet

### Which Primitive Do I Need?

| Scenario                                              | Use                         |
|-------------------------------------------------------|-----------------------------|
| Completely different layout structure per breakpoint  | `AdaptiveLayoutSwitcher`    |
| Same structure, different padding/size/color value    | `AdaptiveValue<T>`          |
| Any scrollable list, grid, or column on desktop       | `AdaptiveScrollWrapper`     |
| Max-width content cap on 4K/ultra-wide               | `AdaptiveValue` + `ConstrainedBox` with `AppBreakpoints.maxContentWidth` |
| Desktop hover effect on a card or row                | `MouseRegion` guarded with `AdaptiveValue<bool>` |

### Import Map

```dart
// All three primitives via barrels — import once, use everywhere
import 'package:stickify/core/core.dart';                       // AdaptiveValue, AppBreakpoints
import 'package:stickify/presentation/widgets/widgets.dart';    // AdaptiveLayoutSwitcher, AdaptiveScrollWrapper
```

---

> **See also:**
> - [`presentation_architecture.md`](presentation_architecture.md) — Page/View pattern and widget scoping
> - [`routing_guide.md`](routing_guide.md) — Route registration and navigation
> - [`design.md`](design.md) — Official color tokens, typography, and spacing values
