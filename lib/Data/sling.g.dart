// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sling.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SlingAdapter extends TypeAdapter<Sling> {
  @override
  final int typeId = 10;

  @override
  Sling read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Sling(
      slingNumber: fields[0] as int,
      weight: fields[1] as int,
      loadAccoutrements: (fields[2] as List).cast<LoadAccoutrement>(),
      loadGear: (fields[3] as List).cast<Gear>(),
      customItems: (fields[4] as List).cast<CustomItem>(),
    );
  }

  @override
  void write(BinaryWriter writer, Sling obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.slingNumber)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.loadAccoutrements)
      ..writeByte(3)
      ..write(obj.loadGear)
      ..writeByte(4)
      ..write(obj.customItems);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SlingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
