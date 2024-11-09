import 'package:hive/hive.dart';

import 'load.dart';

part 'trip.g.dart';

@HiveType(typeId: 3)
class Trip extends HiveObject{
  @HiveField(0)
  String tripName;
  @HiveField(1)
  int allowable;
  @HiveField(2)
  int availableSeats;
  @HiveField(3)
  List<Load> loads = [];

  //

  Trip({required this.tripName, required this.allowable, required this.availableSeats});

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


}

class SavedTrips {

  List<Trip> savedTrips = [];


  void addTrip(Trip newTrip) {
    var tripBox = Hive.box<Trip>('tripBox');
    savedTrips.add(newTrip); // add to in memory as well
    tripBox.add(newTrip); // save to hive memory
  }

  void removeTrip(Trip trip){
    var tripBox = Hive.box<Trip>('tripBox');

    final keyToRemove = tripBox.keys.firstWhere( // find which Hive key we want to remove
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
}


// Global object for all saved trips. All created trips will be stored here
// Until hive implementation
final SavedTrips savedTrips = SavedTrips();
