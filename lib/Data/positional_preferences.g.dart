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

    // Deserialize the dynamic list
    final rawList = fields[2] as List;
    final crewMembersDynamic = rawList.map((item) {
      if (item is Map && item['type'] == 'CrewMember') {
        return CrewMember(
          name: item['value']['name'],
          flightWeight: item['value']['flightWeight'],
          position: item['value']['position'],
          personalTools: (item['value']['personalTools'] as List?)
              ?.map((tool) => Gear.fromJson(tool))
              .toList(),
        );
      } else if (item is Map && item['type'] == 'CrewMemberList') {
        return (item['value'] as List)
            .map((crewItem) => CrewMember(
          name: crewItem['name'],
          flightWeight: crewItem['flightWeight'],
          position: crewItem['position'],
          personalTools: (crewItem['personalTools'] as List?)
              ?.map((tool) => Gear.fromJson(tool))
              .toList(),
        ))
            .toList();
      }
      return item; // Fallback for other unhandled cases
    }).toList();

    return PositionalPreference(
      priority: fields[0] as int,
      loadPreference: fields[1] as int,
      crewMembersDynamic: crewMembersDynamic,
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
      ..writeByte(2);

    // Serialize the dynamic list
    final serializedList = obj.crewMembersDynamic.map((item) {
      if (item is CrewMember) {
        return {
          'type': 'CrewMember',
          'value': {
            'name': item.name,
            'flightWeight': item.flightWeight,
            'position': item.position,
            'personalTools': item.personalTools?.map((tool) => tool.toJson()).toList(),
          },
        };
      } else if (item is List<CrewMember>) {
        return {
          'type': 'CrewMemberList',
          'value': item.map((crewItem) {
            return {
              'name': crewItem.name,
              'flightWeight': crewItem.flightWeight,
              'position': crewItem.position,
              'personalTools': crewItem.personalTools?.map((tool) => tool.toJson()).toList(),
            };
          }).toList(),
        };
      }
      return {'type': 'Other', 'value': item}; // Fallback for other types
    }).toList();

    writer.write(serializedList);
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
