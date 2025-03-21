import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:fire_app/Data/sling.dart';
import 'package:hive/hive.dart';

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
  @HiveField(4)
  List<CustomItem> customItems = [];
  @HiveField(5) // New optional field for Sling
  List<Sling>? slings; // Nullable
  @HiveField(6)
  List<LoadAccoutrement>? loadAccoutrements = [];

  Load({required this.loadNumber,
    required this.weight,
    required this.loadPersonnel,
    required this.loadGear,
    this.customItems = const [],
    this.slings, // Default is null (optional)
    this.loadAccoutrements, // Default is null (optional)

  });

  void addSling(Load load, Sling newSling) {
    load.slings?.add(newSling);
    save();
  }

  // Deep copy method
  Load copy() {
    return Load(
      loadNumber: loadNumber,
      weight: weight,
      loadPersonnel: List.from(loadPersonnel),
      loadGear: loadGear.map((gear) => gear.copyWith()).toList(),
      customItems: customItems.map((item) => item.copy()).toList(),
      slings: slings?.map((sling) => sling.copy()).toList(),
      loadAccoutrements: List.from(loadAccoutrements ?? []),
    );
  }
}
