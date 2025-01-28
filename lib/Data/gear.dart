import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';
part 'gear.g.dart';

final uuid = Uuid(); // Instantiate the UUID generator

@HiveType(typeId: 0) // Needs to be a unique ID across the app
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

  @HiveField(5) // Add this field for the isHazmat attribute
  bool isHazmat;

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
    this.isHazmat = false, // Default value for isHazmat
    String? id, // Optional parameter to allow manual ID assignment
  }) : id = id ?? uuid.v4(); // Generate a new UUID if not provided

  // Function to create a copy of the Gear object with updated attributes
  Gear copyWith({int? quantity, String? name, int? weight, bool? isPersonalTool, bool? isHazmat}) {
    return Gear(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      isPersonalTool: isPersonalTool ?? this.isPersonalTool,
      isHazmat: isHazmat ?? this.isHazmat,
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
      'isHazmat': isHazmat,
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
      isHazmat: json['isHazmat'] as bool, // Parse isHazmat
    );
  }
}

// Sort gear list alphabetically
List<Gear> sortGearListAlphabetically(List<Gear> gearList) {
  gearList.sort((a, b) => a.name.compareTo(b.name));
  return gearList;
}

final List<Map<String, dynamic>> irpgItems = [
  {'name': 'Backpack pump (full)', 'weight': 45, 'hazmat': true},
  {'name': 'Cargo net (12’ x 12’)', 'weight': 20, 'hazmat': false},
  {'name': 'Cargo net (20’ x 20’)', 'weight': 45, 'hazmat': false},
  {'name': 'Cargo net (fish net)', 'weight': 5, 'hazmat': false},
  {'name': 'Cargo hook (1 hook)', 'weight': 35, 'hazmat': false},
  {'name': 'Jerry can/fuel (5 gal.)', 'weight': 45, 'hazmat': true},
  {'name': 'Canteen (1 gal.)', 'weight': 10, 'hazmat': false},
  {'name': 'Dolmar (full)', 'weight': 15, 'hazmat': true},
  {'name': 'Drip torch (full)', 'weight': 15, 'hazmat': true},
  {'name': 'Fusee (1 case)', 'weight': 36, 'hazmat': true},
  {'name': 'Hand tool', 'weight': 8, 'hazmat': false},
  {'name': 'Lead line (12’) ', 'weight': 10, 'hazmat': false},
  {'name': 'Long line (50’)', 'weight': 30, 'hazmat': false},
  {'name': 'Swivel', 'weight': 5, 'hazmat': false},
  {'name': 'Chainsaw', 'weight': 25, 'hazmat': true},
  {'name': 'Hose, 1½” syn. 100’', 'weight': 23, 'hazmat': false},
  {'name': 'Hose, 1” syn. 100’', 'weight': 11, 'hazmat': false},
  {'name': 'Hose, 3/4" syn. (1,000’/case)', 'weight': 30, 'hazmat': false},
  {'name': 'Hose, suction, 8’', 'weight': 10, 'hazmat': false},
  {'name': 'Mark 3 – Pump with kit ', 'weight': 150, 'hazmat': true},
  {'name': 'Stokes w/ backboard', 'weight': 40, 'hazmat': false},
  {'name': 'Trauma bag', 'weight': 35, 'hazmat': false},
  {'name': 'MRE, 1 case', 'weight': 25, 'hazmat': false},
  {'name': 'Cubee/water (5 gal.)', 'weight': 45, 'hazmat': false},

];

