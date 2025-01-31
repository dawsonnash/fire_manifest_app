import 'package:hive/hive.dart';
import 'crewmember.dart';
import 'gear.dart';
import 'load.dart';

part 'trip.g.dart';

@HiveType(typeId: 3)
class Trip extends HiveObject {
  @HiveField(0)
  String tripName;
  @HiveField(1)
  int allowable;
  @HiveField(2)
  int availableSeats;
  @HiveField(3)
  List<Load> loads = [];
  @HiveField(4) // Add a new field index
  DateTime timestamp; // New attribute to store the timestamp
  @HiveField(5)
  List<CrewMember> crewMembers = [];
  @HiveField(6)
  List<Gear> gear = [];
  @HiveField(7)
  int? totalCrewWeight;

  //

  Trip({
    required this.tripName,
    required this.allowable,
    required this.availableSeats,
    DateTime? timestamp,}) : timestamp = timestamp ?? DateTime.now(); // Default to current time if not provided;

  void addLoad(Trip trip, Load newLoad) {
    trip.loads.add(newLoad); //
  }

  // For LogCat testing purposes
  void printLoadDetails() {
    if (loads.isEmpty) {
      print('No loads available for this trip.');
      return;
    }
    // Print out Trip info
    for (var load in loads) {
      print('Load Number: ${load.loadNumber}, Weight: ${load.weight}');
      print('--------------------------------');

      for (var member in load.loadPersonnel) {
        print('Name: ${member.name}, FlightWeight: ${member.flightWeight}');
      }
      for (var gear in load.loadGear) {
        print('Name: ${gear.name}, Weight: ${gear.weight}');
      }
    }
  }
  // Function to calculate total crew weight and update `totalCrewWeight`
  void calculateTotalCrewWeight() {
    int totalWeight = 0;

    // Calculate total weight of all crew members and their personal tools
    for (var crewMember in crewMembers) {
      totalWeight += crewMember.flightWeight;

      // Add the weight of personal tools, if any
      if (crewMember.personalTools != null) {
        for (var tool in crewMember.personalTools!) {
          totalWeight += tool.totalGearWeight;
        }
      }
    }

    // Calculate total weight of all gear
    for (var gearItem in gear) {
      totalWeight += gearItem.totalGearWeight;
    }

    // Update the `totalCrewWeight` attribute
    totalCrewWeight = totalWeight;
  }
}

class SavedTrips {
  List<Trip> savedTrips = [];

  void addTrip(Trip newTrip) {
    var tripBox = Hive.box<Trip>('tripBox');
    savedTrips.add(newTrip); // add to in memory as well
    tripBox.add(newTrip); // save to hive memory
  }

  void removeTrip(Trip trip) {
    var tripBox = Hive.box<Trip>('tripBox');

    final keyToRemove = tripBox.keys.firstWhere(
      // find which Hive key we want to remove
      (key) => tripBox.get(key) == trip,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      tripBox.delete(keyToRemove);
    }
    savedTrips.remove(trip); // remove in-memory as well
  }

  void deleteAllTrips() {
    var tripBox = Hive.box<Trip>('tripBox');
    // Clear the in-memory list
    savedTrips.clear();
    // Clear the Hive storage
    tripBox.clear();
  }

  // For LogCat testing purposes
  void printTripDetails() {
    // Print out Trip info

    for (var trip in savedTrips) {
      print('Name: ${trip.tripName}, Allowable: ${trip.allowable}');
    }
  }

  // Load all preferences from Hive to in-memory lists
  Future<void> loadTripDataFromHive() async {
    var tripBox = Hive.box<Trip>('tripBox');
    savedTrips = tripBox.values.toList(); // Load into memory
  }
}

// Global object for all saved trips. All created trips will be stored here
// Until hive implementation
final SavedTrips savedTrips = SavedTrips();
