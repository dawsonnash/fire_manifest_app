import 'crewmember.dart';
import 'gear.dart';

class Crew {
  List<CrewMember> crewMembers = [];
  List<Gear> gear = [];

  void addCrewMember(CrewMember member) {
    crewMembers.add(member);
  }

  void removeCrewMember(CrewMember member){
    crewMembers.remove(member);
  }

  void removeGear(Gear gearItem){
    gear.remove(gearItem);
  }

  void addGear(Gear gearItem) {
    gear.add(gearItem);
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
