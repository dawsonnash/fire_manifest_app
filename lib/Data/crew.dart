import 'package:fire_app/Data/trip_preferences.dart';

import 'crewmember.dart';
import 'gear.dart';
import 'package:hive/hive.dart';

class Crew {
  List<CrewMember> crewMembers = [];        // Contains all crew members
  List<Gear> gear = [];
  double totalCrewWeight = 0.0;

  // Helper function to get saw teams
  List<CrewMember> getSawTeam(int teamNumber) {
    switch (teamNumber) {
      case 1: return crewMembers.where((member) => member.position == 9).toList();
      case 2: return crewMembers.where((member) => member.position == 10).toList();
      case 3: return crewMembers.where((member) => member.position == 11).toList();
      case 4: return crewMembers.where((member) => member.position == 12).toList();
      case 5: return crewMembers.where((member) => member.position == 13).toList();
      case 6: return crewMembers.where((member) => member.position == 14).toList();
      default: return [];
    }
  }
  void updateTotalCrewWeight() {

    // Get all flight weight
    double crewWeight = 0.0;
    for (var member in crewMembers) {
      crewWeight += member.flightWeight;
    }

    // Get all personal tool weight
    double personalToolWeight = 0.0;
    for (var member in crewMembers){
      if (member.personalTools != null) {
        for (var tools in member.personalTools!) {
            personalToolWeight += tools.weight;
        }
      }
    }

    // Get all gear weight
    double gearWeight = 0.0;
    for (var gearItem in gear) {
      gearWeight += gearItem.totalGearWeight;
    }

    totalCrewWeight = crewWeight + personalToolWeight + gearWeight;
  }

  addCrewMember(CrewMember member) {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox'); // assign hive box to variable we can use
    crewMembers.add(member); // add crewmember in memory as well
    crewmemberBox.add(member); // save to hive memory
    updateTotalCrewWeight();
    print('Updated Total Crew Weight: $totalCrewWeight');
  }

  void removeCrewMember(CrewMember member) {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox'); // Assume TripPreference is stored here

    // Remove the crew member from Hive
    final keyToRemove = crewmemberBox.keys.firstWhere(
          (key) => crewmemberBox.get(key) == member,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      crewmemberBox.delete(keyToRemove);
    }

    // Remove the crew member from the in-memory list
    crewMembers.remove(member);

    // Iterate through all trip preferences to update them
    for (var tripPreference in tripPreferenceBox.values) {
      // Remove entire positional preferences if the crew member exists in them
      tripPreference.positionalPreferences.removeWhere((positionalPreference) {
        // Check if the crew member exists in the dynamic list (either directly or in nested lists)
        return positionalPreference.crewMembersDynamic.any((entry) {
          if (entry is CrewMember) {
            // Direct match with a CrewMember
            return entry == member;
          } else if (entry is List<CrewMember>) {
            // Check within a nested list
            return entry.contains(member);
          }
          return false;
        });
      });

      // If no positional or gear preferences remain, delete the trip preference
      if (tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty) {
        tripPreference.delete();
      } else {
        tripPreference.save(); // Save the updated trip preference
      }
    }

    // Update total crew weight
    updateTotalCrewWeight();
    print('Updated Total Crew Weight: $totalCrewWeight');
  }

  void deleteAllCrewMembers() {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox'); // Assume TripPreference is stored here

    // Clear the in-memory list of crew members
    crewMembers.clear();

    // Clear the Hive storage for crew members
    crewmemberBox.clear();

    // Iterate through all trip preferences to remove positional preferences
    for (var tripPreference in tripPreferenceBox.values) {
      // Clear all positional preferences
      tripPreference.positionalPreferences.clear();

      // If no positional or gear preferences remain, delete the trip preference
      if (tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty) {
        tripPreference.delete();
      } else {
        tripPreference.save(); // Save the updated trip preference
      }
    }

    // Update the total crew weight
    updateTotalCrewWeight();
  }

  void removeGear(Gear gearItem) {
    var gearBox = Hive.box<Gear>('gearBox');
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox'); // Assume TripPreference is stored here

    // Remove the gear item from Hive
    final keyToRemove = gearBox.keys.firstWhere(
          (key) => gearBox.get(key)?.name == gearItem.name, // Compare by name
      orElse: () => null,
    );
    if (keyToRemove != null) {
      gearBox.delete(keyToRemove);
    }

    // Remove the gear item from the in-memory list
    gear.removeWhere((g) => g.name == gearItem.name); // Remove by name

    // Iterate through all trip preferences
    for (var tripPreference in tripPreferenceBox.values.toList()) {

      // Remove gear preferences containing gear with the same name
      tripPreference.gearPreferences.removeWhere((gearPreference) {

        // Remove the gearPreference if it contains a gear with the same name
        return gearPreference.gear.any((g) => g.name == gearItem.name);
      });

      // Check if the trip preference is empty after removing the gear preferences
      if (tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty) {
        tripPreference.delete();
      } else {
        tripPreference.save(); // Save the updated trip preference
      }
    }

    // Update the total crew weight
    updateTotalCrewWeight();
  }

  void addGear(Gear gearItem) {
    var gearBox = Hive.box<Gear>('gearBox');
    gear.add(gearItem); // added to in-memory as well
    gearBox.add(gearItem); // save to hive memory
    updateTotalCrewWeight();
    print('Updated Total Crew Weight: $totalCrewWeight');
  }

  void deleteAllGear() {
    var gearBox = Hive.box<Gear>('gearBox');
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox'); // Assume TripPreference is stored here

    // Clear the in-memory list of gear
    gear.clear();

    // Clear the Hive storage for gear
    gearBox.clear();

    // Iterate through all trip preferences to remove gear preferences
    for (var tripPreference in tripPreferenceBox.values) {
      // Clear all gear preferences
      tripPreference.gearPreferences.clear();

      // If no positional or gear preferences remain, delete the trip preference
      if (tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty) {
        tripPreference.delete();
      } else {
        tripPreference.save(); // Save the updated trip preference
      }
    }

    // Update the total crew weight
    updateTotalCrewWeight();
  }

  // For LogCat testing purposes
  void printCrewDetails() {
    // Print out crewmebmers
    for (var member in crewMembers) {
      print('Name: ${member.name}, Flight Weight: ${member.flightWeight}');
      print('Updated Total Crew Weight: $totalCrewWeight');
    }

    // Print out all gear
    for (var gearItems in gear) {
      print('Name: ${gearItems.name}, Flight Weight: ${gearItems.weight}');
    }
  }

  // This function loads all data stored in the hive for 'Crew' into the local in-memory
  // Seems to be an easier way to work with data for now.
  void loadCrewDataFromHive() {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    var gearBox = Hive.box<Gear>('gearBox');

    // Load crew members from Hive into the in-memory list
    crew.crewMembers = crewmemberBox.values.toList();

    // Load gear from Hive into the in-memory list
    crew.gear = gearBox.values.toList();

    // Update the total weight after loading the data
    crew.updateTotalCrewWeight();
    //print('Crew data loaded from Hive. Total weight: ${crew.totalCrewWeight}');
  }

}

// Testing purposes:
  void printCrewDetailsFromHive() {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    var gearBox = Hive.box<Gear>('gearBox');
    print('tests with hive boxes:');
    var crewmemberList = crewmemberBox.values.toList();
    var gearList = gearBox.values.toList();

    for (var member in crewmemberList) {
      print('Name: ${member.name}, Flight Weight: ${member.flightWeight}');
    }

    for (var gearItems in gearList) {
      print('Name: ${gearItems.name}, Flight Weight: ${gearItems.weight}');
    }
  }

// Global Crew object. This is THE main crew object that comes inherit to the app
final Crew crew = Crew();

void initializeTestData() {
  var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
  var gearBox = Hive.box<Gear>('gearBox');

  // Define common personal tools
  List<Gear> sawyer = [
    Gear(name: 'Chainsaw', weight: 25, quantity: 1, isPersonalTool: true),
    Gear(name: 'P-tool', weight: 8, quantity: 1, isPersonalTool: true),
  ];

  List<Gear> swamper = [
    Gear(name: 'Dolmar', weight: 15, quantity: 1, isPersonalTool: true),
    Gear(name: 'P-tool', weight: 8, quantity: 1, isPersonalTool: true),
  ];

  List<Gear> dig = [
    Gear(name: 'P-tool', weight: 8, quantity: 1, isPersonalTool: true),
  ];

  // Add Crew Members to Hive and in-memory
  List<CrewMember> testCrewMembers = [
    CrewMember(name: 'Quimby', flightWeight: 313, position: 0, personalTools: dig), // Superintendent
    CrewMember(name: 'McMaster', flightWeight: 268, position: 1, personalTools: dig), // Asst. Superintendent
    CrewMember(name: 'Fuller', flightWeight: 204, position: 8, personalTools: dig), // Foreman
    CrewMember(name: 'Hedgepeth', flightWeight: 255, position: 9, personalTools: sawyer), // Captain
    CrewMember(name: 'Winter', flightWeight: 242, position: 9, personalTools: swamper), // Lead Firefighter
    CrewMember(name: 'Shults', flightWeight: 243, position: 10, personalTools: sawyer), // Medic/EMT
    CrewMember(name: 'Jayne', flightWeight: 262, position: 10, personalTools: swamper), // Saw Boss
    CrewMember(name: 'Smothers', flightWeight: 231, position: 11, personalTools: sawyer), // Saw Team 1
    CrewMember(name: 'Curtis', flightWeight: 221, position: 11, personalTools: swamper), // Saw Team 2
    CrewMember(name: 'Wangberg', flightWeight: 247, position: 12, personalTools: sawyer), // Saw Team 3
    CrewMember(name: 'McRaith', flightWeight: 251, position: 12, personalTools: swamper), // Saw Team 4
    CrewMember(name: 'Roberts', flightWeight: 314, position: 15, personalTools: dig), // Lead P
    CrewMember(name: 'Semenuk', flightWeight: 234, position: 6, personalTools: dig), // Dig
    CrewMember(name: 'Monear', flightWeight: 229, position: 24, personalTools: dig), // Maps
    CrewMember(name: 'Grasso', flightWeight: 195, position: 7, personalTools: dig), // Communications
    CrewMember(name: 'Villanueva', flightWeight: 219, position: 21, personalTools: dig), // Weather
    CrewMember(name: 'Barfuss', flightWeight: 244, position: 18, personalTools: dig), // Fuel
    CrewMember(name: 'Morose', flightWeight: 212, position: 19, personalTools: dig), // Vehicles
    CrewMember(name: 'Jackson', flightWeight: 263, position: 24, personalTools: dig), // Supply
    CrewMember(name: 'Savannah', flightWeight: 233, position: 19, personalTools: dig), // Tool Manager
    CrewMember(name: 'Nash', flightWeight: 248, position: 25, personalTools: dig), // Tool Manager
    CrewMember(name: 'Meyers', flightWeight: 242, position: 2, personalTools: dig), // Tool Manager

  ];

  for (var member in testCrewMembers) {
    crewmemberBox.add(member); // Add to Hive
    crew.crewMembers.add(member); // Add to in-memory list
  }

  // Add Gear to Hive and in-memory
  List<Gear> testGear = [
    Gear(name: 'Ammo Can', weight: 20, quantity: 1),
    Gear(name: 'Camp Bag', weight: 75, quantity: 1),
    Gear(name: 'Saw Bag', weight: 80, quantity: 1),
    Gear(name: 'Commo Case', weight: 20, quantity: 1),
    Gear(name: 'Bauman Bag', weight: 15, quantity: 1),
    Gear(name: 'Trauma/AED/SKED', weight: 45, quantity: 1),
    Gear(name: 'Trauma Bag', weight: 40, quantity: 1),
    Gear(name: 'P-tool/Shovel/Rhino', weight: 25, quantity: 1),
    Gear(name: 'SAT Phone', weight: 5, quantity: 2),
    Gear(name: 'Shotgun', weight: 33, quantity: 1),
    Gear(name: 'QB', weight: 45, quantity: 6),
    Gear(name: 'MRE', weight: 25, quantity: 6),

  ];

  for (var gearItem in testGear) {
    gearBox.add(gearItem); // Add to Hive
    crew.gear.add(gearItem); // Add to in-memory list
  }

  // Update the total crew weight
  crew.updateTotalCrewWeight();
}

