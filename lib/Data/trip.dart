import 'load.dart';

class Trip {

  String tripName;
  int allowable;

  List<Load> loads = [];

  Trip({required this.tripName, required this.allowable});
}

class SavedTrips {

  List<Trip> savedTrips = [];


  void addTrip(Trip newTrip) {
    // var tripBox = Hive.box<Trip>('tripBox');
    savedTrips.add(newTrip); // add to in memory as well
    //tripBox.add(newTrip); // save to hive memory
  }

  void removeTrip(Trip trip){
    // var tripBox = Hive.box<Trip>('tripBox');

    // final keyToRemove = tripBox.keys.firstWhere( // find which Hive key we want to remove
    //       (key) => tripBox.get(key) == member,
    //   orElse: () => null,
    // );
    // if (keyToRemove != null) {
    //   tripBox.delete(keyToRemove);
    // }
    savedTrips.remove(trip); // remove in-memory as well
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
