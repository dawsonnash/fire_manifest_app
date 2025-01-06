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

  // Delete all TripPreferences
  void deleteAllTripPreferences() {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.clear(); // Clear in-memory list
    tripPreferenceBox.clear(); // Clear Hive storage
  }

  // Add a PositionalPreference to a specific TripPreference
  void addPositionalPreference(
      TripPreference tripPreference, PositionalPreference newPreference) {
    tripPreference.positionalPreferences.add(newPreference); // Update in-memory
    _updateTripPreferenceInHive(tripPreference);
  }

  // Add a GearPreference to a specific TripPreference
  void addGearPreference(
      TripPreference tripPreference, GearPreference newPreference) {
    tripPreference.gearPreferences.add(newPreference); // Update in-memory
    _updateTripPreferenceInHive(tripPreference);
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
  void loadPreferencesFromHive() {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences = tripPreferenceBox.values.toList(); // Load into memory
  }

  // Debugging: Print all preferences
  void printPreferences() {
    for (var trip in tripPreferences) {
      print('Trip Preference: ${trip.tripPreferenceName}');
      for (var posPref in trip.positionalPreferences) {
        print('  Positional Preference: Priority ${posPref.priority}');
      }
      for (var gearPref in trip.gearPreferences) {
        print('  Gear Preference: Priority ${gearPref.priority}');
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



