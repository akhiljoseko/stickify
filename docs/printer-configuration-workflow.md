# Printer Configuration Workflow

This document explains the end-to-end technician workflow for configuring
printer profiles in Stickify, covering each step, why it is required, and
ideal use cases.

---

## Overview

The printer configuration workflow enables a technician to register a
physical printer, define its hardware capabilities, configure its input
trays, and calibrate it for precise label printing. The configured profile
is then used by the Intelligent Print Optimization Engine at runtime to
automatically resolve compatibility conflicts and apply mechanical
corrections — warehouse operators never need to touch these settings.

---

## Workflow Steps

```
1. Discover & Select Printer
        ↓
2. Configure Basic Info
        ↓
3. Configure Capabilities
        ↓
4. Configure Optimization Preferences
        ↓
5. Configure Trays
        ↓
6. Calibrate (per tray, optional)
        ↓
7. Save Profile
```

---

### Step 1: Discover & Select Printer

**What:** The application scans the operating system for connected printers
and presents a selection sheet. The technician picks the physical printer
to configure.

**Why required:** The system must know which physical printer this profile
corresponds to. The OS-reported printer name, driver, and model are used
to automatically populate the profile's identity fields.

**Ideal case:** The printer is powered on, connected, and the OS driver is
correctly installed. The printer appears as "Online" in the selection
sheet.

**Troubleshooting:** If no printers are discovered, verify:
- The printer is powered on and connected via USB/network
- The printer driver is installed correctly (check Windows "Printers & scanners")
- Network printers are on the same subnet

---

### Step 2: Configure Basic Info

**Fields:**
- **System Printer Name** (read-only): Auto-populated from the OS printer name.
  This is the primary identifier used to route print jobs.
- **Model** (read-only): Auto-populated from the driver metadata.
- **Driver** (read-only): Auto-populated from the registered driver.
- **Display Name** (editable): A human-readable label for this profile.

**Why required:** The display name is what appears in the print workflow
dropdown and on the printer management list. It should be descriptive
enough for operators to identify the correct printer (e.g. "Warehouse
Main — Zebra ZT411").

**Ideal case:** The display name follows a consistent naming convention:
`{Location} — {Manufacturer} {Model}`.

---

### Step 3: Configure Capabilities

**What:** Toggle switches defining the printer's hardware capabilities.

| Setting | Description | Default |
|---------|-------------|---------|
| Custom Paper Size | Whether the driver accepts user-defined paper sizes | Enabled |
| Portrait Custom Paper | Whether custom sizes can be sent in portrait orientation | Enabled |
| Landscape Custom Paper | Whether custom sizes can be sent in landscape orientation | Enabled |
| Manual Feed | Whether the printer supports manual sheet feed | Enabled |
| Borderless Printing | Whether the printer supports full-bleed edge printing | Disabled |
| Tray Selection | Whether the driver supports explicit paper tray selection | Enabled |

**Non-Printable Margins (mm):** The physical margins where the printer
cannot place toner/ink. These are used by the compatibility engine to
detect content overlap conflicts.

| Field | Description |
|-------|-------------|
| Top | Non-printable margin at the top edge |
| Bottom | Non-printable margin at the bottom edge |
| Left | Non-printable margin at the left edge |
| Right | Non-printable margin at the right edge |

**Why required:** The Intelligent Compatibility Engine needs accurate
capability flags and margin values to:
1. Detect whether template content would be clipped by hardware margins
2. Determine if orientation/media mapping is needed
3. Apply minimum necessary corrections at print time

**Ideal case:** All capabilities are set to match the printer's actual
driver capabilities. Non-printable margins should be set to known values
from the printer datasheet or measured from test prints. If unsure, start
with conservative values (e.g. 5mm each side).

---

### Step 4: Configure Optimization Preferences

**What:** Controls how the layout engine may automatically adjust sticker
positions to avoid printer margin conflicts.

| Setting | Description | Default |
|---------|-------------|---------|
| Allow Scaling | Whether the engine may scale down stickers to fit margins | Enabled |
| Allow Translation | Whether the engine may shift sticker positions | Enabled |
| Prefer Shrink Over Shift | When clipping occurs, prefer scaling over shifting | Enabled |
| Allow Sticker-Specific Adj. | Whether individual stickers can be adjusted independently | Enabled |
| Minimum Acceptable Scale | The smallest scale factor allowed (as percentage) | 70% |

**Why required:** The optimization hierarchy (see design doc) attempts
corrections in this order:
1. No modification (ideal)
2. Global translation
3. Edge group translation
4. Edge group scaling
5. Individual sticker optimization
6. Unsupported (escalation)

These preferences define which levels are permitted and where the
acceptable limit is.

**Ideal case:**
- Enable all options for maximum flexibility
- Set minimum acceptable scale to 70% (allows moderate reduction without
  making labels unreadable)
- If label content is extremely dense, consider raising the minimum to 85%

---

### Step 5: Configure Trays

**What:** Each printer profile can have one or more tray configurations
representing physical paper input sources.

**Fields per tray:**
- **Tray Name**: Human-readable label (e.g. "Main Feed Tray")
- **Tray Identifier**: Technical identifier matching the OS/driver tray
  designation (e.g. "tray_1", "manual_feed")
- **Non-Printable Margins**: Per-tray margin overrides (some trays may
  have different mechanical tolerances)

**Why required:** Each tray may have different:
- Media types loaded (labels vs. plain paper vs. cardstock)
- Mechanical offsets and tolerances
- Calibration rules
- Supported sheet template mappings

The print pipeline matches templates to trays via supported paper
configurations, so at least one tray is required per profile.

**Ideal case:** Configure one tray per physical input source that will be
used for label printing. Give each tray a descriptive name matching its
physical label (e.g. "Tray 1 (4×6 Labels)", "Bypass (A4 Sheets)").

---

### Step 6: Calibrate (per tray, optional)

**What:** The calibration wizard guides the technician through:
1. Printing a standardized calibration sheet with measurement markers
2. Measuring actual marker positions on the printed sheet
3. Entering measurements into the wizard
4. Saving the calibration rules to the tray profile

**Why required:** Calibration corrects consistent mechanical errors such
as:
- The printer always prints 1mm to the right
- The printer slightly compresses or expands the X or Y axis
- Sheet feed misalignment causing rotation

These corrections are applied before the optimization engine runs, so the
optimization engine works with already-corrected positions.

**Ideal case:** Always calibrate after configuring a new tray. Run
calibration again whenever:
- The printer is moved or serviced
- A different media type is loaded
- Print quality issues are observed
- The driver is updated

**Deferred:** Calibration can be skipped during initial setup. The
profile will use identity transforms (no correction) until calibration
is performed. The tray will show as "UNCALIBRATED" in the list.

---

### Step 7: Save Profile

**What:** Persists the complete printer profile (identity, capabilities,
optimization preferences, tray configurations, and calibration data) to
the local Hive database and syncs to Firestore when online.

**Why required:** Without saving, all configuration work is lost. The
profile must exist in the database for the print workflow and
compatibility engine to use it.

**Behavior on save:**
- New profiles are created with a UUID and timestamp
- Existing profiles are updated with the current timestamp
- On success, the user is returned to the printer management list
- The list automatically refreshes to show the new/updated profile

---

## Architecture Notes

### Component Diagram

```
PrinterManagementPage (list)
        ↓          ↑
  PrinterSelectionSheet
        ↓          ↑
  PrinterConfigurationPage (form)
        ↓          ↑
  PrinterConfigurationCubit
        ↓          ↑
  PrinterProfileRepository
        ↓
  SyncingPrinterProfileRepository
        ↓              ↓
  DatabasePrinterRepo  FirestorePrinterRepo (when online)
```

### Key Domain Entities

| Entity | Purpose |
|--------|---------|
| `PrinterProfile` | Root aggregate: identity + capabilities + prefs + trays |
| `PrinterIdentity` | OS metadata: name, manufacturer, model, driver |
| `PrinterCapabilities` | Hardware flags + non-printable margins |
| `OptimizationPreferences` | Engine behavior constraints |
| `PrinterTrayProfile` | Per-tray configuration + calibration |
| `PrinterCalibration` | Calibration rules + enabled flag |
| `CalibrationRule` | Sheet/row/column/sticker transform target |
| `PrintCoordinateContext` | Resolved transforms at print time |

### Runtime Pipeline Integration

When an operator prints, the pipeline flows through:

```
Template → Printable Regions → Media Mapping
    → Printer Calibration → Compatibility Engine
    → Transform Generator → PDF Rendering → Printer
```

The printer profile configured here feeds into the Calibration step and
the Compatibility Engine step automatically — no operator intervention
required.

---

## Full System Flow: From Template Creation to Print

This section describes how all the pieces fit together in a complete
end-to-end workflow, from designing a label template to printing the
finished labels.

```
  ┌─────────────────────────────────────────────────────────┐
  │                    TECHNICIAN SETUP                      │
  ├─────────────────────────────────────────────────────────┤
  │                                                         │
  │  1. Create Template                                      │
  │     │                                                    │
  │     ├── Configure Sheet (paper size, margins, grid)      │
  │     ├── Configure Stickers (dimensions, printable area)  │
  │     ├── Design Labels (text, barcode, image elements)    │
  │     └── Save & Finalize                                  │
  │                                                         │
  │  2. Configure Printer Profile                            │
  │     │                                                    │
  │     ├── Select discovered printer                        │
  │     ├── Set display name                                 │
  │     ├── Configure capabilities & margins                  │
  │     ├── Configure optimization preferences                │
  │     ├── Add tray(s) with media type & margins            │
  │     ├── (Optional) Calibrate per tray                    │
  │     │     ├── Print calibration sheet                    │
  │     │     ├── Measure physical offsets                    │
  │     │     └── Save calibration rules                     │
  │     └── Save profile                                     │
  │                                                         │
  │  3. (Optional) Test Print                                │
  │     │                                                    │
  │     └── Print a test label to verify alignment           │
  │                                                         │
  └─────────────────────────────────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │                     OPERATOR WORKFLOW                    │
  ├─────────────────────────────────────────────────────────┤
  │                                                         │
  │  1. Navigate to Print Workflow                          │
  │     │                                                    │
  │  2. Search & Select Product                              │
  │     │                                                    │
  │  3. Select Template                                      │
  │     │   (auto-selects default if configured)             │
  │     │                                                    │
  │  4. Select Printer                                       │
  │     │   (auto-matches available printers to profiles)    │
  │     │                                                    │
  │  5. Enter Quantity & Configure Sheet                     │
  │     │   (toggle individual slots, rows, or print from    │
  │     │    bottom for partially used sheets)               │
  │     │                                                    │
  │  6. Click Print                                          │
  │                                                         │
  └─────────────────────────────────────────────────────────┘
                               │
                               ▼
  ┌─────────────────────────────────────────────────────────┐
  │                  PRINT PIPELINE (AUTOMATIC)              │
  ├─────────────────────────────────────────────────────────┤
  │                                                         │
  │  ┌─────────────┐                                        │
  │  │  1. Load    │  Sheet geometry from template            │
  │  │  Template   │  Sticker printable polygon               │
  │  └─────┬───────┘                                         │
  │        │                                                  │
  │        ▼                                                  │
  │  ┌─────────────┐                                        │
  │  │  2. Media   │  If driver doesn't support orientation, │
  │  │   Mapping   │  transpose coordinates (e.g. portrait → │
  │  └─────┬───────┘  landscape)                              │
  │        │                                                  │
  │        ▼                                                  │
  │  ┌─────────────┐                                        │
  │  │  3. Printer │  Apply technician-measured mechanical    │
  │  │ Calibration │  corrections (offset X/Y, scale X/Y)     │
  │  └─────┬───────┘                                          │
  │        │  CalibrationRuleMatcher → matches rules by        │
  │        │  sheet, row, column, edge, or sticker index       │
  │        │  CalibrationTransformComposer → composes          │
  │        │  cumulative transforms                            │
  │        ▼                                                  │
  │  ┌─────────────────────┐                                 │
  │  │  4. Compatibility   │  Project sticker printable        │
  │  │    Analysis         │  regions with calibration applied │
  │  └─────┬───────────────┘  Detect conflicts with margins    │
  │        │                                                    │
  │        ▼                                                    │
  │  ┌─────────────────────┐                                   │
  │  │  5. Transform       │  Generate minimum corrections:    │
  │  │    Generation       │                                    │
  │  │                     │  Level 1: No modification          │
  │  │                     │  Level 2: Global translation       │
  │  │                     │  Level 3: Edge group translation   │
  │  │                     │  Level 4: Edge group scaling       │
  │  │                     │  Level 5: Individual stickers      │
  │  │                     │  Level 6: Unsupported (fail)       │
  │  └─────┬───────────────┘                                    │
  │        │                                                    │
  │        ▼                                                    │
  │  ┌─────────────┐                                          │
  │  │  6. Compose │  Combine calibration + optimization        │
  │  │  Transforms │  transforms via CalibrationTransformComposer│
  │  └─────┬───────┘                                           │
  │        │                                                    │
  │        ▼                                                    │
  │  ┌─────────────┐                                          │
  │  │  7. PDF     │  Render each sticker with its composed     │
  │  │  Rendering  │  transform (scale around anchor point,     │
  │  └─────┬───────┘  translation)                              │
  │        │  LabelPdfLayoutEngine:                              │
  │        │  - Build page with sheet dimensions                │
  │        │  - For each active sticker slot:                   │
  │        │    - Apply coordinate transform                    │
  │        │    - Render all blueprint elements                 │
  │        │    - Clip to printable polygon                     │
  │        │  - Return raw PDF bytes                            │
  │        ▼                                                    │
  │  ┌─────────────┐                                          │
  │  │  8. Print   │  Send PDF to Windows print spooler         │
  │  │  Service    │  - Apply DEVMODE settings                  │
  │  │             │  - Request custom paper size               │
  │  │             │  - Validate printer supports format         │
  │  │             │  - Spool to physical printer                │
  │  └─────────────┘                                           │
  │                                                             │
  │  9. Record Print Job in History                              │
  │                                                             │
  └─────────────────────────────────────────────────────────┘
```

### Key Services & Their Roles

| Service | Role | Inputs | Output |
|---------|------|--------|--------|
| `CalibrationRuleMatcher` | Finds applicable calibration rules for each sticker slot | Tray calibration rules, slot position | Matched rules per slot |
| `CalibrationTransformComposer` | Composes multiple rules into cumulative transforms | List of `CalibrationRule` | `PrintStickerTransform` per slot/row/column |
| `PrinterCalibrationCoordinateResolver` | Orchestrates matching + composition; validates paper support | `CalibrationRequest` | `Result<PrintCoordinateContext>` |
| `TemplatePrinterCompatibilityAnalyzer` | Detects margin conflicts after calibration | Template, profile, tray, calibration context | `CompatibilityAnalysisResult` with conflicts |
| `IntelligentTransformGenerator` | Generates minimum correction strategy | Analysis result, preferences | `OptimizationStrategy` with transforms |
| `PrintPipelineOrchestrator` | Sequenced pipeline: calibrate → analyze → optimize → compose | Template, profile, tray, paper config ID | `Result<PrintCoordinateContext>` |
| `PrintPreFlightValidator` | Validates template geometry before printing | Template | Validation result |
| `LabelPdfLayoutEngine` | Renders PDF with per-sticker transforms | Template, transforms, data | Raw PDF bytes |
| `WindowsPrintService` | Sends PDF to physical printer via Win32 API (DEVMODE) | PDF, printer target, paper format | Print result |

### Data Flow Summary

```
Template (physical truth)
    ↓                  ↕
Printer Profile (mechanical behavior)
    ↓                  ↕
Printer Tray (feed path + calibration)
    ↓
PrintPipelineOrchestrator.resolve()
    ├── CalibrationResolver → PrintCoordinateContext (calibration)
    ├── CompatibilityAnalyzer → CompatibilityAnalysisResult (conflicts)
    ├── TransformGenerator → OptimizationStrategy (corrections)
    └── TransformComposer → PrintCoordinateContext (composed)
    ↓
LabelPdfLayoutEngine.buildPdfBytes() → PDF bytes
    ↓
WindowsPrintService.printLabels() → Printer hardware
    ↓
PrintJob saved to history
```

### Key Architectural Principles

1. **Templates describe physical truth** — They are never modified for
   printer compensation. All corrections happen in the transform layer.

2. **Printer profiles describe mechanical behavior** — They are independent
   from templates and can be reused across any template.

3. **Minimum correction** — The system always tries less invasive
   corrections first (no change → translation → scaling → individual).

4. **Technicians configure, operators only print** — The warehouse operator
   selects template, printer, and quantity. All complexity is handled
   automatically by the pipeline.

---

## Related Documents

- `docs/intelligent-printer-compatibility-and-calibration-engine-design.md`
  — Full architectural design document with detailed design decisions
- `docs/printer-configuration-workflow.md` — This document (technician
  workflow + full system flow)
- `lib/domain/services/print_pipeline_orchestrator.dart` — Pipeline
  orchestration entry point
- `lib/domain/services/template_printer_compatibility_analyzer.dart` —
  Conflict detection service (524 lines)
- `lib/domain/services/intelligent_transform_generator.dart` — Transform
  optimization service with 4-level hierarchy (402 lines)
- `lib/domain/services/calibration_rule_matcher.dart` — Rule matching
  engine
- `lib/domain/services/calibration_transform_composer.dart` — Transform
  composition engine
- `lib/core/services/printing/label_pdf_layout_engine.dart` — PDF
  rendering with per-sticker transforms (467 lines)
- `lib/core/services/printing/windows/windows_print_service.dart` —
  Windows print spooling with DEVMODE management (373 lines)
