import 'package:fire_app/Data/trip.dart';
import 'package:hive/hive.dart';

import 'gear.dart';
import 'positional_preferences.dart';
import 'gear_preferences.dart';
import 'trip_preferences.dart';

class SavedPreferences {
  List<TripPreference> tripPreferences = [];

  void addTripPreference(TripPreference newTripPreference) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    tripPreferences.add(newTripPreference);
    tripPreferenceBox.add(newTripPreference); // save to hive memory
  }

  void deleteTripPreference(TripPreference tripPreference) {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    final keyToRemove = tripPreferenceBox.keys.firstWhere( // find hive key of entry we are removing
          (key) => tripPreferenceBox.get(key) == tripPreference,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      tripPreferenceBox.delete(keyToRemove);
    }
    tripPreferences.remove(tripPreference);
  }

  void deleteAllTripPreferences() {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    // Clear the Hive storage
    tripPreferenceBox.clear();
    savedPreferences.tripPreferences.clear();

  }

  void addPostionalPreference(TripPreference tripPreference, PositionalPreference newPreference) {
    tripPreference.positionalPreferences.add(newPreference);

  }

  void addGearPreference(TripPreference tripPreference, GearPreference newPreference) {
    tripPreference.gearPreferences.add(newPreference); // add crewmember in memory as well
  }

  // This function loads all data stored in the hive for 'Crew' into the local in-memory
  // Seems to be an easier way to work with data for now.
  void loadSavedPreferenceDataFromHive() {
    var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');

    // Load crew members from Hive into the in-memory list
    savedPreferences.tripPreferences = tripPreferenceBox.values.toList();
  }
}

Map<int, String> loadPreferenceMap = {
  0: 'First',
  1: 'Last',
  2: 'Balanced',
};

// Global SavedPreferences object
final SavedPreferences savedPreferences = SavedPreferences();



