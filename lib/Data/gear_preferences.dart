import 'package:hive/hive.dart';
import 'gear.dart';
part 'gear_preferences.g.dart';

@HiveType(typeId: 4)
class GearPreference extends HiveObject{

  @HiveField(0)
  int priority;											            // Sorting Priority

  @HiveField(1)
  List<Gear> gear = [];									        // Can be 1 or more Gear Items

  @HiveField(2)
  int loadPreference;										        // First, Last, Balanced => 0, 1, 2
  // bool isActive;											        // Enables/Disables preference

  GearPreference({required this.priority, required this.loadPreference, required this.gear});

// If  there are more than 1 items, quantity is disabled in UI.
// If quantity is 1, then 'Balanced' load option is turned off in UI.
}