import 'crewmember.dart';
import 'gear.dart';

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
    crewMembers.add(member);
    updateTotalCrewWeight();
  }

  void removeCrewMember(CrewMember member){
    crewMembers.remove(member);
    updateTotalCrewWeight();
  }

  void removeGear(Gear gearItem){
    gear.remove(gearItem);
    updateTotalCrewWeight();
  }

  void addGear(Gear gearItem) {
    gear.add(gearItem);
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
