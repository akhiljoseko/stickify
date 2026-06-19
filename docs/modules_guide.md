# Label Grid Application Modules Guide

This document provides a comprehensive overview of every logical module in the Label Grid Industrial Canvas application, outlining their requirements, architecture, and concrete implementation details.

---

## Table of Contents
1. [Dashboard Module](#1-dashboard-module)
2. [Product Management Module](#2-product-management-module)
3. [Template Editor Module](#3-template-editor-module)
4. [PDF Generation & Print Management Module](#4-pdf-generation--print-management-module)
5. [Search & Reporting Module](#5-search--reporting-module)
6. [Data & Storage Infrastructure](#6-data--storage-infrastructure)

---

## 1. Dashboard Module

### Requirements
- Provide logistics managers and warehouse operators with a high-level operational overview.
- Monitor active printer station statuses (online, offline, warning).
- Display a real-time list of recent print jobs, including status indicators (queued, printing, completed, error).
- Display shortcut access to frequently printed products for rapid workflow initiation.
- Adapt cleanly across desktop, tablet, and mobile viewports.

### Implementation Details
- **Location:** `lib/presentation/features/dashboard/`
- **State Management:** Coordinates three different Cubits:
  - `AuthCubit` (tracks user details and sign-in status).
  - `RecentPrintJobsCubit` (loads recent print logs).
  - `FrequentProductsCubit` (loads products that are printed most often).
- **Responsive Layout:** Uses `AdaptiveLayoutSwitcher` and `AdaptiveValue` to render a multi-column dashboard grid on desktop (statistics + side panel) that reflows into a single-column layout on mobile viewports.

---

## 2. Product Management Module

### Requirements
- Manage the catalog of products and packaging variants.
- Support adding and editing products with metadata (name, SKU, category, shelf life, instructions, ingredients, and nutrition facts).
- Manage multiple variant configurations (weight/quantity, wholesale price, MRP in INR, SKU, unit) under a single parent product.
- Allow uploading/selecting a local product image via an image picker and save it into a managed workspace.
- Inherit parent product details for variants where appropriate.

### Implementation Details
- **Location:** `lib/presentation/features/product/`
- **State Management:** `ProductCubit` handles the state transitions (`ProductCatalogInitial`, `ProductCatalogLoading`, `ProductCatalogSuccess`, `ProductCatalogError`) for fetching, saving, updating, and deleting products.
- **UI Architecture:** Employs a split-pane layout on desktop: a high-density tabular grid on the left and a detail/edit inspector panel on the right. Local images are picked using the `image_picker` package, copied into the application storage directory under `~/documents/label-grid/product-images/` using the custom `FileStorageService`, and rendered uniformly using the `AppImage` widget.
- **Token Consistency:** Variant SKUs prefill using the parent product SKU to enforce consistent corporate naming schemas.

---

## 3. Template Editor Module

### Requirements
- Offer a visual drag-and-drop canvas for designing physical label stickers.
- Support placing multiple element types:
  - **Text Elements**: Static or dynamic tokens (e.g. `{{product.name}}`, `{{variant.sku}}`, `{{variant.mrp}}`).
  - **Shape Elements**: Rectangles, borders, filled blocks, with custom corner radius and stroke width.
  - **Barcode Elements (1D)**: Rendering standard symbologies (Code 128, EAN-13) derived from dynamic SKU values.
  - **QR Code Elements (2D)**: Supporting dynamic links or textual payload resolution.
  - **Image Elements**: Placing branding images via local paths, network URLs, or asset directories.
- Track precise coordinate transformations (x, y, width, height, rotation in degrees).

### Implementation Details
- **Location:** `lib/presentation/features/template_editor/`
- **Design Patterns:** Uses the **Strategy Pattern** for rendering individual elements on the canvas. The `ElementRendererRegistry` routes each blueprint type to its corresponding UI renderer (`TextElementRenderer`, `BarcodeElementRenderer`, etc.).
- **Canvas Math**: Uses virtual coordinate scaling (4x size multiplier) to ensure high-fidelity previews on screen while keeping layouts decoupled from physical screen DPI.

---

## 4. PDF Generation & Print Management Module

### Requirements
- Select a product variant and matching label template.
- Compile dynamic layout blueprints, binding token templates to actual product and variant values.
- Calculate print volumes and layout slots across physical print sheets (e.g. A4 pages).
- Enable operators to tap and toggle sheet slots (marking them as "used" or "skipped" if using a partially printed label sheet).
- Shift and reflow downstream labels automatically based on disabled slots.
- Generate high-fidelity PDF documents matching exact sheet geometries (measured in millimeters).
- Prevent UI thread blocks or application freezing during CPU-intensive PDF compilation.
- Launch the native Windows/system print dialog directly.

### Implementation Details
- **Location:** `lib/presentation/features/print/`
- **Clean Architecture Decoupling:** Uses the domain-level [PrintService](file:///g:/GitHub/stickify/lib/domain/services/print_service.dart) interface.
- **Background Isolate Offloading:** The concrete [PdfPrintService](file:///g:/GitHub/stickify/lib/core/services/pdf_print_service.dart) pre-caches all images on the main thread, then spawns a background isolate via `Isolate.run()` to compile the `pw.Document` and serialize it to bytes (`doc.save()`). This eliminates main thread freezes.
- **Windows Spooler Dispatch**: For Windows, [WindowsPrintService](file:///g:/GitHub/stickify/lib/core/services/printing/windows/windows_print_service.dart) performs native DEVMODE overrides and prints directly to bypass OS print dialogs, while [WindowsPaperValidator](file:///g:/GitHub/stickify/lib/core/services/printing/windows/windows_paper_validator.dart) validates paper format dimensions.
- **Strategy & Registry Patterns:** Uses [PdfElementRendererRegistry](file:///g:/GitHub/stickify/lib/core/services/pdf/pdf_element_renderer_registry.dart) and [PdfElementRenderer](file:///g:/GitHub/stickify/lib/core/services/pdf/pdf_element_renderer.dart) strategies to translate element blueprints to PDF widgets without large procedural conditional blocks.
- **Coordinate Conversion**: Multiplies all blueprint coordinates by `PdfPageFormat.mm` to map virtual layout pixels directly to physical PDF points.

---

## 5. Search & Reporting Module

### Requirements
- Provide unified search across products, variants, templates, and recent print jobs.
- Display search results in an industrial, high-density data table.
- Direct operators to relevant action screens (e.g., printing or editing) directly from search results.

### Implementation Details
- **Location:** `lib/presentation/features/search/`
- **State Management:** `SearchCubit` listens to query strings and interacts with `SearchRepository` to filter through local cache indexes.
- **UI Pattern:** Renders a clean search text field with automatic debouncing to prevent excessive repository queries.

---

## 6. Data & Storage Infrastructure

### Requirements
- Offline-first local data storage backed by seamless cloud sync triggers.
- Secure, structured folder hierarchy for custom local database boxes and media assets.
- Support file saving and custom copying operations for label template cover images and product pictures.

### Implementation Details
- **Location:** `lib/data/services/hive_local_database.dart`, `lib/data/repositories/`, and `lib/domain/services/file_storage_service.dart`
- **Local Database (Hive CE):** Initiates through [HiveLocalDatabase](file:///g:/GitHub/stickify/lib/data/services/hive_local_database.dart). On Windows, it creates a dedicated directory at `~/documents/label-grid/database` to store Hive box files (`.hive` files).
- **Remote Synchronization:** Employs the decorator pattern via repository sync utilities (e.g., [SyncingProductRepository](file:///g:/GitHub/stickify/lib/data/repositories/syncing_product_repository.dart) and [SyncingTemplateRepository](file:///g:/GitHub/stickify/lib/data/repositories/syncing_template_repository.dart)). Changes are applied locally to Hive, queued, and pushed to Cloud Firestore on background workers.
- **File & Media Storage:** The platform-specific [FileStorageService](file:///g:/GitHub/stickify/lib/domain/services/file_storage_service.dart) organizes user images:
  - Product images are stored under `~/documents/label-grid/product-images/`.
  - Template cover images are stored under `~/documents/label-grid/template-images/`.
  - Generates collision-resistant unique names for saved attachments (`prod_<uuid>.<ext>` and `tpl_<uuid>.<ext>`).
