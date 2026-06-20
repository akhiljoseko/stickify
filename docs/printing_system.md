# Printing System Module Documentation

This document describes the architectural design, requirements, concrete implementation details, and extensibility guidelines of the physical PDF printing engine in the Label Grid application.

---

## 1. Requirements

The printing module is designed to map visual labels designed in the editor to actual physical sheets (e.g., custom label sheets) and dispatch them to physical printer hardware.

Key operational requirements include:
- **Sheet Configuration Grid**: Calculate slots on print sheets from column/row layouts and margins in physical millimeters.
- **Dynamic Reflowing Grid**: Support toggling individual slots on a sheet to mark them as "skipped/used" (e.g., when reusing partially printed label sheets). Enable automatic downstream reflowing.
- **Millimeter Accuracy**: Scale all layout calculations in points to match precise millimeter dimensions on physical paper.
- **Dynamic Printer Listing**: Query available system printer devices dynamically and pre-select the system default printer.
- **Windows Alignment Parity**: Resolve the systematic 15 mm left-alignment shift when printing custom sheet sizes on Windows printer drivers.
- **Thread Safety & Performance**: Prevent blocking the main UI thread during CPU-intensive PDF page construction.
- **Direct System Dispatch**: Send compiled print jobs directly to selected printer devices without presenting duplicate OS print dialogs on Windows.

---

## 2. Architecture & System Decoupling

Following SOLID design principles, the printing system is modularized to separate layout composition, printer validation, and operating-system-specific hardware settings.

```
                     Application Layer (DI Root: app.dart)
                                    │
                                    ▼
                          PrintWorkflowCubit
                                    │
                                    ▼
                      PrintService (domain interface)
                                    ▲
                 ┌──────────────────┴──────────────────┐
                 │                                     │
        WindowsPrintService                      PdfPrintService
      (Platform.isWindows)                   (All Other Platforms)
        ├── LabelPdfLayoutEngine                └── LabelPdfLayoutEngine
        ├── WindowsDevModeManager
        └── WindowsPaperValidator
```

### Key Interfaces & Components

1. **[PrintService](file:///g:/GitHub/stickify/lib/domain/services/print_service.dart) (Domain Interface)**:
   Specifies the contract for querying available printers and printing label sheets. It has no third-party package dependencies.
2. **[LabelLayoutEngine](file:///g:/GitHub/stickify/lib/domain/services/label_layout_engine.dart) (Domain Interface)**:
   Defines the interface for compiling label designs and generating raw PDF bytes.
3. **[PaperValidationEngine](file:///g:/GitHub/stickify/lib/domain/services/paper_validation_engine.dart) (Domain Interface)**:
   Provides checking mechanism to verify if a given printer supports the requested sheet dimensions.
4. **[LabelPdfLayoutEngine](file:///g:/GitHub/stickify/lib/core/services/printing/label_pdf_layout_engine.dart) (Core Shared Engine)**:
   Implements `LabelLayoutEngine`. Operates as a pure, platform-independent builder class that renders elements, handles image caches, and compiles pages in a background Isolate.
5. **[PdfPrintService](file:///g:/GitHub/stickify/lib/core/services/pdf_print_service.dart) (Core Implementation)**:
   Implements `PrintService` for macOS, Linux, and mobile platforms. Delegates PDF generation to `LabelPdfLayoutEngine` and uses the standard dialog-based print manager pathway via `Printing.layoutPdf`.
6. **[WindowsPrintService](file:///g:/GitHub/stickify/lib/core/services/printing/windows/windows_print_service.dart) (Core Windows-Specific Implementation)**:
   Implements `PrintService` for Windows. Orchestrates pre-print validations, paper form checks, Windows-specific DEVMODE overrides, and direct spooler dispatch.

---

## 3. Background Isolate Compilation

Creating documents with hundreds of elements, rendering high-resolution barcodes, and saving the output bytes is a CPU-intensive operation. Running this synchronously on the main Dart UI thread blocks frames, causing the application to hang.

- **Main Thread Caching**: Image assets, network URLs, and local file images are pre-cached in memory on the main thread (since reading files and assets uses platform channels that are only available on the main thread).
- **Background Isolate**: The pre-cached image bytes, template layout, product, and variant configuration are sent to a background Dart Isolate via `Isolate.run()` (bypassed in unit tests via `FLUTTER_TEST` check).
- **Compilation**: The background isolate constructs the `pw.Document` and serializes it to `Uint8List` using `doc.save()`.
- **Result Return**: The compiled bytes are returned to the main thread and forwarded to the printing pipeline.

---

## 4. Element Rendering Design Patterns

Rather than using a procedural `if-else` block to translate domain element blueprints to PDF widgets, we implement the **Strategy Pattern** combined with a **Registry Pattern**:

```
[Registry] ──▶ Lookup Blueprint type
                    │
                    ▼ (resolves to strategy)
             [PdfElementRenderer Strategy]
                    │
                    ▼
      [PdfTextRenderer] | [PdfShapeRenderer] | [PdfBarcodeRenderer] | ...
```

- **PdfElementRenderer Strategy**: Declares a generic rendering interface `PdfElementRenderer<T extends ElementBlueprint>`.
- **PdfElementRendererRegistry**: Maps blueprint classes (e.g. `TextElementBlueprint`) to their concrete rendering strategies.
- **Instance Isolation**: To prevent layout state contamination across multiple repeated slot placements, template element widget trees are compiled fresh for each individual sticker slot instance. Reusable binary resources like network/local image bytes and fonts are pre-cached on the main thread, while the widget tree itself is constructed on-demand.

---

## 5. Precise Metric Conversion & Layout

To ensure exact sub-millimeter parity with on-screen templates:
- Physical coordinates in the PDF package are defined in points (1/72 inch).
- The templates are defined directly in physical millimeters.
- All dimensions (page width, margins, sticker width, row gaps) are scaled using `PdfPageFormat.mm` (equivalent to `2.834645669291339` points per millimeter).
- The grid model arranges slots dynamically. Active sticker slots are absolutely positioned inside a root `pw.Stack` page container using physical coordinates in millimeters:
  ```dart
  slotX = sheetConfig.marginLeft + columnIndex * (sticker.widthMm + sheetConfig.columnGap);
  slotY = sheetConfig.marginTop + rowIndex * (sticker.heightMm + sheetConfig.rowGap);
  ```
- No global `FittedBox` or scaling is applied during PDF generation; elements are rendered directly at their designated millimeter dimensions.

---

## 6. Pre-Print Validation Layer

Before compiling a PDF, a strict validation layer checks layout and design constraints:
- **Sheet Bounds**: Validates that the total grid size (margins, stickers, gaps) does not exceed the configured physical sheet width and height.
- **Element Containment**: Checks that all QR and Barcode elements fall completely inside the sticker's physical boundary. If a custom printable polygon is defined, the system verifies that the barcode's rotated corners are fully enclosed by the polygon using a ray-casting point-in-polygon algorithm. Non-barcode elements that lie outside generate a warning.
- **Quantity & Configurations**: Ensures required configurations are present and quantities are valid.

---

## 7. Custom Printable Area Polygon Clipping

When the physical sticker is non-rectangular (e.g., circular, oval, polygonal), the printable area is defined as a list of local vertices. The service clips the sticker's compiled stack using low-level PDF graphics paths inside a `pw.CustomPaint` widget:
- Vertices are converted to PDF points using `PdfPageFormat.mm`.
- Since PDF graphics paths start with a bottom-left origin (Y increases upwards), Y coordinates are flipped relative to the top-left sticker-local origin: `pdfY = (sticker.heightMm - localY) * PdfPageFormat.mm`.
- The path is closed and clipped using `canvas.clipPath()`, containing all child widgets within the physical bounds of the sticker shape.

---

## 8. Windows Registry-Level Alignment Correction

On Windows, standard print spoolers read printer driver preferences (`DEVMODE`) from the system registry to determine the paper size for a print job. When a custom size (e.g., 180×300 mm) is requested, Windows defaults to the printer's registered default size (typically A4 = 210 mm) if the target form is not explicitly set in the registry. This mismatch shifts layout origins by half the difference (`(210 - 180) / 2 = 15 mm`), throwing labels out of alignment.

Label Grid resolves this driver-level issue on Windows by performing a localized registry override before printing, invalidating caches, printing directly, and then restoring original system configurations.

### 1. DEVMODE Override Lifecycle ([WindowsDevModeManager](file:///g:/GitHub/stickify/lib/core/services/printing/windows/windows_devmode_manager.dart))
- **Settings Backup**: Reads current print configuration binary preferences from the Windows Registry keys `HKCU:\Printers\DevModes2` and `HKCU:\Printers\DevModePerUser`. It writes a recovery entry to `HKCU:\Printers\DevModeBackup` in case of application crash.
- **DEVMODE Override**: Sets `dmPaperWidth` and `dmPaperLength` (in tenths-of-millimeter), updates `dmPaperSize` to the matched registered paper form ID (`RawKind`), and enables custom layout dimensions.
- **Cache Invalidation**: Broadcasts the `WM_DEVMODECHANGE` window notification using win32 API to force active system print spoolers to reload configurations.
- **Spooler Printing**: Calls `Printing.directPrintPdf(..., usePrinterSettings: true)` to bypass duplicate dialog prompts, routing the job directly through the newly-applied registry preferences.
- **Registry Restoration**: A 5-second delay is introduced to give the OS print queue enough time to ingest and lock the customized print settings. Afterwards, the manager restores original backup preferences and broadcasts `WM_DEVMODECHANGE` again.
- **Self-Healing Startup**: On application startup, `healOnStartup()` scans `HKCU:\Printers\DevModeBackup` and restores any preferences that were left modified due to unexpected application exits or crashes.
- **Job Mutex**: A serialized execution queue prevents overlapping print jobs from concurrently overwriting and corrupting registry values.

### 2. Paper Form Size Verification ([WindowsPaperValidator](file:///g:/GitHub/stickify/lib/core/services/printing/windows/windows_paper_validator.dart))
- Before initiating a print job on Windows, the system queries the target printer using `System.Drawing.Printing.PrinterSettings.PaperSizes` via PowerShell.
- It verifies that a registered paper form size matches the requested layout within a `±1.5 mm` tolerance (supporting standard and landscape/flipped orientations).
- If no matching paper size is registered on the system, the print job fails with a clear validation instruction directing the user to register the custom paper sheet in Windows Print Server Properties first.

### 3. Dynamic Landscape Shift Offset Correction
- **Problem**: Custom landscape sheets (width > height) printed on Windows spooled in Portrait mode (`dmOrientation = 1` in DEVMODE) experienced a vertical shift of approximately 5mm, where the top of the sticker was cut off.
- **RCA**: The Windows print spooler C++ layer (`print_job.cpp`) translates the PDF page coordinates on the physical canvas by subtracting the driver's unprintable margins (`-marginLeft`, `-marginTop` = typically ~3mm). However, for landscape dimensions printed under a Portrait spooling job, the printer driver GDI coordinate origin is physically at 0mm (borderless origin). Subtracting the top margin shifts the entire layout **UP** relative to the physical page, cutting off elements.
- **Why Horizontal remains Unshifted**: The printer driver natively aligns the horizontal coordinate system correctly. Adding a horizontal shift (`shiftX`) causes elements to print shifted to the right (e.g. shifting the left margin by 3mm). Therefore, only the vertical axis requires correction.
- **Solution**:
  - The PDF document compilation is executed dynamically inside the `onLayout` callback of `Printing.directPrintPdf`, capturing the driver-reported margins (`format.marginLeft` and `format.marginTop`) dynamically.
  - If the layout configuration is landscape (`pageWidth > pageHeight`), the layout engine adds the top margin as a positive offset to the `y` coordinates (`shiftY = format.marginTop`), which counters the negative offset applied by the Windows print spooler C++ layer (`0 - marginTop + marginTop = 0mm`).
  - `shiftX` is kept at `0` to prevent horizontal alignment shifts, maintaining 100% accurate placement.
  - Portrait sheets (width <= height) skip this adjustment, preserving their original stable alignment.

---

## 9. Future Platform Extensibility Guide

The decoupling of layout engines and concrete print services makes it simple to extend custom hardware/driver corrections to other operating systems (such as macOS, Linux, or Android).

### Extensibility Roadmap

To add specialized support for a new operating system, follow this three-step checklist:

#### 1. Implement Custom Validation (Optional)
If the new platform requires verifying hardware capabilities or forms (similar to the Windows paper validator):
- Create `lib/core/services/printing/new_platform/new_platform_paper_validator.dart`.
- Implement [PaperValidationEngine](file:///g:/GitHub/stickify/lib/domain/services/paper_validation_engine.dart).
- Return `true` on other platforms.

#### 2. Implement Platform Print Service
Create a dedicated print service subclass under `lib/core/services/printing/new_platform/`:
- Create `new_platform_print_service.dart` implementing [PrintService](file:///g:/GitHub/stickify/lib/domain/services/print_service.dart).
- Pass [LabelLayoutEngine](file:///g:/GitHub/stickify/lib/domain/services/label_layout_engine.dart) in the constructor to reuse the platform-independent PDF generator.
- Implement any platform-specific setup, native printer calls, or driver configurations inside `printLabels`.

#### 3. Inject Platform-Specific Service
Register the new class conditionally in the application's dependency injection root [app.dart](file:///g:/GitHub/stickify/lib/app/view/app.dart):
- Import the new service.
- Modify the `_printService` setup block:
  ```dart
  final layoutEngine = const LabelPdfLayoutEngine();
  if (Platform.isWindows) {
    _printService = WindowsPrintService(
      layoutEngine: layoutEngine,
      paperValidator: WindowsPaperValidator(),
      devModeManager: WindowsDevModeManager(),
    );
  } else if (Platform.isMacOS) { // Example for macOS custom implementation
    _printService = MacOSPrintService(
      layoutEngine: layoutEngine,
      // Pass other macOS-specific managers
    );
  } else {
    _printService = PdfPrintService(layoutEngine: layoutEngine);
  }
  ```

This architecture guarantees that existing layout calculations and platform implementations are left completely untouched and free of regressions when new target operating systems are introduced.
