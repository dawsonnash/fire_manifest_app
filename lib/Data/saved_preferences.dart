import 'crewmember.dart';
import 'gear.dart';

class SavedPreferences {
  List<TripPreference> tripPreferences = [];

  void addTripPreference(TripPreference newTripPreference) {
    // var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.add(newTripPreference); // add crewmember in memory as well
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



  void testDataTripPreference(){

    TripPreference newPreference1 = TripPreference(tripPreferenceName: 'Going to a Fire');
    TripPreference newPreference2 = TripPreference(tripPreferenceName: 'Leaving a Fire');

    savedPreferences.addTripPreference(newPreference1);
    savedPreferences.addTripPreference(newPreference2);

  }

  // Fake Test data! bruh
  // void testDataLoadPreference(TripPreference tripPreference){
  //
  //   // Populating Postiional Preferences
  //   PositionalPreference newPreference1 = PositionalPreference(priority: 1, loadPreference: 1 );
  //   CrewMember crewMember1 = CrewMember(name: "John Cena", flightWeight: 330, position: 0);
  //   newPreference1.crewMembers.add(crewMember1);
  //   addPostionalPreference(tripPreference, newPreference1);
  //
  //   // Create the GearPreference with priority and loadPreference values
  //   GearPreference newGearPreference = GearPreference(priority: 2, loadPreference: 0);
  //   //Gear gearItem1 = Gear(name: "Boxing Gloves", weight: 15);
  //   Gear gearItem2 = Gear(name: "C-4", weight: 60);
  //
  //   // Add Gear items to the GearPreference's gear list
  //   //newGearPreference.gear.add(gearItem1);
  //   newGearPreference.gear.add(gearItem2);
  //
  //   // Update isMultipleItems based on the number of items in the gear list
  //   //newGearPreference.isMultipleItems = newGearPreference.gear.length > 1 ? 1 : null;
  //
  //   // Now add the GearPreference to tripPreference, assuming this is your desired action
  //   addGearPreference(tripPreference, newGearPreference);
  //
  // }
}

class TripPreference {

  String tripPreferenceName;                               // Ex. 'Going to a Fire'
  List<CrewMember> loadoutCrewMembers = [];				  // This makes sure users cannot use the same person more than once in there preferences
  List<Gear> loadoutGear = [];							        // This makes sure users cannot use the same item more than once in there preferences
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
  List<CrewMember> crewMembers = [];						// Can be 1 or more CrewMembers
  int loadPreference;										        // First, Last, Balanced => 0, 1, 2
  // bool isActive;											        // Enables/Disables preference

  PositionalPreference({required this.priority, required this.loadPreference, required this.crewMembers});

  // If  there is only 1 crewmember, 'Balanced' load option is disabled
  // implement in ui?

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

  GearPreference({required this.priority, required this.loadPreference}){
    {
      isMultipleItems = gear.length > 1 ? 1 : null; // This will be used in algorithm instead of quantity
    }
  }

  // If  there are more than 1 items, quantity is disabled in UI.
  // If quantity is 1, then 'Balanced' load option is turned off in UI.
}


// Global SavedPreferences object
final SavedPreferences savedPreferences = SavedPreferences();



