import 'package:hive/hive.dart';
part 'gear.g.dart';

@HiveType(typeId: 0) // Needs to be a unique ID across app
class Gear extends HiveObject{
  @HiveField(0) // needs to be unique ID across class
  String name;
  @HiveField(1)
  int weight;

  @HiveField(2)
  int quantity;

  @HiveField(3)
  bool isPersonalTool;

  // bool hazmat;

  // Getter function to calculate totalGearWeight: weight * quantity
  int get totalGearWeight {
    int totalWeight = weight * quantity;
    return totalWeight;
  }

  // Function to create a copy of the Gear object with updated attributes - for quantity copies in Gear Preferences
  Gear copyWith({int? quantity}) {
    return Gear(
        name: this.name,
        quantity: quantity ?? this.quantity,
        weight: this.weight,
        isPersonalTool: this.isPersonalTool
    );
  }

  Gear({required this.name, required this.weight, required this.quantity, this.isPersonalTool = false});

  // Convert Gear object to a JSON-like map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'weight': weight,
      'quantity': quantity,
      'isPersonalTool': isPersonalTool,
    };
  }

  // Create a Gear object from a JSON-like map
  factory Gear.fromJson(Map<String, dynamic> json) {
    return Gear(
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