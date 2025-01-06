// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gear_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GearPreferenceAdapter extends TypeAdapter<GearPreference> {
  @override
  final int typeId = 4;

  @override
  GearPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GearPreference(
      priority: fields[0] as int,
      loadPreference: fields[2] as int,
      gear: (fields[1] as List).cast<Gear>(),
    );
  }

  @override
  void write(BinaryWriter writer, GearPreference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.priority)
      ..writeByte(1)
      ..write(obj.gear)
      ..writeByte(2)
      ..write(obj.loadPreference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GearPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
