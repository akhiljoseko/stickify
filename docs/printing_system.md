# Printing System Module Documentation

This document describes the architectural design, requirements, and concrete implementation details of the physical PDF printing engine in the Stickify application.

---

## 1. Requirements

The printing module is designed to map visual labels designed in the editor to actual physical sheets (e.g., A4 pages) and dispatch them to the host operating system's printing dialog.

Key operational requirements include:
- **Sheet Configuration Grid**: Calculate slots on print sheets from column/row layouts and margins.
- **Dynamic Reflowing Grid**: Support toggling individual slots on a sheet to mark them as "skipped/used" (e.g., when reusing partially printed label sheets). Enable automatic downstream reflowing.
- **Millimeter Accuracy**: Scale all layout calculations in points to match precise millimeter dimensions on physical paper.
- **Responsive Parameter Panel**: Adapt the printer selection, quantity input, and sheet previews dynamically across all desktop, tablet, and mobile viewports.
- **Thread Safety & Performance**: Prevent blocking the main UI thread during CPU-intensive PDF page construction.
- **Direct System Dispatch**: Hand off compiled documents directly to the operating system's native print manager.

---

## 2. Architecture & System Decoupling

To enforce Clean Architecture boundaries, the printing infrastructure is completely decoupled from the presentation layer:

```
[UI: PrintSetupPage] ──▶ [State: PrintWorkflowCubit]
                                │
                                ▼ (abstract interface)
                      [Domain: PrintService]
                                ▲
                                │ (concrete implementation)
                     [Core: PdfPrintService]
```

- **Domain Layer (`lib/domain/services/print_service.dart`)**: Exposes an abstract service interface `PrintService` specifying the `printLabels` call contract. This layer has no dependencies on packages like `pdf` or `printing`.
- **Infrastructure Layer (`lib/core/services/pdf_print_service.dart`)**: Implements `PdfPrintService` using the third-party `pdf` and `printing` packages.
- **UI Injection**: Placed in `RepositoryProvider<PrintService>` at the application root (`lib/app/view/app.dart`) and injected directly into `PrintWorkflowCubit` inside `PrintSetupPage`.

---

## 3. Background Isolate Compilation

Creating documents with hundreds of elements, rendering high-resolution barcodes, and saving the output bytes is a CPU-intensive operation. Running this synchronously on the main Dart UI thread blocks frames, causing the application to hang and displaying the macOS spinning loading indicator.

### Solution: Spawning a Dart Isolate
- Image assets, network URLs, and local file images are pre-cached in memory on the main thread (since reading files and assets uses platform channels that are only available on the main thread).
- The pre-cached image bytes, template layout, product, and variant configuration are sent to a background Dart Isolate via `Isolate.run()`.
- The background isolate constructs the `pw.Document` and serializes it to `Uint8List` using `doc.save()`.
- The main thread awaits the compiled bytes and forwards them directly to the native printing channel.

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
- **PdfElementRendererRegistry**: Maps blueprint classes (e.g. `TextElementBlueprint`) to their concrete rendering strategies (e.g. `PdfTextElementRenderer`).
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

## 8. Printer Calibration

Custom calibration profiles adjust print jobs per device model to correct for driver/hardware feed offsets:
- Supports X/Y translation offsets in millimeters.
- Supports X/Y scaling coefficients.
- Settings are applied dynamically during physical coordinates computation, keeping design templates clean and portable.

---

## 9. macOS Deadlock Prevention & App Sandbox

Enabling printing on macOS requires addressing two system boundaries:
1. **App Sandbox boundary**: The macOS application manifests (`DebugProfile.entitlements` and `Release.entitlements`) explicitly declare the printing capability key:
   ```xml
   <key>com.apple.security.print</key>
   <true/>
   ```
2. **Platform Channel Deadlock**: Under experimental merged UI/Platform threading configurations on macOS, a synchronous callback loop between native printing and Dart can cause a deadlock. We resolve this by:
   - Setting `dynamicLayout: false` inside the `Printing.layoutPdf` call.
   - Disabling the experimental merged thread model via the `FLTEnableMergedPlatformUIThread` key set to `false` in `Info.plist`.

---

## 10. Android Custom MediaSize Print Bridge

By default, the third-party `printing` plugin's native Android implementation does not configure a custom native `PrintAttributes.MediaSize` when a non-standard page size is requested. Instead, if the requested size falls outside standard predefined dimensions (such as ISO A4 or NA Letter), it defaults to `PrintAttributes.MediaSize.UNKNOWN_PORTRAIT` or `UNKNOWN_LANDSCAPE`. This causes the native Android print spooler and printer drivers to fallback to standard A4/Letter formats, scaling or cropping custom sticker sheets.

### Native Custom Bridge Solution
To guarantee exact physical paper sizes and prevent scaling on Android devices, Stickify bypasses the plugin's print pathway on Android using a custom platform method channel `co.inevitablesoftware.stickify/custom_print` implemented natively in `MainActivity.kt`:
- **Dimensions Conversion**: The requested custom sheet width and height (defined in millimeters) are converted to mils:
  ```kotlin
  val widthMils = (widthMm / 25.4 * 1000.0).toInt()
  val heightMils = (heightMm / 25.4 * 1000.0).toInt()
  ```
- **Custom MediaSize Instantiation**: Instantiates a custom `PrintAttributes.MediaSize` using these exact mils values:
  ```kotlin
  val customMediaSize = PrintAttributes.MediaSize("custom_sticker_sheet", "Custom Sticker Sheet", widthMils, heightMils)
  ```
- **Zero Margins Enforcement**: Instructs the builder to use zero physical margins (`PrintAttributes.Margins.NO_MARGINS`) to prevent offsets.
- **Direct Spooler Feeding**: A native `PrintDocumentAdapter` writes the raw generated PDF bytes directly to the printer file descriptor in `onWrite`.
- **Active Mismatch Protection**: Within the adapter's `onLayout` callback, the native bridge compares the spooler's selected print size (`newAttributes.mediaSize`) against our requested custom width and height (converted to mils). A tolerance of `100 mils` (~2.54 mm) is used to account for minor printer-driver rounding errors, and orientation checks cover both portrait and landscape orientation matches. If the host OS or chosen printer forces the job to resize to an unsupported standard size (like A4 or Letter), the adapter invokes `callback.onLayoutFailed()`. This immediately halts the print job, displays a descriptive error in the system print dialog, and disables physical printing to protect physical sticker sheets.

This custom platform channel is automatically active for all Android print jobs in release and debug modes. In unit test environments (`FLUTTER_TEST`), it falls back to `Printing.layoutPdf` to ensure compatibility with standard Dart platform interface mocking.
