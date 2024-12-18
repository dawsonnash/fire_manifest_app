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
}
