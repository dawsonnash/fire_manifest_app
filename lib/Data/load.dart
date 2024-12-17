import 'package:hive/hive.dart';

import '../05_build_your_own_manifest.dart';
import 'crewmember.dart';
import 'customItem.dart';
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
  @HiveField(4) // New field for CustomItem
  List<CustomItem> customItems = [];

  Load({required this.loadNumber,
    required this.weight,
    required this.loadPersonnel,
    required this.loadGear,
    this.customItems = const [],

});
}
