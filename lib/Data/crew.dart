import 'crewmember.dart';
import 'gear.dart';

class Crew {
  List<CrewMember> crewMembers = [];
  List<Gear> gear = [];

  void addCrewMember(CrewMember member) {
    crewMembers.add(member);
  }

  void addGear(Gear gearItem) {
    gear.add(gearItem);
  }
}

// Global Crew object. This is THE main crew object that comes inherit to the app
final Crew crew = Crew();
