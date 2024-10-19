import 'crewmember.dart';
import 'gear.dart';
import 'package:hive/hive.dart';

class Crew {
  List<CrewMember> crewMembers = [];
  List<Gear> gear = [];
  double totalCrewWeight = 0.0;

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
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    crewMembers.add(member); // add to in memory as well
    crewmemberBox.add(member); // save to hive memory
    updateTotalCrewWeight();
  }

  void removeCrewMember(CrewMember member){
    var crewmemberBox = Hive.box<CrewMember>('crewmemberBox');

    final keyToRemove = crewmemberBox.keys.firstWhere( // find which Hive key we want to remove
          (key) => crewmemberBox.get(key) == member,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      crewmemberBox.delete(keyToRemove);
    }
    crewMembers.remove(member); // remove in-memory as well
    updateTotalCrewWeight();
  }

  void removeGear(Gear gearItem){
    var gearBox = Hive.box<Gear>('gearBox');

    final keyToRemove = gearBox.keys.firstWhere( // find which Hive key we want to remove
          (key) => gearBox.get(key) == gearItem,
      orElse: () => null,
    );
    if (keyToRemove != null) {
      gearBox.delete(keyToRemove);
    }
    gear.remove(gearItem); // removed from in-memory as well
    updateTotalCrewWeight();
  }

  void addGear(Gear gearItem) {
    var gearBox = Hive.box<Gear>('gearBox');
    gear.add(gearItem); // added to in-memory as well
    gearBox.add(gearItem); // save to hive memory
    updateTotalCrewWeight();
  }

  // For LogCat testing purposes
  void printCrewDetails() {
    // Print out crewmebmers
    for (var member in crewMembers) {
      print('Name: ${member.name}, Flight Weight: ${member.flightWeight}');
    }

    // Print out all gear
    for (var gearItems in gear) {
      print('Name: ${gearItems.name}, Flight Weight: ${gearItems.weight}');
    }
  }
}

// Global Crew object. This is THE main crew object that comes inherit to the app
final Crew crew = Crew();
