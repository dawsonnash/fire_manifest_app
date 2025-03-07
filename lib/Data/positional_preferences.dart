import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'crewMemberList.dart';
import 'crewmember.dart';
import 'gear.dart';

part 'positional_preferences.g.dart';

@HiveType(typeId: 5)
class PositionalPreference extends HiveObject
{
  // Priority will be dealt with on UI side through drag and drop, eventually
  @HiveField(0)
  int priority;											            // Sorting Priority

  @HiveField(1)
  int loadPreference;										        // First, Last, Balanced => 0, 1, 2

  @HiveField(2)
  List<dynamic> crewMembersDynamic;			  // Can hold either individual crew member(s), or entire groups of crew members (like saw teams)

  PositionalPreference({required this.priority, required this.loadPreference,  this.crewMembersDynamic = const []});

  Map<String, dynamic> toJson() {
    return {
      "priority": priority,
      "loadPreference": loadPreference,
      "crewMembersDynamic": crewMembersDynamic.map((cm) {
        if (cm is CrewMember) return cm.toJson();
        if (cm is List<CrewMember>) return cm.map((m) => m.toJson()).toList();
        return cm;
      }).toList(),
    };
  }

  factory PositionalPreference.fromJson(Map<String, dynamic> json) {
    return PositionalPreference(
      priority: json["priority"],
      loadPreference: json["loadPreference"],
      crewMembersDynamic: (json["crewMembersDynamic"] as List).map((cm) {
        if (cm is Map<String, dynamic>) {
          return CrewMember(
            name: cm['name'],
            flightWeight: cm['flightWeight'],
            position: cm['position'],
            personalTools: (cm['personalTools'] as List?)?.map((tool) => Gear.fromJson(tool)).toList(),
          );
        }
        if (cm is List) {
          return cm.map((m) => CrewMember(
            name: m['name'],
            flightWeight: m['flightWeight'],
            position: m['position'],
            personalTools: (m['personalTools'] as List?)?.map((tool) => Gear.fromJson(tool)).toList(),
          )).toList();
        }
        return cm;
      }).toList(),
    );
  }


}