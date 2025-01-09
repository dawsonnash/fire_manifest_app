// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TripAdapter extends TypeAdapter<Trip> {
  @override
  final int typeId = 3;

  @override
  Trip read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Trip(
      tripName: fields[0] as String,
      allowable: fields[1] as int,
      availableSeats: fields[2] as int,
      timestamp: fields[4] as DateTime?,
    )..loads = (fields[3] as List).cast<Load>();
  }

  @override
  void write(BinaryWriter writer, Trip obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.tripName)
      ..writeByte(1)
      ..write(obj.allowable)
      ..writeByte(2)
      ..write(obj.availableSeats)
      ..writeByte(3)
      ..write(obj.loads)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
