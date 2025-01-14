// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gear.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GearAdapter extends TypeAdapter<Gear> {
  @override
  final int typeId = 0;

  @override
  Gear read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Gear(
      name: fields[0] as String,
      weight: fields[1] as int,
      quantity: fields[2] as int,
      isPersonalTool: fields[3] as bool,
      id: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Gear obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.isPersonalTool)
      ..writeByte(4)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
