// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crewMemberList.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CrewMemberListAdapter extends TypeAdapter<CrewMemberList> {
  @override
  final int typeId = 8;

  @override
  CrewMemberList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CrewMemberList(
      crewMembers: (fields[0] as List).cast<CrewMember>(),
    );
  }

  @override
  void write(BinaryWriter writer, CrewMemberList obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.crewMembers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CrewMemberListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
