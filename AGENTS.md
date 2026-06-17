# Stickify — Agent Guide

Flutter app for creating/printing sticker labels (Very Good CLI scaffold).

## Architecture

- **Clean Architecture**: `domain/` (entities + interfaces) → `data/` (impl) → `presentation/` (widgets)
- **State**: BLoC (`flutter_bloc`). Auth is `AuthCubit`; other features use `Bloc`/`Cubit`.
- **DI**: Manual `AppServiceLocator` (`lib/app/app_service_locator.dart`), no DI package.
- **Routing**: `go_router` + `go_router_builder` codegen. 4-tab `StatefulShellRoute` (Dashboard, Products, Templates, Settings) + auth routes outside shell.
- **Offline-first**: Hive CE (local) → sync queue → Cloud Firestore (remote). Auth state wires remote repos.

## Entrypoints

3 flavors, all call `bootstrap()` then `App(locator: locator)`:

| Flavor     | Command |
|------------|---------|
| development | `flutter run --flavor development --target lib/main_development.dart` |
| staging     | `flutter run --flavor staging --target lib/main_staging.dart` |
| production  | `flutter run --flavor production --target lib/main_production.dart` |

## Essential Commands

```sh
# Test (single command, uses very_good_cli, not flutter test directly)
very_good test --coverage --test-randomize-ordering-seed random

# BLoC lint (separate from regular dart analyze)
dart run bloc_tools:bloc lint .

# Code generation (router.g.dart, hive adapters)
dart run build_runner build

# Localization generation (auto-runs on flutter run, or manually)
flutter gen-l10n --arb-dir="lib/l10n/arb"

# Standard analyze
flutter analyze
```

## Code Generation

- `lib/app/routing/router.g.dart` — run `dart run build_runner build` after route changes
- `lib/hive_registrar.g.dart` — run `dart run build_runner build` after new hive models
- `lib/l10n/gen/` — run `flutter gen-l10n` (or just `flutter run`)
- `lib/firebase_options.dart` — run `flutterfire configure`

Generated files checked in.

## Linting

- `analysis_options.yaml` includes `very_good_analysis` + `bloc_lint/recommended.yaml`
- `lib/l10n/gen/*` and `build/` excluded from analyzer
- `public_member_api_docs: false`, `discarded_futures` and `lines_longer_than_80_chars` errors ignored

## Testing

- Uses `mocktail` (not mockito), `bloc_test`, and `flutter_test`
- Test helpers at `test/helpers/pump_app.dart`
- No integration tests found; unit/widget only

## Platform Notes

- Windows: uses `WindowsPrintService` with direct Win32 printing (DevMode, paper validation)
- Others: uses `PdfPrintService` (generates PDF)
- No Linux support (Firebase throws `UnsupportedError`)

## Dependencies to Know

- `go_router` + `go_router_builder` ^4 — route generation uses mixins for `GoRouteData`, extensions for `StatefulShellRouteData`
- `hive_ce` / `hive_ce_flutter` + `hive_ce_generator` — local persistence
- `barcode_widget`, `pdf`, `printing` — label rendering
- `responsive_framework` — breakpoint-aware layouts
- `image_picker` — photo selection
- `firebase_core`, `firebase_auth`, `cloud_firestore` — backend

## CI

GitHub Actions workflows run `flutter_package`, `semantic_pull_request`, `spell_check`, and `license_check` from `VeryGoodOpenSource/very_good_workflows`. PR titles must follow conventional commits.
