# Label Grid Presentation Architecture Guide

> **Stack:** Flutter Desktop · `flutter_bloc ^9` (Cubit) · `equatable` · `go_router ^17`

---

## Table of Contents

1. [Overview](#1-overview)
2. [The Page / View Pattern](#2-the-page--view-pattern)
3. [File Naming & Directory Conventions](#3-file-naming--directory-conventions)
4. [Widget Scoping Rules](#4-widget-scoping-rules)
5. [Complete Feature Boilerplate](#5-complete-feature-boilerplate)
6. [Cubit State Lifecycle](#6-cubit-state-lifecycle)
7. [How to Add a New Feature](#7-how-to-add-a-new-feature)
8. [Anti-Patterns to Avoid](#8-anti-patterns-to-avoid)

---

## 1. Overview

The Presentation layer in Label Grid is **modular by feature**. Each feature is fully self-contained under `lib/presentation/features/[feature_name]/` and owns its own:

- **Pages** — dependency injection shells
- **Cubits** — reactive state management
- **Widgets** — atomic, isolated UI components

The Domain and Data layers are **global** (not per-feature) and are consumed by Cubits via injected repository interfaces.

```
lib/
├── core/                         # Design tokens, theme, responsive utilities
├── data/                         # Global: concrete repository implementations
├── domain/                       # Global: entities + repository interfaces
└── presentation/
    ├── widgets/                  # App-wide reusable widgets (2+ feature consumers)
    └── features/
        └── [feature_name]/
            ├── cubits/           # Cubit/Bloc + State classes (sometimes named `cubit/` or `bloc/`)
            ├── presentation/     # Presentation layouts (pages, views, sometimes named `views/`)
            └── widgets/          # Feature-private atomic widgets
```

---

## 2. The Page / View Pattern

Every screen **must** contain exactly two classes inside a single file.

### The Page Class (Public)

**Responsibility:** Dependency injection only. This class:
- Creates and provides the `Cubit` via `BlocProvider`
- Passes route arguments down to the View
- Returns the `View` class as its child — nothing more

```dart
/// The PUBLIC entry point for the router.
/// Handles BlocProvider and argument extraction. Contains NO layout code.
class ProductDashboardPage extends StatelessWidget {
  const ProductDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductDashboardCubit(
        // Repository injected from global service locator (e.g., get_it)
        productRepository: context.read<ProductRepository>(),
      )..loadProducts(),  // trigger initial data fetch / mock load
      child: const _ProductDashboardView(),
    );
  }
}
```

### The View Class (Private / Internal)

**Responsibility:** Layout and UI only. This class:
- Reads Cubit state via `BlocBuilder` or `BlocConsumer`
- Delegates atomic sections to feature-private widget files
- Contains **zero** dependency injection or business logic

```dart
/// PRIVATE to this file. Consumes Cubit state. Contains NO DI code.
class _ProductDashboardView extends StatelessWidget {
  const _ProductDashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductDashboardCubit, ProductDashboardState>(
      builder: (context, state) {
        return switch (state) {
          ProductDashboardInitial()  => const _LoadingPane(),
          ProductDashboardLoading()  => const _LoadingPane(),
          ProductDashboardLoaded()   => _LoadedLayout(products: state.products),
          ProductDashboardError()    => _ErrorPane(message: state.message),
        };
      },
    );
  }
}
```

### Why This Separation Matters

| Concern                        | Owner         |
|--------------------------------|---------------|
| Cubit instantiation            | Page class    |
| Repository injection           | Page class    |
| Route argument extraction      | Page class    |
| Layout and widget tree         | View class    |
| State-driven UI switching      | View class    |
| Atomic UI sub-sections         | Widget files  |

This separation means the View can be tested in isolation by wrapping it in a `MockCubit`, completely decoupled from routing or DI infrastructure.

---

## 3. File Naming & Directory Conventions

### Screen Files

All screen files live under `presentation/` (or `views/`) and use `_entry.dart` or `_page.dart` / `_screen.dart` suffixes:

```
lib/presentation/features/product/
├── bloc/
│   ├── product_cubit.dart
│   └── product_state.dart
├── presentation/
│   └── product_management_entry.dart   ← Entry/Page class + View class (both here)
└── widgets/
    ├── product_card.dart
    ├── product_filter_bar.dart
    └── product_empty_state.dart
```

### Naming Rules

| Artifact             | Convention                              | Example                            |
|----------------------|-----------------------------------------|------------------------------------|
| Screen file          | `[feature]_entry.dart` or `_page.dart`  | `product_management_entry.dart`    |
| Page class           | `[FeatureName]Page` or `[Name]Screen`   | `ProductManagementScreen`          |
| View class           | `_[FeatureName]View` (private)          | `_ProductManagementView`           |
| Cubit class          | `[FeatureName]Cubit`                    | `ProductCubit`                     |
| State class          | `[FeatureName]State` (sealed)           | `ProductState`                     |
| Feature widget       | `[descriptive_name].dart`               | `product_card.dart`                |
| Shared widget        | `[descriptive_name].dart` in `/widgets` | `app_status_badge.dart`            |

### Route Registration

The `Page` class is the only thing the router ever references. The `_View` is internal.

```dart
// In router.dart (go_router_builder annotation)
class ProductDashboardRoute extends GoRouteData {
  const ProductDashboardRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const ProductDashboardPage(); // ← always the Page, never the View
}
```

---

## 4. Widget Scoping Rules

Before creating any new widget, run through this mental checklist:

```
┌─────────────────────────────────────────────────────────────────┐
│             Widget Scoping Decision Tree                        │
│                                                                 │
│  Does a widget already exist that covers this UI need?         │
│       YES ──→ Extend or reuse it. Do NOT create a duplicate.   │
│       NO  ──→ Continue ↓                                       │
│                                                                 │
│  Will this widget be used by 2 or more features?               │
│       YES ──→ lib/presentation/widgets/          (SHARED)      │
│       NO  ──→ lib/presentation/features/[f]/widgets/ (PRIVATE) │
└─────────────────────────────────────────────────────────────────┘
```

### Shared Widgets (`lib/presentation/widgets/`)

These are app-wide primitives — treat them like an internal UI kit:

- `AppStatusBadge` — reusable across Dashboard, Products, Templates
- `AppLoadingIndicator` — consistent loading state across all features
- `AppErrorPane` — standardized error display with retry callback
- `AppConfirmDialog` — modal confirmation dialog
- `AppSearchField` — standardized search input with debounce

### Feature-Private Widgets (`lib/presentation/features/[f]/widgets/`)

These are atomic, isolated UI components meaningful only within a single feature:

- `ProductCard` — specific to `product_dashboard`
- `TemplateGridItem` — specific to `template_management`
- `PrintJobStatusRow` — specific to `print_queue`

### Naming Sub-Widget Classes

Break large widget trees into named widget files. **Do not** use anonymous widget helpers (local `Widget _buildSomething()` methods) for anything longer than ~10 lines.

```dart
// ✅ Correct — isolated atomic widget file
// lib/presentation/features/product_dashboard/widgets/product_card.dart
class ProductCard extends StatelessWidget {
  const ProductCard({required this.product, super.key});
  final Product product;
  // ...
}

// ❌ Incorrect — private method in the View bloats the class
class _ProductDashboardView extends StatelessWidget {
  Widget _buildProductCard(Product p) => /* ... */; // avoid this
}
```

---

## 5. Complete Feature Boilerplate

Below is the canonical, full boilerplate for a new feature called **"Print Queue"**. Copy and adapt this structure exactly.

### `cubits/print_queue_state.dart`

```dart
part of 'print_queue_cubit.dart';

/// Sealed state class — use Dart 3 sealed classes for exhaustive switching.
sealed class PrintQueueState extends Equatable {
  const PrintQueueState();

  @override
  List<Object?> get props => [];
}

final class PrintQueueInitial extends PrintQueueState {
  const PrintQueueInitial();
}

final class PrintQueueLoading extends PrintQueueState {
  const PrintQueueLoading();
}

final class PrintQueueLoaded extends PrintQueueState {
  const PrintQueueLoaded({required this.jobs});
  final List<PrintJob> jobs;

  @override
  List<Object?> get props => [jobs];
}

final class PrintQueueError extends PrintQueueState {
  const PrintQueueError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
```

### `cubits/print_queue_cubit.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_queue_repository.dart';

part 'print_queue_state.dart';

class PrintQueueCubit extends Cubit<PrintQueueState> {
  PrintQueueCubit({required PrintQueueRepository printQueueRepository})
      : _repo = printQueueRepository,
        super(const PrintQueueInitial());

  final PrintQueueRepository _repo;

  Future<void> loadJobs() async {
    emit(const PrintQueueLoading());
    try {
      // During mock phase: hardcoded data lives here, not in the UI
      final jobs = _repo.getMockJobs();
      emit(PrintQueueLoaded(jobs: jobs));
    } catch (e) {
      emit(PrintQueueError(message: e.toString()));
    }
  }
}
```

### `pages/print_queue_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/repositories/print_queue_repository.dart';
import 'package:stickify/presentation/features/print_queue/cubits/print_queue_cubit.dart';
import 'package:stickify/presentation/features/print_queue/widgets/print_job_row.dart';
import 'package:stickify/presentation/widgets/app_error_pane.dart';
import 'package:stickify/presentation/widgets/app_loading_indicator.dart';

// ─── PUBLIC: Route entry point ──────────────────────────────────────────────

class PrintQueuePage extends StatelessWidget {
  const PrintQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PrintQueueCubit(
        printQueueRepository: context.read<PrintQueueRepository>(),
      )..loadJobs(),
      child: const _PrintQueueView(),
    );
  }
}

// ─── PRIVATE: Layout and state consumption ──────────────────────────────────

class _PrintQueueView extends StatelessWidget {
  const _PrintQueueView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<PrintQueueCubit, PrintQueueState>(
        builder: (context, state) => switch (state) {
          PrintQueueInitial() => const AppLoadingIndicator(),
          PrintQueueLoading() => const AppLoadingIndicator(),
          PrintQueueLoaded(:final jobs) => _JobList(jobs: jobs),
          PrintQueueError(:final message) => AppErrorPane(
              message: message,
              onRetry: () => context.read<PrintQueueCubit>().loadJobs(),
            ),
        },
      ),
    );
  }
}

// ─── SUB-WIDGET: Only used within this View ─────────────────────────────────
// NOTE: If this grows beyond ~30 lines, move it to widgets/job_list.dart

class _JobList extends StatelessWidget {
  const _JobList({required this.jobs});
  final List<PrintJob> jobs;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: jobs.length,
      itemBuilder: (context, index) => PrintJobRow(job: jobs[index]),
    );
  }
}
```

---

## 6. Cubit State Lifecycle

Every Cubit must expose exactly these four state phases:

```
[Initial] ──(load called)──▶ [Loading] ──(success)──▶ [Loaded]
                                        └──(failure)──▶ [Error]
               [Error] ──(retry called)──▶ [Loading]
```

The UI must handle all four states. Leaving `Initial` or `Error` without a UI fallback is a compile-time warning risk and a UX failure.

---

## 7. How to Add a New Feature

Follow these steps in order to add a new feature, e.g., **"Inventory Alerts"**:

### Step 1 — Define the Domain Entity

```
lib/domain/entities/inventory_alert.dart
```

### Step 2 — Define the Repository Interface

```
lib/domain/repositories/inventory_alert_repository.dart
```

### Step 3 — Implement the Concrete Repository (with mock data)

```
lib/data/repositories/inventory_alert_repository_impl.dart
```

### Step 4 — Scaffold the Feature Directory

```
lib/presentation/features/inventory_alerts/
├── cubits/
│   ├── inventory_alerts_cubit.dart
│   └── inventory_alerts_state.dart
├── pages/
│   └── inventory_alerts_screen.dart
└── widgets/
    └── alert_card.dart
```

### Step 5 — Register the Route

Add a `GoRouteData` subclass in `router.dart` pointing to `InventoryAlertsPage`.

### Step 6 — Register the Repository

Register `InventoryAlertRepositoryImpl` in your service locator (e.g., `get_it`) or at the `BlocProvider` level.

### Step 7 — Run the Build Runner

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Step 8 — Document

Add an entry to `docs/routing_guide.md` (new route) and update this file's feature table if applicable.

---

## 8. Anti-Patterns to Avoid

| Anti-Pattern                                | Correct Approach                                      |
|---------------------------------------------|-------------------------------------------------------|
| Business logic in the View class            | Move all logic to the Cubit                           |
| `context.read<Cubit>()` in `build()`        | Use `BlocBuilder` or `BlocConsumer` instead           |
| Anonymous `_buildX()` helper methods        | Extract to a named widget file in `widgets/`          |
| Hardcoded data in the UI                    | Put mock data in the Cubit or Repository Impl         |
| Router pointing to the `_View` class        | Router always points to the `Page` class              |
| Shared widget buried in a feature folder    | Promote to `lib/presentation/widgets/`                |
| `MediaQuery.of(context).size.width < 800`   | Use `ResponsiveBreakpoints.of(context)` exclusively   |

---

> **See also:**
> - [`routing_guide.md`](routing_guide.md) — How routes map to Page classes
> - [`responsive_widget_guidelines.md`](responsive_widget_guidelines.md) — Adaptive layout patterns
> - [`design.md`](design.md) — Color tokens, typography, and spacing system
