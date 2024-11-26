// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'positional_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PositionalPreferenceAdapter extends TypeAdapter<PositionalPreference> {
  @override
  final int typeId = 5;

  @override
  PositionalPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PositionalPreference(
      priority: fields[0] as int,
      loadPreference: fields[1] as int,
      crewMembersDynamic: (fields[2] as List).cast<dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, PositionalPreference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.priority)
      ..writeByte(1)
      ..write(obj.loadPreference)
      ..writeByte(2)
      ..write(obj.crewMembersDynamic);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PositionalPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
