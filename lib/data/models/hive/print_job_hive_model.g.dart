// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'print_job_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrintJobHiveModelAdapter extends TypeAdapter<PrintJobHiveModel> {
  @override
  final typeId = 9;

  @override
  PrintJobHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrintJobHiveModel(
      id: fields[0] as String,
      productName: fields[1] as String,
      variantId: fields[2] as String,
      variantName: fields[3] as String,
      variantSku: fields[4] as String,
      templateId: fields[5] as String,
      templateName: fields[6] as String,
      status: fields[7] as String,
      printerStation: fields[8] as String,
      printedAt: fields[9] as DateTime,
      labelCount: (fields[10] as num).toInt(),
      isVerified: fields[11] as bool,
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
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.printerStation)
      ..writeByte(9)
      ..write(obj.printedAt)
      ..writeByte(10)
      ..write(obj.labelCount)
      ..writeByte(11)
      ..write(obj.isVerified);
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
