// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crewmember.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CrewMemberAdapter extends TypeAdapter<CrewMember> {
  @override
  final int typeId = 1;

  @override
  CrewMember read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CrewMember(
      name: fields[0] as String,
      flightWeight: fields[1] as int,
      position: fields[2] as int,
      personalTools: (fields[3] as List?)?.cast<Gear>(),
      id: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CrewMember obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.flightWeight)
      ..writeByte(2)
      ..write(obj.position)
      ..writeByte(3)
      ..write(obj.personalTools)
      ..writeByte(4)
      ..write(obj.id);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrewMemberAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
