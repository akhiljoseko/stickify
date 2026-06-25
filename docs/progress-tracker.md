# Progress Tracker — Intelligent Printer Compatibility & Calibration Engine

This living document tracks the progress of the implementation plan across Phases 3A.2 through 6.

## Overall Status

| Phase | Description | Status |
|-------|-------------|--------|
| **Phase 3A.2** | Calibration Rule Generation Service | ✅ Complete |
| **Phase 3B**   | Calibration Wizard UI Foundation   | ✅ Complete |
| **Phase 4**    | Compatibility Analysis Engine      | ✅ Complete |
| **Phase 5**    | Intelligent Transformation Engine | ✅ Complete |
| **Phase 6**    | Runtime Integration               | 🔄 In Progress |

---

## Detailed Task Checklist

### Phase 3A.2 — Calibration Rule Generation Service
* **Goal**: Given a complete `CalibrationSession`, compute the mechanical offset and scale corrections, producing a `CalibrationGenerationResult` containing `CalibrationRule` objects.
* **Commit**: `feat(domain): add calibration rule generation service`
- [x] Create `lib/domain/services/calibration_rule_generator.dart` with offset and scale computation logic
- [x] Update `lib/domain/domain.dart` to export the new generator service
- [x] Create `test/domain/services/calibration_rule_generator_test.dart` covering:
  - [x] Zero offset/scale (identity)
  - [x] Positive offset correction
  - [x] Scale correction
  - [x] Mixed corrections
  - [x] Insufficient horizontal points (1 point)
  - [x] Sufficient horizontal, insufficient vertical
  - [x] Sufficient vertical, insufficient horizontal

### Phase 3B — Calibration Wizard UI Foundation
* **Goal**: Provide the technician UI for executing a calibration session: select printer/tray, print calibration sheet, enter measurements, generate rules, save to profile.
* **Commits**:
  - `feat(presentation): add calibration session cubit and state`
  - `feat(presentation): add calibration wizard UI screens`
  - `feat(routing): add calibration wizard route`
- [x] Create `lib/core/services/printing/calibration_sheet_pdf_generator.dart` using PDF rendering primitives
- [x] Create `lib/presentation/features/printer_management/cubit/calibration_session_cubit.dart` state machine
- [x] Create `lib/presentation/features/printer_management/cubit/calibration_session_state.dart`
- [x] Create `lib/presentation/features/printer_management/views/calibration_wizard_page.dart` multi-step UI
- [x] Create `lib/presentation/features/printer_management/widgets/measurement_entry_form.dart`
- [x] Update `lib/app/routing/router.dart` (register `/settings/printers/:profileId/calibrate/:trayId`)
- [x] Update `lib/app/app_service_locator.dart` (wire dependencies)
- [x] Create `test/presentation/features/printer_management/cubit/calibration_session_cubit_test.dart`
- [x] Create `test/presentation/features/printer_management/views/calibration_wizard_page_test.dart`

### Phase 4 — Compatibility Analysis Engine
* **Goal**: Determine whether a template's sticker printable regions conflict with the printer's physical limitations.
* **Commits**:
  - `feat(domain): add printable region conflict detection entities`
  - `feat(domain): add compatibility analysis engine service`
  - `test(domain): add compatibility analysis engine tests`
- [x] Create `lib/domain/entities/print_region_conflict.dart`
- [x] Create `lib/domain/entities/compatibility_analysis_result.dart`
- [x] Create `lib/domain/services/template_printer_compatibility_analyzer.dart` (Step 1-5: Orientation mapping, projection, margin checks, level recommendation)
- [x] Update `lib/domain/domain.dart` to export new conflict-related items
- [x] Create `test/domain/entities/print_region_conflict_test.dart`
- [x] Create `test/domain/entities/compatibility_analysis_result_test.dart`
- [x] Create `test/domain/services/template_printer_compatibility_analyzer_test.dart` (covering identity, 90° rotation, unsupported mapping, left-edge conflicts)

### Phase 5 — Intelligent Transformation Engine
* **Goal**: Generate minimum correction transforms following the hierarchy (Level 1 to 4, escalation to Level 6).
* **Commits**:
  - `feat(domain): add optimization strategy resolver`
  - `feat(domain): add intelligent transform generator service`
  - `test(domain): add transform generator tests`
- [x] Modify `lib/domain/entities/optimization_preferences.dart` to add `minimumAcceptableScale` (default `0.7`)
- [x] Update Hive and Firestore serialization for `OptimizationPreferences` (ensure backward compatibility)
- [x] Create `lib/domain/entities/optimization_strategy.dart`
- [x] Create `lib/domain/services/intelligent_transform_generator.dart` with Levels 1-4, minimum scale check escalation to Level 6
- [x] Update `lib/domain/domain.dart` to export optimization engine elements
- [x] Create `test/domain/entities/optimization_strategy_test.dart`
- [x] Create `test/domain/services/intelligent_transform_generator_test.dart` (covering all 13 test cases specified in the plan)

### Phase 6 — Runtime Integration
* **Goal**: Wire everything together for the operator workflow: automatic calibration + optimization in the print flow.
* **Commits**:
  - `feat(domain): add print pipeline orchestrator service`
  - `refactor(presentation): integrate printer profile selection into print workflow`
  - `feat(presentation): integrate compatibility check into print workflow`
  - `test: add runtime integration tests`
- [ ] Create `lib/domain/services/print_pipeline_orchestrator.dart` (composites calibration + optimization transforms)
- [ ] Modify `lib/presentation/features/print/cubits/print_workflow_cubit.dart` (populate `PrintExecutionConfiguration`)
- [ ] Modify `lib/presentation/features/print/cubits/print_workflow_state.dart`
- [ ] Update `lib/app/app_service_locator.dart` (register orchestrator and analyzer, inject into cubit)
- [ ] Create `test/domain/services/print_pipeline_orchestrator_test.dart`
- [ ] Update `test/presentation/features/print/cubits/print_workflow_cubit_test.dart`

---

## Verification Checklist

- [ ] Static Analysis passes (`flutter analyze`)
- [ ] BLoC Linter passes (`dart run bloc_tools:bloc lint .`)
- [ ] Generated files updated (`dart run build_runner build`)
- [ ] Full test suite passes (`very_good test --coverage --test-randomize-ordering-seed random`)
