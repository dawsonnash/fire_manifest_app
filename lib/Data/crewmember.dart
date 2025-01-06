
import 'package:hive/hive.dart';

import 'crew.dart';
import 'gear.dart';
part 'crewmember.g.dart';


@HiveType(typeId: 1) // Needs to be a unique ID across app
class CrewMember extends HiveObject{
  @HiveField(0)// needs to be unique ID across class
  String name;
  @HiveField(1)// needs to be unique ID across class
  int flightWeight;
  @HiveField(2)
  // Had to add a potential null field in crewmember.g, else would not build
  // position: fields[2] as int? ?? 0,
  int position; // New field to store the position code

  @HiveField(3)
  List<Gear>? personalTools;


  // Getter function to calculate totalCrewMemberWeight: flightweight + all personal tools
  int get totalCrewMemberWeight {
    int totalWeight = flightWeight;
    if (personalTools != null) {
      for (var tool in personalTools!) {
        totalWeight += tool.weight.toInt(); // Ensure tool.weight is treated as int
      }
    }
    return totalWeight; // Explicitly returning an int
  }


  CrewMember({required this.name, required this.flightWeight, required this.position, this.personalTools});

  String getPositionTitle(int positionCode) {
    return positionMap[positionCode] ?? 'Unknown Position';
  }

  // Convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'flightWeight': flightWeight,
      'position': position,
      'personalTools': personalTools?.map((tool) => tool.toJson()).toList(),
    };
  }

  // Create object from JSON
  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      name: json['name'] as String,
      flightWeight: json['flightWeight'] as int,
      position: json['position'] as int,
      personalTools: (json['personalTools'] as List?)
          ?.map((tool) => Gear.fromJson(tool as Map<String, dynamic>))
          .toList(),
    );
  }

}
List<Gear> getAllGearItems() {
  List<Gear> allGear = [];
  for (var crewMember in crew.crewMembers) {
    allGear.addAll(crewMember.personalTools ?? []);
  }
  return allGear;
}

// Position Mapping
const Map<int, String> positionMap = {
  0: 'Superintendent',
  1: 'Asst. Superintendent',
  2: 'Foreman',
  3: 'Captain',
  4: 'Lead Firefighter',
  5: 'Senior Firefighter',
  6: 'Air Ops',
  7: 'Medic/EMT',
  8: 'Saw Boss',
  9: 'Saw Team 1',
  10: 'Saw Team 2',
  11: 'Saw Team 3',
  12: 'Saw Team 4',
  13: 'Saw Team 5',
  14: 'Saw Team 6',
  15: 'Lead P',
  16: 'Dig',
  17: 'Maps',
  18: 'Communications',
  19: 'Weather',
  20: 'Fuel',
  21: 'Vehicles',
  22: 'Camp/Facilities',
  23: 'Supply',
  24: 'Tool Manager',
  25: '6-man',
  26: 'Other',      // User defined
};

List<CrewMember> sortCrewListByPosition(List<CrewMember> crewList) {
  // Sort the crewList
  crewList.sort((a, b) {
    // Compare positions directly
    if (a.position != b.position) {
      return a.position.compareTo(b.position);
    }

    // If positions are the same, sort alphabetically by name
    return a.name.compareTo(b.name);
  });

  return crewList;
}
