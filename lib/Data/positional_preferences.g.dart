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
      if (item is HiveList) {
        return item.cast<CrewMember>(); // Convert HiveList back to List<CrewMember>
      } else if (item is CrewMember) {
        return item; // Individual CrewMember
      } else if (item is CrewMemberList) {
        return item.crewMembers; // Convert CrewMemberList to List<CrewMember>
      } else if (item is List) {
        return CrewMemberList(crewMembers: item.cast<CrewMember>()).crewMembers; // Cast plain lists correctly
      }
      return item; // Fallback for other types
    }).toList();

    return PositionalPreference(
      priority: fields[0] as int,
      loadPreference: fields[1] as int,
      crewMembersDynamic: crewMembersDynamic,
    );
  }


  @override
  void write(BinaryWriter writer, PositionalPreference obj) {
    final crewMemberBox = Hive.box<CrewMember>('crewmemberBox'); // Get the CrewMember box

    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.priority)
      ..writeByte(1)
      ..write(obj.loadPreference)
      ..writeByte(2);

    // Store lists of CrewMembers (Saw Teams) as `CrewMemberList`
    final serializedList = obj.crewMembersDynamic.map((item) {
      if (item is List<CrewMember>) {
        return CrewMemberList(crewMembers: item); // Store as CrewMemberList
      } else if (item is CrewMember) {
        return item; // Store individual CrewMembers directly
      }
      return item; // Fallback for other types
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