// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoadAdapter extends TypeAdapter<Load> {
  @override
  final int typeId = 2;

  @override
  Load read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Load(
      loadNumber: fields[0] as int,
      weight: fields[1] as int,
      loadPersonnel: (fields[2] as List).cast<CrewMember>(),
      loadGear: (fields[3] as List).cast<Gear>(),
      customItems: (fields[4] as List).cast<CustomItem>(),
      slings: (fields[5] as List?)?.cast<Sling>(),
      loadAccoutrements: (fields[6] as List?)?.cast<LoadAccoutrement>(),
    );
  }

  @override
  void write(BinaryWriter writer, Load obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.loadNumber)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.loadPersonnel)
      ..writeByte(3)
      ..write(obj.loadGear)
      ..writeByte(4)
      ..write(obj.customItems)
      ..writeByte(5)
      ..write(obj.slings)
      ..writeByte(6)
      ..write(obj.loadAccoutrements);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
