// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ProductHiveModelAdapter extends TypeAdapter<ProductHiveModel> {
  @override
  final typeId = 0;

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
      totalPrints: (fields[3] as num).toInt(),
      lastPrintedAt: fields[4] as DateTime,
      category: fields[7] as String?,
      shelfLifeDays: (fields[8] as num?)?.toInt(),
      storageConditions: fields[9] as String?,
      imageUrl: fields[10] as String?,
      ingredients: fields[11] == null
          ? const []
          : (fields[11] as List).cast<IngredientHiveModel>(),
      nutritionFacts: fields[12] as NutritionFactsHiveModel?,
      variants: fields[13] == null
          ? const []
          : (fields[13] as List).cast<ProductVariantHiveModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ProductHiveModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sku)
      ..writeByte(3)
      ..write(obj.totalPrints)
      ..writeByte(4)
      ..write(obj.lastPrintedAt)
      ..writeByte(7)
      ..write(obj.category)
      ..writeByte(8)
      ..write(obj.shelfLifeDays)
      ..writeByte(9)
      ..write(obj.storageConditions)
      ..writeByte(10)
      ..write(obj.imageUrl)
      ..writeByte(11)
      ..write(obj.ingredients)
      ..writeByte(12)
      ..write(obj.nutritionFacts)
      ..writeByte(13)
      ..write(obj.variants);
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

class NutritionFactsHiveModelAdapter
    extends TypeAdapter<NutritionFactsHiveModel> {
  @override
  final typeId = 2;

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

class ProductVariantHiveModelAdapter
    extends TypeAdapter<ProductVariantHiveModel> {
  @override
  final typeId = 3;

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
    );
  }

  @override
  void write(BinaryWriter writer, ProductVariantHiveModel obj) {
    writer
      ..writeByte(6)
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
      ..write(obj.sku);
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
