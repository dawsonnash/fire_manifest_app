import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:hive/hive.dart';

import 'customItem.dart';
import 'gear.dart';

part 'sling.g.dart';

@HiveType(typeId: 10)
class Sling extends HiveObject{
  @HiveField(0) // needs to be unique ID across class
  int slingNumber;
  @HiveField(1)
  int weight;
  @HiveField(2)
  List<LoadAccoutrement> loadAccoutrements = [];
  @HiveField(3)
  List<Gear> loadGear = [];
  @HiveField(4)
  List<CustomItem> customItems = [];

  Sling({required this.slingNumber,
    required this.weight,
    required this.loadAccoutrements,
    required this.loadGear,
    this.customItems = const [],
  });

  // **Deep Copy Method**
  Sling copy() {
    return Sling(
      slingNumber: slingNumber,
      weight: weight,
      loadAccoutrements: List.from(loadAccoutrements), // Copy list items
      loadGear: loadGear.map((gear) => gear.copyWith()).toList(), // Deep copy each gear item
      customItems: customItems.map((item) => item.copy()).toList(), // Deep copy each custom item
    );
  }
}
