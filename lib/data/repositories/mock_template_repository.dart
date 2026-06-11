import 'dart:async';
import 'package:stickify/domain/domain.dart';

/// Mock implementation of [TemplateRepository] providing seed layouts.
///
/// Seeds a few standard templates such as shipping labels, HAZMAT tags,
/// and retail price stickers.
class MockTemplateRepository implements TemplateRepository {
  /// Creates a [MockTemplateRepository] and seeds default layouts.
  MockTemplateRepository() {
    _seedTemplates();
  }

  final Map<String, LabelTemplate> _templates = {};

  void _seedTemplates() {
    // 1. A4 Shipping Label (4x6")
    const shipSheet = SheetConfig(
      pageWidth: 210,
      pageHeight: 297,
      marginTop: 15,
      marginBottom: 15,
      marginLeft: 15,
      marginRight: 15,
      columns: 2,
      rows: 2,
      columnGap: 10,
      rowGap: 10,
    );
    const shipSticker = StickerConfig(
      widthMm: 101.6, // 4"
      heightMm: 152.4, // 6"
      cornerRadiusMm: 4,
      printableArea: [
        StickerPoint(5, 5),
        StickerPoint(96.6, 5),
        StickerPoint(96.6, 147.4),
        StickerPoint(5, 147.4),
      ],
    );
    final shipElements = <ElementBlueprint>[
      const ShapeElementBlueprint(
        id: 'ship-border',
        x: 10,
        y: 10,
        width: 320,
        height: 480,
        rotation: 0,
        fillColorHex: 0x00FFFFFF,
        strokeColorHex: 0xFF000000,
        strokeWidth: 2,
        cornerRadius: 4,
        isFilled: false,
      ),
      const TextElementBlueprint(
        id: 'ship-title',
        x: 20,
        y: 20,
        width: 300,
        height: 40,
        rotation: 0,
        content: 'PRIORITY MAIL',
        isDynamic: false,
        fontSize: 24,
        fontWeightValue: 700,
        textAlign: BlueprintTextAlign.center,
        colorHex: 0xFF000000,
      ),
      const BarcodeElementBlueprint(
        id: 'ship-barcode',
        x: 40,
        y: 350,
        width: 260,
        height: 80,
        rotation: 0,
        data: '{{product.sku}}',
        isDynamic: true,
        barcodeType: BlueprintBarcodeType.code128,
        showLabel: true,
      ),
    ];
    _templates['temp-001'] = LabelTemplate(
      id: 'temp-001',
      name: 'A4 Shipping Label',
      sheetConfig: shipSheet,
      stickerConfig: shipSticker,
      elements: shipElements,
      isFinalized: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    // 2. Hazardous Material Tag (10x15cm)
    const hazSheet = SheetConfig(
      pageWidth: 210,
      pageHeight: 297,
      marginTop: 20,
      marginBottom: 20,
      marginLeft: 20,
      marginRight: 20,
      columns: 2,
      rows: 2,
      columnGap: 5,
      rowGap: 5,
    );
    const hazSticker = StickerConfig(
      widthMm: 100,
      heightMm: 150,
      cornerRadiusMm: 0,
      printableArea: [
        StickerPoint(0, 0),
        StickerPoint(100, 0),
        StickerPoint(100, 150),
        StickerPoint(0, 150),
      ],
    );
    final hazElements = <ElementBlueprint>[
      const ShapeElementBlueprint(
        id: 'haz-border',
        x: 5,
        y: 5,
        width: 290,
        height: 440,
        rotation: 0,
        fillColorHex: 0x22FF0000,
        strokeColorHex: 0xFFFF0000,
        strokeWidth: 4,
        cornerRadius: 0,
        isFilled: true,
      ),
      const TextElementBlueprint(
        id: 'haz-text-1',
        x: 15,
        y: 50,
        width: 270,
        height: 30,
        rotation: 0,
        content: 'DANGER',
        isDynamic: false,
        fontSize: 28,
        fontWeightValue: 700,
        textAlign: BlueprintTextAlign.center,
        colorHex: 0xFFFF0000,
      ),
    ];
    _templates['temp-002'] = LabelTemplate(
      id: 'temp-002',
      name: 'Hazardous Material Tag',
      sheetConfig: hazSheet,
      stickerConfig: hazSticker,
      elements: hazElements,
      isFinalized: true,
      updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
    );

    // 3. Product Price Sticker (2x1")
    const priceSheet = SheetConfig(
      pageWidth: 215.9,
      pageHeight: 279.4,
      marginTop: 10,
      marginBottom: 10,
      marginLeft: 10,
      marginRight: 10,
      columns: 4,
      rows: 10,
      columnGap: 5,
      rowGap: 5,
    );
    const priceSticker = StickerConfig(
      widthMm: 50.8, // 2"
      heightMm: 25.4, // 1"
      cornerRadiusMm: 2,
      printableArea: [
        StickerPoint(2, 2),
        StickerPoint(48.8, 2),
        StickerPoint(48.8, 23.4),
        StickerPoint(2, 23.4),
      ],
    );
    final priceElements = <ElementBlueprint>[
      const TextElementBlueprint(
        id: 'price-name',
        x: 10,
        y: 10,
        width: 180,
        height: 20,
        rotation: 0,
        content: '{{product.name}}',
        isDynamic: true,
        fontSize: 10,
        fontWeightValue: 700,
        textAlign: BlueprintTextAlign.left,
        colorHex: 0xFF000000,
      ),
      const TextElementBlueprint(
        id: 'price-sku',
        x: 10,
        y: 35,
        width: 180,
        height: 15,
        rotation: 0,
        content: 'SKU: {{product.sku}}',
        isDynamic: true,
        fontSize: 8,
        fontWeightValue: 400,
        textAlign: BlueprintTextAlign.left,
        colorHex: 0xFF555555,
      ),
    ];
    _templates['temp-003'] = LabelTemplate(
      id: 'temp-003',
      name: 'Product Price Sticker',
      sheetConfig: priceSheet,
      stickerConfig: priceSticker,
      elements: priceElements,
      isFinalized: true,
      updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
    );

    // 4. Custom Pallet Slip (8x11")
    const palletSheet = SheetConfig(
      pageWidth: 215.9,
      pageHeight: 279.4,
      marginTop: 0,
      marginBottom: 0,
      marginLeft: 0,
      marginRight: 0,
      columns: 1,
      rows: 1,
      columnGap: 0,
      rowGap: 0,
    );
    const palletSticker = StickerConfig(
      widthMm: 215.9,
      heightMm: 279.4,
      cornerRadiusMm: 0,
      printableArea: [
        StickerPoint(10, 10),
        StickerPoint(205.9, 10),
        StickerPoint(205.9, 269.4),
        StickerPoint(10, 269.4),
      ],
    );
    final palletElements = <ElementBlueprint>[
      const TextElementBlueprint(
        id: 'pallet-title',
        x: 20,
        y: 40,
        width: 500,
        height: 50,
        rotation: 0,
        content: 'PALLET IDENTIFICATION',
        isDynamic: false,
        fontSize: 32,
        fontWeightValue: 700,
        textAlign: BlueprintTextAlign.center,
        colorHex: 0xFF000000,
      ),
      const QrElementBlueprint(
        id: 'pallet-qr',
        x: 200,
        y: 300,
        width: 200,
        height: 200,
        rotation: 0,
        data: 'https://stickify.io/pallets/{{product.id}}',
        isDynamic: true,
      ),
    ];
    _templates['temp-004'] = LabelTemplate(
      id: 'temp-004',
      name: 'Custom Pallet Slip',
      sheetConfig: palletSheet,
      stickerConfig: palletSticker,
      elements: palletElements,
      isFinalized: true,
      updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    );
  }

  @override
  Future<List<LabelTemplate>> fetchTemplates() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _templates.values.toList()
      ..sort((a, b) => (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0)));
  }

  @override
  Future<LabelTemplate> fetchTemplate(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final template = _templates[id];
    if (template == null) {
      throw Exception('Template not found: $id');
    }
    return template;
  }

  @override
  Future<LabelTemplate> createTemplate(String name) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final id = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final template = LabelTemplate(
      id: id,
      name: name,
      updatedAt: DateTime.now(),
    );
    _templates[id] = template;
    return template;
  }

  @override
  Future<void> saveSheetConfig(String templateId, SheetConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final template = _templates[templateId];
    if (template == null) throw Exception('Template not found: $templateId');
    _templates[templateId] = template.copyWith(
      sheetConfig: config,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveStickerConfig(String templateId, StickerConfig config) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final template = _templates[templateId];
    if (template == null) throw Exception('Template not found: $templateId');
    _templates[templateId] = template.copyWith(
      stickerConfig: config,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> saveElements(
      String templateId, List<ElementBlueprint> elements) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final template = _templates[templateId];
    if (template == null) throw Exception('Template not found: $templateId');
    _templates[templateId] = template.copyWith(
      elements: elements,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> finalizeTemplate(String templateId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    final template = _templates[templateId];
    if (template == null) throw Exception('Template not found: $templateId');
    _templates[templateId] = template.copyWith(
      isFinalized: true,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteTemplate(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _templates.remove(id);
  }
}
