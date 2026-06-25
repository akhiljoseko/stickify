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

## Related Documents

- `docs/intelligent-printer-compatibility-and-calibration-engine-design.md`
  — Full architectural design document
- `lib/domain/services/print_pipeline_orchestrator.dart` — Pipeline
  orchestration entry point
- `lib/domain/services/template_printer_compatibility_analyzer.dart` —
  Conflict detection service
- `lib/domain/services/intelligent_transform_generator.dart` — Transform
  optimization service
