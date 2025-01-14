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
