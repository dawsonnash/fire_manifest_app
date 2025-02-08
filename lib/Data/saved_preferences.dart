import 'package:fire_app/Data/trip.dart';

import 'crewmember.dart';
import 'gear.dart';
import 'trip_preferences.dart';
import 'gear_preferences.dart';
import 'positional_preferences.dart';
import 'package:hive/hive.dart';

class SavedPreferences {
  List<TripPreference> tripPreferences = []; // In-memory list for TripPreferences

  // Add a new TripPreference
  void addTripPreference(TripPreference newTripPreference) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.add(newTripPreference); // Add to in-memory list
    tripPreferenceBox.add(newTripPreference); // Save to Hive
  }

  // Remove a specific TripPreference
  void removeTripPreference(TripPreference tripPreference) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    final keyToRemove = tripPreferenceBox.keys.firstWhere(
      (key) => tripPreferenceBox.get(key) == tripPreference,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      tripPreferenceBox.delete(keyToRemove); // Remove from Hive
    }
    tripPreferences.remove(tripPreference); // Remove from in-memory list
  }
  void removePositionalPreference(TripPreference tripPreference, PositionalPreference positionalPreferenceToRemove) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');

    // Find the key of the TripPreference
    final key = tripPreferenceBox.keys.firstWhere(
          (k) => tripPreferenceBox.get(k) == tripPreference,
      orElse: () => null,
    );

    if (key != null) {
      // Get the existing TripPreference from Hive
      TripPreference existingTripPreference = tripPreferenceBox.get(key)!;

      // Remove the specific PositionalPreference
      existingTripPreference.positionalPreferences.removeWhere((posPref) =>
      posPref == positionalPreferenceToRemove);

      // Save the updated TripPreference back to Hive
      tripPreferenceBox.put(key, existingTripPreference);
    }

    // Update in-memory storage if needed
    tripPreference.positionalPreferences.removeWhere((posPref) =>
    posPref == positionalPreferenceToRemove);
  }
  void removeGearPreference(TripPreference tripPreference, GearPreference gearPreferenceToRemove) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');

    // Find the key of the TripPreference
    final key = tripPreferenceBox.keys.firstWhere(
          (k) => tripPreferenceBox.get(k) == tripPreference,
      orElse: () => null,
    );

    if (key != null) {
      // Get the existing TripPreference from Hive
      TripPreference existingTripPreference = tripPreferenceBox.get(key)!;

      // Remove the specific PositionalPreference
      existingTripPreference.gearPreferences.removeWhere((gearPref) =>
      gearPref == gearPreferenceToRemove);

      // Save the updated TripPreference back to Hive
      tripPreferenceBox.put(key, existingTripPreference);
    }

    // Update in-memory storage if needed
    tripPreference.gearPreferences.removeWhere((gearPref) =>
    gearPref == gearPreferenceToRemove);
  }

  // Delete all TripPreferences
  void deleteAllTripPreferences() {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.clear(); // Clear in-memory list
    tripPreferenceBox.clear(); // Clear Hive storage
  }

  // Add a PositionalPreference to a specific TripPreference
  void addPositionalPreference(TripPreference tripPreference, PositionalPreference newPreference) {
    tripPreference.positionalPreferences.add(newPreference); // Update in-memory
    _updateTripPreferenceInHive(tripPreference);
  }

  // Add a GearPreference to a specific TripPreference
  void addGearPreference(TripPreference tripPreference, GearPreference newPreference) {
    tripPreference.gearPreferences.add(newPreference); // Update in-memory
    _updateTripPreferenceInHive(tripPreference);
  }

  bool updateGearInPreferences(String oldGearName, String newGearQuantity, Gear updatedGear) {
    bool quantityIssueFound = false;

    // Loop through all saved TripPreferences
    for (TripPreference tripPref in savedPreferences.tripPreferences) {
      for (GearPreference gearPref in tripPref.gearPreferences) {
        for (Gear gear in gearPref.gear) {
          // Find gear using old name
          if (gear.name.trim().toLowerCase() == oldGearName.trim().toLowerCase()) {
            // Check if the new quantity is less than any existing preference quantity
            if (int.parse(newGearQuantity) < gear.quantity) {
              quantityIssueFound = true;
            }

            // Update all attributes except quantity
            gear.name = updatedGear.name.trim();  // Update to new name
            gear.weight = updatedGear.weight;
            gear.isHazmat = updatedGear.isHazmat;
          }
        }
      }
    }

    return quantityIssueFound; // Return true if quantity issue was found
  }

  // Helper function to update a TripPreference in Hive
  void _updateTripPreferenceInHive(TripPreference tripPreference) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    final keyToUpdate = tripPreferenceBox.keys.firstWhere(
      (key) => tripPreferenceBox.get(key) == tripPreference,
      orElse: () => null,
    );
    if (keyToUpdate != null) {
      tripPreferenceBox.put(keyToUpdate, tripPreference); // Update in Hive
    }
  }

  // Load all preferences from Hive to in-memory lists
  Future<void> loadPreferencesFromHive() async {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    savedPreferences.tripPreferences = tripPreferenceBox.values.toList(); // Load into memory
  }

  void printTripPreferencesFromHive() {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    var tripPreferenceList = tripPreferenceBox.values.toList();

    for (var trip in tripPreferenceList) {
      print('Trip Preference Name: ${trip.tripPreferenceName}');

      // Print Positional Preferences
      for (var posPref in trip.positionalPreferences) {
        print('  Positional Preference: Priority ${posPref.priority}');
        print('    Load Preference: ${loadPreferenceMap[posPref.loadPreference]}');
        for (var member in posPref.crewMembersDynamic) {
          if (member is CrewMember) {
            print('    Individual Crew Member: ${member.name}');
          } else if (member is List<CrewMember>) {
            print('    Crew Member List:');
            for (var crew in member) {
              print('      - ${crew.name}');
            }
          }
        }
      }

      // Print Gear Preferences
      for (var gearPref in trip.gearPreferences) {
        print('  Gear Preference: Priority ${gearPref.priority}');
        print('    Load Preference: ${loadPreferenceMap[gearPref.loadPreference]}');
        for (var gear in gearPref.gear) {
          print('    Gear Item: ${gear.name} (Quantity: ${gear.quantity}, Weight: ${gear.weight})');
        }
      }
    }
  }

}


// Global instance of SavedPreferences
final SavedPreferences savedPreferences = SavedPreferences();

Map<int, String> loadPreferenceMap = {
  0: 'First',
  1: 'Last',
  2: 'Balanced',
};

