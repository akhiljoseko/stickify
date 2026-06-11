// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'template_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LabelTemplateHiveModelAdapter
    extends TypeAdapter<LabelTemplateHiveModel> {
  @override
  final typeId = 4;

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
    );
  }

  @override
  void write(BinaryWriter writer, LabelTemplateHiveModel obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.elements);
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

class SheetConfigHiveModelAdapter extends TypeAdapter<SheetConfigHiveModel> {
  @override
  final typeId = 5;

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
  final typeId = 6;

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
  final typeId = 7;

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

class ElementBlueprintHiveModelAdapter
    extends TypeAdapter<ElementBlueprintHiveModel> {
  @override
  final typeId = 8;

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
    );
  }

  @override
  void write(BinaryWriter writer, ElementBlueprintHiveModel obj) {
    writer
      ..writeByte(25)
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
      ..write(obj.fit);
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
