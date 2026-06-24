# Stickify Intelligent Printer Compatibility & Calibration System

## Technical Architecture, Design Decisions & Implementation Roadmap

**Document Version:** 1.0
**Status:** In Development
**Audience:** Software Engineers, AI Coding Agents, System Maintainers
**Platform:** Flutter Desktop (Windows Printing)
**Database:** Firestore (Cloud backup), Local cache (future phases)
**Printing Engine:** Existing PDF-based label rendering engine

---

# 1. Problem Statement

## 1.1 Existing System

The current Stickify application generates label PDFs by placing each element at exact coordinates defined by the label designer.

Example:

```
Sheet
--------------------------------
| Label 1 | Label 2 | Label 3 |
|---------|---------|---------|
| Label 4 | Label 5 | Label 6 |
--------------------------------
```

Each sticker contains a designer-defined printable region.

The designer places:

* Text
* Barcodes
* QR codes
* Images
* Dynamic data fields

The generated PDF is therefore an exact representation of the intended physical sheet.

---

# 1.2 The Real World Printing Problem

Physical printers are imperfect.

Examples:

```
Printer A

Left non-printable area:
2 mm

Right non-printable area:
1 mm

Top:
0.5 mm
```

Another printer:

```
Printer B

Left:
0.5 mm

Right:
3 mm
```

A PDF that prints perfectly on Printer A may clip content on Printer B.

---

# 1.3 Why Traditional Margin Calibration Does Not Work

The initial idea was to apply a global shift:

```
Move entire page 2 mm right
```

This fails.

Example:

```
Before:

|Sticker1|Sticker2|Sticker3|

After shift:

    |Sticker1|Sticker2|Sticker3|
```

Now the right-most stickers may become clipped.

---

# 1.4 Why Changing Paper Size Is Not a Solution

A proposed idea was:

```
Physical sheet:
200 mm × 250 mm

Create virtual paper:
204 mm × 250 mm
```

to compensate for a 2 mm printer margin.

This approach is unreliable because printers do not treat PDF coordinates as an unlimited canvas.

The printer driver:

* Applies its own physical printable region.
* Applies paper origin rules.
* May clip content outside the printable area.
* May reject custom paper definitions.
* May enforce orientation limitations.

Therefore:

**The application must adapt the content, not attempt to trick the printer.**

---

# 1.5 Why We Cannot Always Apply Calibration

Another important discovery:

A printer non-printable area does not automatically mean a problem.

Example:

```
Sticker Design

+----------------+
| Company Logo   |
| (pre-printed)  |
|                |
| Barcode        |
+----------------+
```

The top 10 mm contains no generated content.

A printer unable to print in that area is irrelevant.

Applying calibration would unnecessarily reduce usable space.

---

# 1.6 Core Design Principle

The system must answer:

> Does the printer limitation actually conflict with the designed printable region?

If the answer is:

```
NO
```

Print exactly as designed.

If:

```
YES
```

Apply the smallest possible correction.

---

# 1.7 Final Goal

The final system must:

* Prevent clipping.
* Utilize maximum available sticker space.
* Preserve the designer's layout whenever possible.
* Require no technical decisions from warehouse staff.
* Allow technicians to perform complex calibration once.
* Automatically apply corrections during printing.

---

# 2. High Level Solution

The system introduces:

```
Technician Configuration
            |
            |
     Printer Profiles
            |
            |
     Calibration Rules
            |
            |
 Intelligent Conflict Engine
            |
            |
 PrintCoordinateContext
            |
            |
 Existing PDF Generator
            |
            |
          Printer
```

---

# 3. Fundamental Architecture Decision

## 3.1 Transform Individual Sticker Slots

The existing PDF generator controls every sticker slot independently.

Therefore:

```
Sticker 1 → Transform A

Sticker 2 → No transform

Sticker 3 → Transform B
```

is possible.

This is superior to transforming the entire page.

---

## Example

A sheet:

```
A B C
D E F
```

Only left edge conflicts.

Result:

```
A shifted
D shifted

B,C,E,F unchanged
```

Maximum usable area is preserved.

---

# 4. Existing System Modifications

The current printing pipeline:

```
PrintService
     |
     |
PDF Layout Engine
     |
     |
Fixed Coordinates
```

will become:

```
PrintService
     |
     |
Calibration Resolution Engine
     |
     |
PrintCoordinateContext
     |
     |
PDF Layout Engine
     |
     |
Adjusted Coordinates
```

---

# 5. Core Data Models

---

# 5.1 PrintStickerTransform

**Status:** Implemented
**Phase:** 1A.1 (Completed)

Represents a transformation for a single sticker slot.

Properties:

```
offsetX mm
offsetY mm

scaleX
scaleY

anchorX
anchorY
```

Example:

```
Shift right:
offsetX = +1 mm


Shrink from right edge:
scaleX = 0.98
anchorX = 1.0
```

---

# 5.2 PrintCoordinateContext

**Status:** Implemented
**Phase:** 1A (Completed)

Represents all transformations required for a print job.

Contains mappings for:

```
Global transforms

Row transforms

Column transforms

Sticker transforms
```

The current implementation uses override lookup.

Future versions may support composition.

---

# 5.3 PrinterIdentity

**Phase:** 1B.1

Represents a physical printer.

Fields:

Required:

```
systemPrinterName
```

Optional:

```
manufacturer
model
driverName
driverVersion
```

---

# 5.4 PrinterProfile

Represents a technician configured printer.

Contains:

```
id
displayName

PrinterIdentity

PrinterCapabilities

OptimizationPreferences

List<PrinterTrayProfile>

createdAt
updatedAt
lastValidatedAt

status
```

---

# 5.5 PrinterCapabilities

Represents printer limitations.

Examples:

```
supportsCustomPaperSize

supportsPortraitCustomPaper

supportsLandscapeCustomPaper

supportsTraySelection

supportsBorderlessPrinting
```

---

# 5.6 PrinterTrayProfile

A printer can have multiple trays.

Each tray contains:

```
trayIdentifier

displayName

supportedPaperConfigurations

PrinterCalibration
```

---

# 5.7 PaperConfigurationReference

References an application sheet configuration.

It is NOT:

* Windows paper form.
* Driver paper ID.

It represents:

```
This tray has been calibrated
for this sheet definition.
```

---

# 5.8 PrinterCalibration

Contains:

```
enabled

List<CalibrationRule>

lastCalibratedAt
```

---

# 5.9 CalibrationRule

Defines:

```
Where to apply correction

+
What transformation to apply
```

Contains:

```
CalibrationTarget

PrintStickerTransform
```

No priority exists.

Composition decisions belong to the future engine.

---

# 5.10 CalibrationTarget

Current supported targets:

```
Entire sheet

Specific row

Specific column

Specific sticker

Edge groups:
Left
Right
Top
Bottom
```

Future versions may add:

```
Multiple rows

Ranges

Groups
```

---

# 5.11 OptimizationPreferences

Technician decisions.

Examples:

```
Allow scaling

Allow translation

Prefer shrinking over shifting

Allow sticker specific correction
```

---

# 6. Repository Architecture (Future)

The application will support cloud backup.

---

# 6.1 PrinterProfileRepository

Responsibilities:

```
Create profiles

Update profiles

Delete profiles

Query profiles

Sync profiles
```

---

## Storage Strategy

Firestore stores:

```
PrinterProfile
```

including:

```
Calibration

Capabilities

Tray mappings
```

---

# 6.2 Local Printer Mapping Repository

Purpose:

A Firestore profile may exist on a different computer.

Example:

Old PC:

```
Warehouse Printer
```

New PC:

```
Warehouse Printer (Copy)
```

A local mapping stores:

```
Cloud Profile
        |
        |
Local Installed Printer
```

This data should remain local.

---

# 7. Service Layer Architecture

---

# 7.1 Printer Discovery Service

Responsibilities:

```
Enumerate Windows printers

Read driver information

Read trays

Read capabilities
```

---

# 7.2 Printer Profile Service

Responsibilities:

```
Create profiles

Validate profiles

Match cloud profiles
to installed printers
```

---

# 7.3 Calibration Service

Technician workflow:

```
Select printer

Select tray

Select sheet

Print test page

Measure errors

Generate calibration rules
```

---

# 7.4 Compatibility Analyzer

Input:

```
Template

Printer

Tray

Sheet
```

Determines:

```
Conflict exists?
```

---

Example:

```
Top margin unavailable

BUT

Template does not print there

Result:
No correction required
```

---

# 7.5 Calibration Resolution Engine

Most important service.

Input:

```
Template

PrinterProfile

Tray

Sheet
```

Output:

```
PrintCoordinateContext
```

---

Responsibilities:

```
Analyze conflicts

Apply technician preferences

Generate minimal transformations
```

---

# 7.6 Existing PDF Engine

No redesign required.

It receives:

```
PrintCoordinateContext
```

and applies:

```
Offset

Scaling

Anchor-based scaling
```

during sticker rendering.

---

# 8. Implementation Roadmap

---

# Phase 1A — Printing Pipeline Foundation (Completed)

Implemented:

* PrintCoordinateContext
* PrintStickerTransform
* PDF transformation pipeline
* Validation extraction

No behavior changes.

---

# Phase 1A.1 — Transformation Stabilization (Completed)

Implemented:

* Anchor based scaling
* Identity improvements
* Transformation tests
* Mathematical corrections

---

# Phase 1B.1 — Printer Domain Model Foundation (Pending Implementation)

Implement:

* Printer entities
* Calibration entities
* Capabilities
* Paper references
* Validation
* Domain tests

---

# Phase 1B.2 — Persistence Layer

Implement:

Repositories:

```
PrinterProfileRepository
```

Firestore:

```
profiles collection
```

Implement:

* Serialization
* Cloud backup
* Restore workflow

---

# Phase 1B.3 — Local Machine Mapping

Implement:

Local storage:

```
Profile ID
        |
Local printer identifier
```

Allows:

```
Restore profile on new laptop
```

without losing configuration.

---

# Phase 2 — Technician Printer Configuration UI

Implement:

```
Navigation Rail

Printer Configuration
```

Screens:

* Printer list
* Profile creation
* Tray configuration
* Capability editor
* Sheet assignment
* Calibration wizard
* Validation screen

---

# Phase 3 — Calibration Engine

Implement:

* Test printing
* Measurement UI
* Create calibration rules

Generate:

```
PrinterCalibration
```

---

# Phase 4 — Compatibility Analysis Engine

Implement:

```
Template printable regions
+
Printer limitations
```

Decision:

```
No conflict:
No adjustment

Conflict:
Generate optimization request
```

---

# Phase 5 — Intelligent Transformation Engine

Input:

```
Calibration rules

Template geometry

Optimization preferences
```

Output:

```
PrintCoordinateContext
```

---

Example:

```
Left column conflict

Result:

Left column:
Shift +0.5 mm

Center:
No change

Right:
No change
```

---

# Phase 6 — Runtime Integration

Warehouse user flow:

```
Select printer

Select template

Click Print
```

Behind the scenes:

```
Load profile

Detect tray

Resolve calibration

Generate PrintCoordinateContext

Generate PDF

Print
```

No technical decisions are required.

---

# 9. Final Architectural Principles

The system must always follow these rules:

---

## Rule 1

Do not modify sheets to compensate printer margins.

Modify content placement.

---

## Rule 2

Do not globally move all stickers if only some stickers conflict.

Use selective sticker transformations.

---

## Rule 3

Do not apply calibration where no printed content exists.

Use compatibility analysis.

---

## Rule 4

Technicians configure complexity once.

Warehouse staff should only print.

---

## Rule 5

Calibration rules describe intent.

The engine decides how to combine and apply them.

---

# 10. Current Project Status

| Phase      | Status                      |
| ---------- | --------------------------- |
| Phase 1A   | ✅ Completed                 |
| Phase 1A.1 | ✅ Completed                 |
| Phase 1B.1 | ✅ Completed                 |
| Phase 1B.2 | Planned                     |
| Phase 1B.3 | Planned                     |
| Phase 2    | Planned                     |
| Phase 3    | Planned                     |
| Phase 4    | Planned                     |
| Phase 5    | Planned                     |
| Phase 6    | Planned                     |

---

# Conclusion

This architecture transforms Stickify from a static label printing application into a **printer-aware intelligent printing platform**.

The final system will:

* Preserve label designs.
* Use maximum available printable space.
* Handle different printers and trays.
* Survive laptop replacement through Firestore backup.
* Automatically apply corrections.
* Hide all technical complexity from warehouse operators.

This document should be treated as the authoritative design reference for all future development of the printer compatibility subsystem.
