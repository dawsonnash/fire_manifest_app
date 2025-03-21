import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/Data/trip_preferences.dart';

import '../CodeShare/variables.dart';
import 'crewmember.dart';
import 'gear.dart';
import 'package:hive/hive.dart';

class Crew {
  List<CrewMember> crewMembers = [];        // Contains all crew members
  List<Gear> gear = [];                     // Contains all gear
  List<Gear> personalTools = [];            // List of personal tool templates
  double totalCrewWeight = 0.0;

  // Explicit constructor
  Crew({
    this.crewMembers = const [],
    this.gear = const [],
    this.personalTools = const [],
    this.totalCrewWeight = 0.0,
  });

  // Convert Crew object to JSON
  Map<String, dynamic> toJson() {
    return {
      "crewMembers": crewMembers.map((member) => member.toJson()).toList(),
      "gear": gear.map((g) => g.toJson()).toList(),
      "personalTools": personalTools.map((p) => p.toJson()).toList(),
      "totalCrewWeight": totalCrewWeight ?? 0.0,
    };
  }

  // Convert JSON back into Crew object
  factory Crew.fromJson(Map<String, dynamic> json) {
    Crew crew = Crew();
    crew.crewMembers = (json["crewMembers"] as List)
        .map((member) => CrewMember.fromJson(member))
        .toList();
    crew.gear = (json["gear"] as List)
        .map((g) => Gear.fromJson(g))
        .toList();
    crew.personalTools = (json["personalTools"] as List)
        .map((p) => Gear.fromJson(p))
        .toList();
    crew.totalCrewWeight = json["totalCrewWeight"] ?? 0.0;

    if (json.containsKey("crewName")) {
      AppData.crewName = json["crewName"];
    }
    return crew;
  }

  void printPersonalTools() {
    if (personalTools.isEmpty) {
      print('No personal tools found.');
      return;
    }

    print('Personal Tools List:');
    for (var tool in personalTools) {
      print('- ${tool.name}, Weight: ${tool.weight}, Quantity: ${tool.quantity}');
    }
  }


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

  void addCrewMember(CrewMember member) {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    crewMembers.add(member); // Add CrewMember to in-memory list
    crewmemberBox.add(member); // Save to Hive storage

    // Check if the CrewMember is in a Saw Team
    if (member.position >= 9 && member.position <= 14) { // Positions 9-14 are Saw Teams
      int sawTeamNumber = member.position - 8; // Convert position index to team number (Saw Team 1-6)

      var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
      for (var tripPreference in tripPreferenceBox.values) {
        for (var posPref in tripPreference.positionalPreferences) {
          for (var entry in posPref.crewMembersDynamic) {
            if (entry is List<CrewMember>) {
              // Check if this Saw Team exists in Positional Preference
              if (entry.every((crew) => crew.position == member.position)) {
                // Add the new CrewMember to the existing Saw Team
                entry.add(member);
                tripPreference.save(); // Save the updated TripPreference to Hive
                break; // Exit loop once added
              }
            }
          }
        }
      }
    }

    updateTotalCrewWeight();
  }


  void addPersonalTool(Gear tool) {
    final personalToolsBox = Hive.box<Gear>('personalToolsBox');
    personalTools.add(tool);
    personalToolsBox.add(tool);
  }

  void removePersonalTool(String toolName) {
    var personalToolsBox = Hive.box<Gear>('personalToolsBox');

    // Find the tool in Hive based on its name
    final keyToRemove = personalToolsBox.keys.firstWhere(
          (key) {
        final gear = personalToolsBox.get(key);
        return gear != null && gear.name == toolName;
      },
      orElse: () => null, // Return null if no matching tool is found
    );

    if (keyToRemove != null) {
      personalToolsBox.delete(keyToRemove); // Remove from Hive
    }

    // Remove the tool from the in-memory list
    personalTools.removeWhere((tool) => tool.name == toolName);
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

    // Update trip preference
    removeCrewMemberFromPreferences(member);

    // Update total crew weight
    updateTotalCrewWeight();
  }

  void removeCrewMemberFromPreferences(CrewMember member) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');

    List<TripPreference> tripPreferencesToRemove = [];

    for (var tripPreference in tripPreferenceBox.values) {
      bool preferenceUpdated = false;

      // Filter `positionalPreferences`
      tripPreference.positionalPreferences.removeWhere((positionalPreference) {
        List<dynamic> updatedCrewMembersDynamic = [];

        for (var entry in positionalPreference.crewMembersDynamic) {
          if (entry is CrewMember) {
            // If the entry is an individual CrewMember, exclude it if it matches
            if (entry.name != member.name) {
              updatedCrewMembersDynamic.add(entry);
            }
          } else if (entry is List<CrewMember>) {
            // If the entry is a Saw Team (List<CrewMember>), remove the CrewMember if present
            entry.removeWhere((teamMember) => teamMember.name == member.name);

            // Only keep the list if it still has members
            if (entry.isNotEmpty) {
              updatedCrewMembersDynamic.add(entry);
            }
          }
        }

        // Update crewMembersDynamic and check if it’s now empty
        positionalPreference.crewMembersDynamic = updatedCrewMembersDynamic;
        preferenceUpdated = true;

        return updatedCrewMembersDynamic.isEmpty; // Remove preference if empty
      });

      // Remove the trip preference if no positional or gear preferences remain
      if (tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty) {
        tripPreferencesToRemove.add(tripPreference);
      } else if (preferenceUpdated) {
        tripPreference.save(); // Save the updated trip preference
      }
    }

    // Remove empty trip preferences from Hive
    for (var tripPref in tripPreferencesToRemove) {
      savedPreferences.removeTripPreference(tripPref);
    }
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
        savedPreferences.removeTripPreference(tripPreference);
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
      // First, remove the specific gear item from each gear preference
      for (var gearPreference in tripPreference.gearPreferences) {
        gearPreference.gear.removeWhere((g) => g.name == gearItem.name);
      }

      // Then, remove any gear preference that is now empty
      tripPreference.gearPreferences.removeWhere((gearPreference) => gearPreference.gear.isEmpty);

      // Check if the entire trip preference is empty after removing gear preferences
      if (tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty) {
        savedPreferences.removeTripPreference(tripPreference);
        tripPreferenceBox.delete(tripPreference); // Ensure it's removed from Hive
      } else {
        tripPreference.save(); // Save the updated trip preference
      }
    }

    // Update the total crew weight
    updateTotalCrewWeight();
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
        savedPreferences.removeTripPreference(tripPreference);
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
  Future<void> loadCrewDataFromHive() async {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    var gearBox = Hive.box<Gear>('gearBox');
    var personalToolsBox = Hive.box<Gear>('personalToolsBox');

    // Wait for Hive to load values
    crew.crewMembers = crewmemberBox.values.toList();
    crew.gear = gearBox.values.toList();
    crew.personalTools = personalToolsBox.values.toList();

    // Update total weight
    crew.updateTotalCrewWeight();
  }

  void loadPersonalTools() {
    var personalToolsBox = Hive.box<Gear>('personalTools');
    personalTools = personalToolsBox.values.toList();
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
    Gear(name: 'Chainsaw', weight: 25, quantity: 1, isPersonalTool: true, isHazmat: true),
    Gear(name: 'P-tool', weight: 8, quantity: 1, isPersonalTool: true, isHazmat: false),
  ];

  List<Gear> swamper = [
    Gear(name: 'Dolmar', weight: 15, quantity: 1, isPersonalTool: true, isHazmat: true),
  ];

  List<Gear> dig = [
    Gear(name: 'P-tool', weight: 8, quantity: 1, isPersonalTool: true, isHazmat: false),
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
    Gear(name: 'Ammo Can', weight: 20, quantity: 1, isHazmat: true),
    Gear(name: 'Camp Bag', weight: 75, quantity: 1, isHazmat: false),
    Gear(name: 'Saw Bag', weight: 80, quantity: 1, isHazmat: false),
    Gear(name: 'Commo Case', weight: 20, quantity: 1, isHazmat: false),
    Gear(name: 'Bauman Bag', weight: 15, quantity: 1, isHazmat: false),
    Gear(name: 'Trauma/AED/SKED', weight: 45, quantity: 1, isHazmat: false),
    Gear(name: 'Trauma Bag', weight: 40, quantity: 1, isHazmat: false),
    Gear(name: 'P-tool/Shovel/Rhino', weight: 25, quantity: 1, isHazmat: false),
    Gear(name: 'SAT Phone', weight: 5, quantity: 2, isHazmat: false),
    Gear(name: 'Shotgun', weight: 33, quantity: 1, isHazmat: false),
    Gear(name: 'QB', weight: 45, quantity: 6, isHazmat: false),
    Gear(name: 'MRE', weight: 25, quantity: 6, isHazmat: false),

  ];

  for (var gearItem in testGear) {
    gearBox.add(gearItem); // Add to Hive
    crew.gear.add(gearItem); // Add to in-memory list
  }

  // Update the total crew weight
  crew.updateTotalCrewWeight();
}

