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
    );
  }

  @override
  void write(BinaryWriter writer, Gear obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.weight);
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