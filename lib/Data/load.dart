import 'crewmember.dart';
import 'gear.dart';

class Load {

  int loadNumber;
  int weight;

  List<CrewMember> loadPersonnel = [];
  List<Gear> loadGear = [];

  Load({required this.loadNumber, required this.weight});
}