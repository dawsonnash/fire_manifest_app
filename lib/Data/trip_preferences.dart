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

}