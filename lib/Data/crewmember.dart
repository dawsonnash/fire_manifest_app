import 'package:hive/hive.dart';
part 'crewmember.g.dart';


@HiveType(typeId: 1) // Needs to be a unique ID across app
class CrewMember extends HiveObject{
  @HiveField(0)// needs to be unique ID across class
  String name;
  @HiveField(1)// needs to be unique ID across class
  int flightWeight;
  // int positions[];

  CrewMember({required this.name, required this.flightWeight});
}
