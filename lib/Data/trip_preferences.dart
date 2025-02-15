import 'package:hive/hive.dart';
import 'positional_preferences.dart';
import 'gear_preferences.dart';

part 'trip_preferences.g.dart';

@HiveType(typeId: 6)
class TripPreference extends HiveObject{

  @HiveField(0)
  String tripPreferenceName;                               // Ex. 'Going to a Fire'

  @HiveField(1)
  List<PositionalPreference> positionalPreferences = [];

  @HiveField(2)
  List<GearPreference> gearPreferences = [];

  //PriorityMap
  // of whatever type. Maps preferences to a priority number across positional & gear
  // Maybe multi-object array
  // UI will check to see if priority is taken.

  TripPreference({required this.tripPreferenceName});

  Map<String, dynamic> toJson() {
    return {
      "tripPreferenceName": tripPreferenceName,
      "positionalPreferences": positionalPreferences.map((pp) => pp.toJson()).toList(),
      "gearPreferences": gearPreferences.map((gp) => gp.toJson()).toList(),
    };
  }

  factory TripPreference.fromJson(Map<String, dynamic> json) {
    return TripPreference(tripPreferenceName: json["tripPreferenceName"])
      ..positionalPreferences = (json["positionalPreferences"] as List)
          .map((pp) => PositionalPreference.fromJson(pp))
          .toList()
      ..gearPreferences = (json["gearPreferences"] as List)
          .map((gp) => GearPreference.fromJson(gp))
          .toList();
  }

}