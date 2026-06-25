// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class ElementBlueprintHiveModelAdapter
    extends TypeAdapter<ElementBlueprintHiveModel> {
  @override
  final typeId = 0;

  @override
  ElementBlueprintHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ElementBlueprintHiveModel(
      id: fields[0] as String,
      type: fields[1] as String,
      x: (fields[2] as num).toDouble(),
      y: (fields[3] as num).toDouble(),
      width: (fields[4] as num).toDouble(),
      height: (fields[5] as num).toDouble(),
      rotation: (fields[6] as num).toDouble(),
      content: fields[7] as String?,
      isDynamic: fields[8] as bool?,
      fontSize: (fields[9] as num?)?.toDouble(),
      fontWeightValue: (fields[10] as num?)?.toInt(),
      textAlign: fields[11] as String?,
      colorHex: (fields[12] as num?)?.toInt(),
      fillColorHex: (fields[13] as num?)?.toInt(),
      strokeColorHex: (fields[14] as num?)?.toInt(),
      strokeWidth: (fields[15] as num?)?.toDouble(),
      cornerRadius: (fields[16] as num?)?.toDouble(),
      isFilled: fields[17] as bool?,
      data: fields[18] as String?,
      barcodeType: fields[19] as String?,
      showLabel: fields[20] as bool?,
      assetPath: fields[21] as String?,
      networkUrl: fields[22] as String?,
      localFilePath: fields[23] as String?,
      fit: fields[24] as String?,
      maxLines: (fields[25] as num?)?.toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, ElementBlueprintHiveModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.type)
      ..writeByte(2)
      ..write(obj.x)
      ..writeByte(3)
      ..write(obj.y)
      ..writeByte(4)
      ..write(obj.width)
      ..writeByte(5)
      ..write(obj.height)
      ..writeByte(6)
      ..write(obj.rotation)
      ..writeByte(7)
      ..write(obj.content)
      ..writeByte(8)
      ..write(obj.isDynamic)
      ..writeByte(9)
      ..write(obj.fontSize)
      ..writeByte(10)
      ..write(obj.fontWeightValue)
      ..writeByte(11)
      ..write(obj.textAlign)
      ..writeByte(12)
      ..write(obj.colorHex)
      ..writeByte(13)
      ..write(obj.fillColorHex)
      ..writeByte(14)
      ..write(obj.strokeColorHex)
      ..writeByte(15)
      ..write(obj.strokeWidth)
      ..writeByte(16)
      ..write(obj.cornerRadius)
      ..writeByte(17)
      ..write(obj.isFilled)
      ..writeByte(18)
      ..write(obj.data)
      ..writeByte(19)
      ..write(obj.barcodeType)
      ..writeByte(20)
      ..write(obj.showLabel)
      ..writeByte(21)
      ..write(obj.assetPath)
      ..writeByte(22)
      ..write(obj.networkUrl)
      ..writeByte(23)
      ..write(obj.localFilePath)
      ..writeByte(24)
      ..write(obj.fit)
      ..writeByte(25)
      ..write(obj.maxLines);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ElementBlueprintHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class IngredientHiveModelAdapter extends TypeAdapter<IngredientHiveModel> {
  @override
  final typeId = 1;

  @override
  IngredientHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IngredientHiveModel(
      name: fields[0] as String,
      percentage: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, IngredientHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.percentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LabelTemplateHiveModelAdapter
    extends TypeAdapter<LabelTemplateHiveModel> {
  @override
  final typeId = 2;

  @override
  LabelTemplateHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LabelTemplateHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      isFinalized: fields[2] as bool,
      updatedAt: fields[3] as DateTime?,
      sheetConfig: fields[4] as SheetConfigHiveModel?,
      stickerConfig: fields[5] as StickerConfigHiveModel?,
      elements: fields[6] == null
          ? const []
          : (fields[6] as List).cast<ElementBlueprintHiveModel>(),
      imageUrl: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LabelTemplateHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.isFinalized)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.sheetConfig)
      ..writeByte(5)
      ..write(obj.stickerConfig)
      ..writeByte(6)
      ..write(obj.elements)
      ..writeByte(7)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabelTemplateHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NutritionFactsHiveModelAdapter
    extends TypeAdapter<NutritionFactsHiveModel> {
  @override
  final typeId = 3;

  @override
  NutritionFactsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NutritionFactsHiveModel(
      calories: (fields[0] as num).toDouble(),
      protein: (fields[1] as num).toDouble(),
      totalFat: (fields[2] as num).toDouble(),
      saturatedFat: (fields[3] as num).toDouble(),
      totalCarbs: (fields[4] as num).toDouble(),
      fiber: (fields[5] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, NutritionFactsHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.calories)
      ..writeByte(1)
      ..write(obj.protein)
      ..writeByte(2)
      ..write(obj.totalFat)
      ..writeByte(3)
      ..write(obj.saturatedFat)
      ..writeByte(4)
      ..write(obj.totalCarbs)
      ..writeByte(5)
      ..write(obj.fiber);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NutritionFactsHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrintJobHiveModelAdapter extends TypeAdapter<PrintJobHiveModel> {
  @override
  final typeId = 4;

  @override
  PrintJobHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrintJobHiveModel(
      id: fields[0] as String,
      productId: fields[12] as String,
      productName: fields[1] as String,
      variantId: fields[2] as String,
      variantName: fields[3] as String,
      variantSku: fields[4] as String,
      templateId: fields[5] as String,
      templateName: fields[6] as String,
      printerStation: fields[8] as String,
      printedAt: fields[9] as DateTime,
      labelCount: (fields[10] as num).toInt(),
      imageUrl: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, PrintJobHiveModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.variantId)
      ..writeByte(3)
      ..write(obj.variantName)
      ..writeByte(4)
      ..write(obj.variantSku)
      ..writeByte(5)
      ..write(obj.templateId)
      ..writeByte(6)
      ..write(obj.templateName)
      ..writeByte(8)
      ..write(obj.printerStation)
      ..writeByte(9)
      ..write(obj.printedAt)
      ..writeByte(10)
      ..write(obj.labelCount)
      ..writeByte(12)
      ..write(obj.productId)
      ..writeByte(13)
      ..write(obj.imageUrl);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintJobHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductHiveModelAdapter extends TypeAdapter<ProductHiveModel> {
  @override
  final typeId = 5;

  @override
  ProductHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductHiveModel(
      id: fields[0] as String,
      name: fields[1] as String,
      sku: fields[2] as String,
      category: fields[5] as String?,
      shelfLifeDays: (fields[6] as num?)?.toInt(),
      storageConditions: fields[7] as String?,
      imageUrl: fields[8] as String?,
      ingredients: fields[9] == null
          ? const []
          : (fields[9] as List).cast<IngredientHiveModel>(),
      nutritionFacts: fields[10] as NutritionFactsHiveModel?,
      variants: fields[11] == null
          ? const []
          : (fields[11] as List).cast<ProductVariantHiveModel>(),
      lastModified: fields[12] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductHiveModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sku)
      ..writeByte(5)
      ..write(obj.category)
      ..writeByte(6)
      ..write(obj.shelfLifeDays)
      ..writeByte(7)
      ..write(obj.storageConditions)
      ..writeByte(8)
      ..write(obj.imageUrl)
      ..writeByte(9)
      ..write(obj.ingredients)
      ..writeByte(10)
      ..write(obj.nutritionFacts)
      ..writeByte(11)
      ..write(obj.variants)
      ..writeByte(12)
      ..write(obj.lastModified);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductVariantHiveModelAdapter
    extends TypeAdapter<ProductVariantHiveModel> {
  @override
  final typeId = 6;

  @override
  ProductVariantHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductVariantHiveModel(
      name: fields[0] as String,
      quantity: (fields[1] as num).toDouble(),
      unit: fields[2] as String,
      wholesale: (fields[3] as num).toDouble(),
      mrp: (fields[4] as num).toDouble(),
      sku: fields[5] as String,
      defaultTemplateId: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductVariantHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.quantity)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.wholesale)
      ..writeByte(4)
      ..write(obj.mrp)
      ..writeByte(5)
      ..write(obj.sku)
      ..writeByte(6)
      ..write(obj.defaultTemplateId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductVariantHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SheetConfigHiveModelAdapter extends TypeAdapter<SheetConfigHiveModel> {
  @override
  final typeId = 7;

  @override
  SheetConfigHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SheetConfigHiveModel(
      pageWidth: (fields[0] as num).toDouble(),
      pageHeight: (fields[1] as num).toDouble(),
      marginTop: (fields[2] as num).toDouble(),
      marginBottom: (fields[3] as num).toDouble(),
      marginLeft: (fields[4] as num).toDouble(),
      marginRight: (fields[5] as num).toDouble(),
      columns: (fields[6] as num).toInt(),
      rows: (fields[7] as num).toInt(),
      columnGap: (fields[8] as num).toDouble(),
      rowGap: (fields[9] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, SheetConfigHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.pageWidth)
      ..writeByte(1)
      ..write(obj.pageHeight)
      ..writeByte(2)
      ..write(obj.marginTop)
      ..writeByte(3)
      ..write(obj.marginBottom)
      ..writeByte(4)
      ..write(obj.marginLeft)
      ..writeByte(5)
      ..write(obj.marginRight)
      ..writeByte(6)
      ..write(obj.columns)
      ..writeByte(7)
      ..write(obj.rows)
      ..writeByte(8)
      ..write(obj.columnGap)
      ..writeByte(9)
      ..write(obj.rowGap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SheetConfigHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StickerConfigHiveModelAdapter
    extends TypeAdapter<StickerConfigHiveModel> {
  @override
  final typeId = 8;

  @override
  StickerConfigHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StickerConfigHiveModel(
      widthMm: (fields[0] as num).toDouble(),
      heightMm: (fields[1] as num).toDouble(),
      cornerRadiusMm: (fields[2] as num).toDouble(),
      printableArea: fields[3] == null
          ? const []
          : (fields[3] as List).cast<StickerPointHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, StickerConfigHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.widthMm)
      ..writeByte(1)
      ..write(obj.heightMm)
      ..writeByte(2)
      ..write(obj.cornerRadiusMm)
      ..writeByte(3)
      ..write(obj.printableArea);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerConfigHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class StickerPointHiveModelAdapter extends TypeAdapter<StickerPointHiveModel> {
  @override
  final typeId = 9;

  @override
  StickerPointHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StickerPointHiveModel(
      x: (fields[0] as num).toDouble(),
      y: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, StickerPointHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.x)
      ..writeByte(1)
      ..write(obj.y);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StickerPointHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VariantPrintStatsHiveModelAdapter
    extends TypeAdapter<VariantPrintStatsHiveModel> {
  @override
  final typeId = 10;

  @override
  VariantPrintStatsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VariantPrintStatsHiveModel(
      variantSku: fields[0] as String,
      productId: fields[1] as String,
      productName: fields[2] as String,
      variantName: fields[3] as String,
      totalPrints: (fields[4] as num).toInt(),
      lastPrintedAt: fields[5] as DateTime,
      imageUrl: fields[6] as String?,
      defaultTemplateId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, VariantPrintStatsHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.variantSku)
      ..writeByte(1)
      ..write(obj.productId)
      ..writeByte(2)
      ..write(obj.productName)
      ..writeByte(3)
      ..write(obj.variantName)
      ..writeByte(4)
      ..write(obj.totalPrints)
      ..writeByte(5)
      ..write(obj.lastPrintedAt)
      ..writeByte(6)
      ..write(obj.imageUrl)
      ..writeByte(7)
      ..write(obj.defaultTemplateId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VariantPrintStatsHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalibrationRuleHiveModelAdapter
    extends TypeAdapter<CalibrationRuleHiveModel> {
  @override
  final typeId = 11;

  @override
  CalibrationRuleHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalibrationRuleHiveModel(
      target: fields[0] as CalibrationTargetHiveModel,
      transformation: fields[1] as PrintStickerTransformHiveModel,
    );
  }

  @override
  void write(BinaryWriter writer, CalibrationRuleHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.target)
      ..writeByte(1)
      ..write(obj.transformation);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibrationRuleHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CalibrationTargetHiveModelAdapter
    extends TypeAdapter<CalibrationTargetHiveModel> {
  @override
  final typeId = 12;

  @override
  CalibrationTargetHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CalibrationTargetHiveModel(
      type: fields[0] as String,
      index: (fields[1] as num?)?.toInt(),
      edgeGroup: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CalibrationTargetHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.index)
      ..writeByte(2)
      ..write(obj.edgeGroup);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibrationTargetHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OptimizationPreferencesHiveModelAdapter
    extends TypeAdapter<OptimizationPreferencesHiveModel> {
  @override
  final typeId = 13;

  @override
  OptimizationPreferencesHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OptimizationPreferencesHiveModel(
      allowScaling: fields[0] as bool,
      allowTranslation: fields[1] as bool,
      allowStickerSpecificAdjustment: fields[3] as bool,
      minimumAcceptableScale: fields[4] == null
          ? 0.7
          : (fields[4] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, OptimizationPreferencesHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.allowScaling)
      ..writeByte(1)
      ..write(obj.allowTranslation)
      ..writeByte(3)
      ..write(obj.allowStickerSpecificAdjustment)
      ..writeByte(4)
      ..write(obj.minimumAcceptableScale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OptimizationPreferencesHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaperConfigurationReferenceHiveModelAdapter
    extends TypeAdapter<PaperConfigurationReferenceHiveModel> {
  @override
  final typeId = 14;

  @override
  PaperConfigurationReferenceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaperConfigurationReferenceHiveModel(
      id: fields[0] as String,
      displayName: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PaperConfigurationReferenceHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaperConfigurationReferenceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrintStickerTransformHiveModelAdapter
    extends TypeAdapter<PrintStickerTransformHiveModel> {
  @override
  final typeId = 15;

  @override
  PrintStickerTransformHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrintStickerTransformHiveModel(
      offsetX: (fields[0] as num).toDouble(),
      offsetY: (fields[1] as num).toDouble(),
      scaleX: (fields[2] as num).toDouble(),
      scaleY: (fields[3] as num).toDouble(),
      anchorX: (fields[4] as num).toDouble(),
      anchorY: (fields[5] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, PrintStickerTransformHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.offsetX)
      ..writeByte(1)
      ..write(obj.offsetY)
      ..writeByte(2)
      ..write(obj.scaleX)
      ..writeByte(3)
      ..write(obj.scaleY)
      ..writeByte(4)
      ..write(obj.anchorX)
      ..writeByte(5)
      ..write(obj.anchorY);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrintStickerTransformHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrinterCalibrationHiveModelAdapter
    extends TypeAdapter<PrinterCalibrationHiveModel> {
  @override
  final typeId = 16;

  @override
  PrinterCalibrationHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterCalibrationHiveModel(
      enabled: fields[0] as bool,
      calibrationRules: (fields[1] as List).cast<CalibrationRuleHiveModel>(),
      lastCalibratedAt: fields[2] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterCalibrationHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.enabled)
      ..writeByte(1)
      ..write(obj.calibrationRules)
      ..writeByte(2)
      ..write(obj.lastCalibratedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterCalibrationHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrinterCapabilitiesHiveModelAdapter
    extends TypeAdapter<PrinterCapabilitiesHiveModel> {
  @override
  final typeId = 17;

  @override
  PrinterCapabilitiesHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterCapabilitiesHiveModel(
      supportsCustomPaperSize: fields[0] as bool,
      supportsPortraitCustomPaper: fields[1] as bool,
      supportsLandscapeCustomPaper: fields[2] as bool,
      supportsManualFeed: fields[3] as bool,
      supportsBorderlessPrinting: fields[4] as bool,
      supportsTraySelection: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterCapabilitiesHiveModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.supportsCustomPaperSize)
      ..writeByte(1)
      ..write(obj.supportsPortraitCustomPaper)
      ..writeByte(2)
      ..write(obj.supportsLandscapeCustomPaper)
      ..writeByte(3)
      ..write(obj.supportsManualFeed)
      ..writeByte(4)
      ..write(obj.supportsBorderlessPrinting)
      ..writeByte(5)
      ..write(obj.supportsTraySelection);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterCapabilitiesHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrinterIdentityHiveModelAdapter
    extends TypeAdapter<PrinterIdentityHiveModel> {
  @override
  final typeId = 18;

  @override
  PrinterIdentityHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterIdentityHiveModel(
      systemPrinterName: fields[0] as String,
      manufacturer: fields[1] as String,
      model: fields[2] as String,
      driverName: fields[3] as String,
      driverVersion: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterIdentityHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.systemPrinterName)
      ..writeByte(1)
      ..write(obj.manufacturer)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.driverName)
      ..writeByte(4)
      ..write(obj.driverVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterIdentityHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrinterProfileHiveModelAdapter
    extends TypeAdapter<PrinterProfileHiveModel> {
  @override
  final typeId = 19;

  @override
  PrinterProfileHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterProfileHiveModel(
      id: fields[0] as String,
      displayName: fields[1] as String,
      status: fields[2] as String,
      printerIdentity: fields[3] as PrinterIdentityHiveModel,
      capabilities: fields[4] as PrinterCapabilitiesHiveModel,
      optimizationPreferences: fields[5] as OptimizationPreferencesHiveModel,
      trays: (fields[6] as List).cast<PrinterTrayProfileHiveModel>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      lastValidatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterProfileHiveModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.printerIdentity)
      ..writeByte(4)
      ..write(obj.capabilities)
      ..writeByte(5)
      ..write(obj.optimizationPreferences)
      ..writeByte(6)
      ..write(obj.trays)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.lastValidatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterProfileHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PrinterTrayProfileHiveModelAdapter
    extends TypeAdapter<PrinterTrayProfileHiveModel> {
  @override
  final typeId = 20;

  @override
  PrinterTrayProfileHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterTrayProfileHiveModel(
      trayIdentifier: fields[0] as String,
      displayName: fields[1] as String,
      supportedPaperConfigurations: (fields[2] as List)
          .cast<PaperConfigurationReferenceHiveModel>(),
      calibration: fields[3] as PrinterCalibrationHiveModel,
      nonPrintableMarginLeft: fields[4] == null
          ? 0.0
          : (fields[4] as num).toDouble(),
      nonPrintableMarginRight: fields[5] == null
          ? 0.0
          : (fields[5] as num).toDouble(),
      nonPrintableMarginTop: fields[6] == null
          ? 0.0
          : (fields[6] as num).toDouble(),
      nonPrintableMarginBottom: fields[7] == null
          ? 0.0
          : (fields[7] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, PrinterTrayProfileHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.trayIdentifier)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.supportedPaperConfigurations)
      ..writeByte(3)
      ..write(obj.calibration)
      ..writeByte(4)
      ..write(obj.nonPrintableMarginLeft)
      ..writeByte(5)
      ..write(obj.nonPrintableMarginRight)
      ..writeByte(6)
      ..write(obj.nonPrintableMarginTop)
      ..writeByte(7)
      ..write(obj.nonPrintableMarginBottom);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterTrayProfileHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
