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
- **Optimization**: To avoid layout duplication, elements are rendered **once** per print job to build a list of cached widgets (`cachedStickerElements`). The grid builder then wraps this pre-built list inside each active slot cell.

---

## 5. Precise Metric Conversion & Layout

To ensure sub-millimeter parity with on-screen templates:
- Physical coordinates in the PDF package are defined in points (1/72 inch).
- The templates are defined in millimeters.
- All dimensions (page width, margins, sticker width, row gaps) are scaled using `PdfPageFormat.mm` (equivalent to `2.834645669291339` points per millimeter).
- The virtual label canvas is designed at a 4x ratio (`widthMm * 4` by `heightMm * 4`) to allow high-density element layout. During print compilation, the elements are placed inside a `SizedBox` matching the virtual size and scaled into the physical millimeter container using `FittedBox`.

---

## 6. macOS Deadlock Prevention & App Sandbox

Enabling printing on macOS requires addressing two system boundaries:
1. **App Sandbox boundary**: The macOS application manifests (`DebugProfile.entitlements` and `Release.entitlements`) explicitly declare the printing capability key:
   ```xml
   <key>com.apple.security.print</key>
   <true/>
   ```
2. **Platform Channel Deadlock**: Under experimental merged UI/Platform threading configurations on macOS, a synchronous callback loop between native printing and Dart can cause a deadlock. We resolve this by:
   - Setting `dynamicLayout: false` inside the `Printing.layoutPdf` call.
   - Disabling the experimental merged thread model via the `FLTEnableMergedPlatformUIThread` key set to `false` in `Info.plist`.
