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
    double crewWeight = 0.0;
    for (var member in crewMembers) {
      crewWeight += member.flightWeight;
    }

    double gearWeight = 0.0;
    for (var gearItem in gear) {
      gearWeight += gearItem.weight;
    }

    totalCrewWeight = crewWeight + gearWeight;
  }

  void addCrewMember(CrewMember member) {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox'); // assign hive box to variable we can use
    crewMembers.add(member); // add crewmember in memory as well
    crewmemberBox.add(member); // save to hive memory
    updateTotalCrewWeight();
    print('Updated Total Crew Weight: $totalCrewWeight');
  }

  void removeCrewMember(CrewMember member){
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    final keyToRemove = crewmemberBox.keys.firstWhere( // find hive key of entry we are removing
          (key) => crewmemberBox.get(key) == member,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      crewmemberBox.delete(keyToRemove);
    }
    crewMembers.remove(member); // remove in-memory as well
    updateTotalCrewWeight();
    print('Updated Total Crew Weight: $totalCrewWeight');
  }

  void deleteAllCrewMembers() {
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    // Clear the in-memory list
    crewMembers.clear();
    // Clear the Hive storage
    crewmemberBox.clear();
    // Update the total weight
    updateTotalCrewWeight();
  }

  void removeGear(Gear gearItem){
    var gearBox = Hive.box<Gear>('gearBox');

    final keyToRemove = gearBox.keys.firstWhere( // find hive key of entry we are removing
          (key) => gearBox.get(key) == gearItem,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      gearBox.delete(keyToRemove);
    }
    gear.remove(gearItem); // removed from in-memory as well
    updateTotalCrewWeight();
    print('Updated Total Crew Weight: $totalCrewWeight');
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
    // Clear the in-memory list
    gear.clear();
    // Clear the Hive storage
    gearBox.clear();
    // Update the total weight
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

