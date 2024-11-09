import 'crewmember.dart';
import 'gear.dart';

class SavedPreferences {
  List<TripPreference> tripPreferences = [];

  void addTripPreference(TripPreference newTripPreference) {
    // var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.add(newTripPreference); // add crewmember in memory as well
    //preferenceLoadoutBox.add(newPreferenceLoadout); // save to hive memory
  }

  void deleteTripPreference(TripPreference tripPreference) {
    // var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.remove(tripPreference); // add crewmember in memory as well
    //preferenceLoadoutBox.add(newPreferenceLoadout); // save to hive memory
  }

  void deleteAllTripPreferences() {
    // var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    // Clear the in-memory list
    savedPreferences.tripPreferences.clear();
    // Clear the Hive storage
    //crewmemberBox.clear();
  }

  void addPostionalPreference(TripPreference tripPreference, PositionalPreference newPreference) {
    // var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreference.positionalPreferences.add(newPreference); // add crewmember in memory as well
    //preferenceLoadoutBox.add(newPreferenceLoadout); // save to hive memory
  }

  void addGearPreference(TripPreference tripPreference, GearPreference newPreference) {
    // var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreference.gearPreferences.add(newPreference); // add crewmember in memory as well
    //preferenceLoadoutBox.add(newPreferenceLoadout); // save to hive memory
  }
}

class TripPreference {

  String tripPreferenceName;                               // Ex. 'Going to a Fire'
  List<PositionalPreference> positionalPreferences = [];
  List<GearPreference> gearPreferences = [];

  //PriorityMap
  // of whatevertype. Maps preferences to a priority number across positional & gear
  // Maybe multi-object array
  // UI will check to see if priority is taken.

  TripPreference({required this.tripPreferenceName});

}

class PositionalPreference {
  // Priority will be dealt with on UI side through drag and drop
  int priority;											            // Sorting Priority
  int loadPreference;										        // First, Last, Balanced => 0, 1, 2
  List<dynamic> crewMembersDynamic = [];						    // Can hold either individual crew member(s), or entire groups of crew members (like saw teams)

  PositionalPreference({required this.priority, required this.loadPreference, required this.crewMembersDynamic});


}

Map<int, String> loadPreferenceMap = {
  0: 'First',
  1: 'Last',
  2: 'Balanced',
};

class GearPreference{

  int priority;											            // Sorting Priority
  List<Gear> gear = [];									        // Can be 1 or more Gear Items
  int? quantity;											          // Based on crew inventory. Only really need for like water or MREs
  int? isMultipleItems;
  int loadPreference;										        // First, Last, Balanced => 0, 1, 2
  // bool isActive;											        // Enables/Disables preference

  GearPreference({required this.priority, required this.loadPreference, required this.gear}){
    {
      isMultipleItems = gear.length > 1 ? 1 : null; // This will be used in algorithm instead of quantity
    }
  }

  // If  there are more than 1 items, quantity is disabled in UI.
  // If quantity is 1, then 'Balanced' load option is turned off in UI.
}


// Global SavedPreferences object
final SavedPreferences savedPreferences = SavedPreferences();



