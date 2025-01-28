import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
part 'gear.g.dart';

final uuid = Uuid(); // Instantiate the UUID generator

@HiveType(typeId: 0) // Needs to be a unique ID across app
class Gear extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int weight;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  bool isPersonalTool;

  @HiveField(4) // Add this field for the UUID
  final String id;

  // Getter function to calculate totalGearWeight: weight * quantity
  int get totalGearWeight {
    return weight * quantity;
  }

  // Constructor to generate a UUID automatically
  Gear({
    required this.name,
    required this.weight,
    required this.quantity,
    this.isPersonalTool = false,
    String? id, // Optional parameter to allow manual ID assignment
  }) : id = id ?? uuid.v4(); // Generate a new UUID if not provided

  // Function to create a copy of the Gear object with updated attributes
  Gear copyWith({int? quantity, String? name, int? weight, bool? isPersonalTool}) {
    return Gear(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      isPersonalTool: isPersonalTool ?? this.isPersonalTool,
      id: this.id, // Keep the same UUID for copies
    );
  }

  // Convert Gear object to a JSON-like map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'weight': weight,
      'quantity': quantity,
      'isPersonalTool': isPersonalTool,
    };
  }

  // Create a Gear object from a JSON-like map
  factory Gear.fromJson(Map<String, dynamic> json) {
    return Gear(
      id: json['id'] as String,
      name: json['name'] as String,
      weight: json['weight'] as int,
      quantity: json['quantity'] as int,
      isPersonalTool: json['isPersonalTool'] as bool,
    );
  }
}

List<Gear> sortGearListAlphabetically(List<Gear> gearList) {
  gearList.sort((a, b) => a.name.compareTo(b.name));
  return gearList;
}
final List<Map<String, dynamic>> irpgItems = [
  {'name': 'Backpack pump (full)', 'weight': 45},
  {'name': 'Cargo net (12’ x 12’)', 'weight': 20},
  {'name': 'Cargo net (20’ x 20’)', 'weight': 45},
  {'name': 'Cargo net (fish net)', 'weight': 5},
  {'name': 'Cargo hook (1 hook)', 'weight': 35},
  {'name': 'Jerry can/fuel (5 gal.)', 'weight': 45},
  {'name': 'Canteen (1 gal.)', 'weight': 10},
  {'name': 'Dolmar (full)', 'weight': 15},
  {'name': 'Drip torch (full)', 'weight': 15},
  {'name': 'Fusee (1 case)', 'weight': 36},
  {'name': 'Hand tool', 'weight': 8},
  {'name': 'Lead line (12’) ', 'weight': 10},
  {'name': 'Long line (50’)', 'weight': 30},
  {'name': 'Swivel', 'weight': 5},
  {'name': 'Chainsaw', 'weight': 25},
  {'name': 'Hose, 1½” syn. 100’', 'weight': 23},
  {'name': 'Hose, 1” syn. 100’', 'weight': 11},
  {'name': 'Hose, 3/4" syn. (1,000’/case)', 'weight': 30},
  {'name': 'Hose, suction, 8’', 'weight': 10},
  {'name': 'Mark 3 – Pump with kit ', 'weight': 150},
  {'name': 'Stokes w/ backboard', 'weight': 40},
  {'name': 'Trauma bag', 'weight': 35},
  {'name': 'MRE, 1 case', 'weight': 25},
  {'name': 'Cubee/water (5 gal.)', 'weight': 45},

];

