// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'custom_position.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CustomPositionAdapter extends TypeAdapter<CustomPosition> {
  @override
  final int typeId = 11;

  @override
  CustomPosition read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomPosition(
      code: fields[0] as int,
      title: fields[1] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CustomPosition obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.code)
      ..writeByte(1)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomPositionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
