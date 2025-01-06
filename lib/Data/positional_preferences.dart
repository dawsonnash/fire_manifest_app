import 'package:hive/hive.dart';
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


}