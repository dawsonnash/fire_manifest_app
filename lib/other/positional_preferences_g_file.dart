// // GENERATED CODE - DO NOT MODIFY BY HAND
//
// part of 'positional_preferences.dart';
//
// // **************************************************************************
// // TypeAdapterGenerator
// // **************************************************************************
// class PositionalPreferenceAdapter extends TypeAdapter<PositionalPreference> {
//   @override
//   final int typeId = 5;
//
//   @override
//   PositionalPreference read(BinaryReader reader) {
//     final numOfFields = reader.readByte();
//     final fields = <int, dynamic>{
//       for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
//     };
//
//     // Deserialize the dynamic list
//     final rawList = fields[2] as List;
//     final crewMembersDynamic = rawList.map((item) {
//       if (item is HiveList) {
//         return item.cast<CrewMember>();
//       } else if (item is CrewMember) {
//         return item;
//       } else {
//         return item; // Fallback for other types
//       }
//     }).toList();
//
//     return PositionalPreference(
//       priority: fields[0] as int,
//       loadPreference: fields[1] as int,
//       crewMembersDynamic: crewMembersDynamic,
//     );
//   }
//
//   @override
//   void write(BinaryWriter writer, PositionalPreference obj) {
//     final crewMemberBox = Hive.box<CrewMember>('crewmemberBox'); // Get the CrewMember box
//
//     writer
//       ..writeByte(3)
//       ..writeByte(0)
//       ..write(obj.priority)
//       ..writeByte(1)
//       ..write(obj.loadPreference)
//       ..writeByte(2);
//
//     // Serialize the dynamic list
//     final serializedList = obj.crewMembersDynamic.map((item) {
//       if (item is List<CrewMember>) {
//         return HiveList(crewMemberBox, objects: item); // Use the CrewMember box
//       } else if (item is CrewMember) {
//         return item; // Store individual CrewMembers
//       }
//       return item; // Fallback for other types
//     }).toList();
//
//     writer.write(serializedList);
//   }
//
//
//   @override
//   int get hashCode => typeId.hashCode;
//
//   @override
//   bool operator ==(Object other) =>
//       identical(this, other) ||
//           other is PositionalPreferenceAdapter &&
//               runtimeType == other.runtimeType &&
//               typeId == other.typeId;
// }
