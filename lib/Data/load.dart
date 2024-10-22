import 'package:hive/hive.dart';

import 'crewmember.dart';
import 'gear.dart';

part 'load.g.dart';

@HiveType(typeId: 2)
class Load extends HiveObject{
  @HiveField(0) // needs to be unique ID across class
  int loadNumber;
  @HiveField(1)
  int weight;
  @HiveField(2)
  List<CrewMember> loadPersonnel = [];
  @HiveField(3)
  List<Gear> loadGear = [];

  Load({required this.loadNumber,
    required this.weight,
    required this.loadPersonnel,
    required this.loadGear
  });
}