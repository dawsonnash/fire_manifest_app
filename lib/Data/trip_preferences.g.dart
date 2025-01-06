// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_preferences.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripPreferenceAdapter extends TypeAdapter<TripPreference> {
  @override
  final int typeId = 6;

  @override
  TripPreference read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TripPreference(
      tripPreferenceName: fields[0] as String,
    )
      ..positionalPreferences = (fields[1] as List).cast<PositionalPreference>()
      ..gearPreferences = (fields[2] as List).cast<GearPreference>();
  }

  @override
  void write(BinaryWriter writer, TripPreference obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.tripPreferenceName)
      ..writeByte(1)
      ..write(obj.positionalPreferences)
      ..writeByte(2)
      ..write(obj.gearPreferences);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripPreferenceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
