// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'load_accoutrements.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LoadAccoutrementAdapter extends TypeAdapter<LoadAccoutrement> {
  @override
  final int typeId = 9;

  @override
  LoadAccoutrement read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LoadAccoutrement(
      name: fields[0] as String,
      weight: fields[1] as int,
      quantity: fields[2] as int,
    );
  }

  @override
  void write(BinaryWriter writer, LoadAccoutrement obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.weight)
      ..writeByte(2)
      ..write(obj.quantity);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LoadAccoutrementAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
