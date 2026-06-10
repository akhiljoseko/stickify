# Label Designing Editor Module Documentation

This document describes the architectural design, requirements, and concrete implementation details of the visual template designer and label editor in the Stickify application.

---

## 1. Requirements

The label editor module provides a visual canvas for designing custom label templates. Requirements include:
- **Interactive Canvas**: Drag, select, resize, rotate, and delete template design elements.
- **Multiple Element Blueprints**: Support placing static/dynamic text, shapes (rectangles, borders), 1D barcodes (Code 128, EAN-13), 2D QR codes, and custom images.
- **Dynamic Token Resolution**: Place placeholders (e.g., `{{product.name}}` or `{{variant.mrp}}`) that bind to actual product/variant variables at print time.
- **Coordinate Precision**: Handle position (x, y), dimensions (width, height), and rotation (degrees) with sub-pixel alignment.
- **Properties Inspector**: Edit text style (font size, weight, alignment, color, spacing), shape attributes (stroke color, stroke width, corner radius, fill color), and image source URLs.

---

## 2. Editor UI Architecture

The editor interface follows a split-view design optimized for desktop viewports:

```
┌─────────────────┬───────────────────────────────┬─────────────────┐
│                 │                               │                 │
│                 │                               │  Properties     │
│  Element        │         Editor Canvas         │  Panel          │
│  Palette        │        (Widget Stack)         │  (Forms, Sliders│
│  (Drag sources) │                               │   Color Picker) │
│                 │                               │                 │
└─────────────────┴───────────────────────────────┴─────────────────┘
```

- **Element Palette (`lib/presentation/features/template_editor/label_editor/widgets/element_palette.dart`)**: Side panel containing icons representing each design element type. Clicking an element instantiates a new blueprint and adds it to the editor state.
- **Editor Canvas (`lib/presentation/features/template_editor/label_editor/widgets/editor_canvas.dart`)**: Interactive workspace displaying the label bounding box. Users can drag elements inside the canvas area.
- **Properties Panel (`lib/presentation/features/template_editor/label_editor/widgets/properties_panel.dart`)**: Contextual inspector panel that automatically opens when an element is selected, displaying forms/sliders appropriate for that element's properties.

---

## 3. Coordinate Space & Virtual Scaling

Stickers are defined in physical millimeters (e.g. `100mm` by `60mm`), but rendering millimeters directly on screens with varying pixel densities (DPI) causes scaling issues.

### The 4x Coordinate Space Solution
- To decoupling editor layouts from screen DPI, Stickify uses a virtual coordinate system where **1 millimeter = 4 pixels**.
- A sticker with dimension `100mm` by `60mm` maps to a virtual canvas of size `400px` by `240px` inside the editor.
- Elements placed on the canvas are positioned using this 4x coordinate space.
- When displaying on-screen previews (such as inside the sheet print configuration preview), the entire Stack is wrapped in a `FittedBox` which scales the virtual canvas down/up to fit the viewport constraints without changing coordinate ratios.

---

## 4. Element Rendering Strategy (UI Layer)

To translate element blueprints to standard Flutter UI widgets, the presentation layer uses a Strategy Pattern:

- **LabelElementRenderer**: Declares a standard interface:
  ```dart
  abstract interface class LabelElementRenderer {
    Widget render(
      BuildContext context,
      ElementBlueprint blueprint, {
      Product? product,
      ProductVariant? variant,
    });
  }
  ```
- **Registry Pattern (`ElementRendererRegistry`)**: Maps blueprint classes to their UI renderers:
  - `TextElementBlueprint` ──▶ `TextElementRenderer`
  - `ShapeElementBlueprint` ──▶ `ShapeElementRenderer`
  - `BarcodeElementBlueprint` ──▶ `BarcodeElementRenderer`
  - `QrElementBlueprint` ──▶ `QrElementRenderer`
  - `ImageElementBlueprint` ──▶ `ImageElementRenderer`
- **Dynamic Render Routing**: `ElementRendererRegistry.forBlueprint(bp).render(context, bp, product: product, variant: variant)` is called for each element.

---

## 5. Dynamic Token Binding Engine

Placeholders are resolved at render-time using [TextElementRenderer.resolveToken](file:///Volumes/WD-Black-1TB/akhiljose/personal-projects/stickify/lib/presentation/features/template_editor/renderers/text_element_renderer.dart):

```
Token String: "MRP: ₹{{variant.mrp}}"
                    │
                    ▼ (Regex Evaluation)
Resolved Output: "MRP: ₹299.00"
```

The binding engine supports:
- **Product Tokens**: `{{product.name}}`, `{{product.sku}}`, `{{product.assignedStation}}`, etc.
- **Variant Tokens**: `{{variant.name}}`, `{{variant.sku}}`, `{{variant.mrp}}`, `{{variant.wholesale}}`.
- **Ingredients/Nutrition**: Translates composite lists dynamically.

---

## 6. Drag, Resize & Snap Math

- **Drag Positioning**: Canvas drags translate cursor offsets directly to the virtual coordinate space, updating the blueprint's `x` and `y` coordinates in the template state.
- **Resizing**: Elements show handle overlay indicators. Dragging handles updates the blueprint's `width` and `height` properties.
- **Grid Snapping**: If snapping is enabled in the editor toolbar, coordinates automatically round to the nearest grid step (e.g. 5px or 10px intervals) to ease element alignment.
