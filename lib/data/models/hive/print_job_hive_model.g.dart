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
      sku: fields[2] as String,
      status: fields[3] as String,
      printerStation: fields[4] as String,
      printedAt: fields[5] as DateTime,
      labelCount: (fields[6] as num).toInt(),
      isVerified: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, PrintJobHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.sku)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.printerStation)
      ..writeByte(5)
      ..write(obj.printedAt)
      ..writeByte(6)
      ..write(obj.labelCount)
      ..writeByte(7)
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
