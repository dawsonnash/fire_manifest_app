import 'package:hive/hive.dart';
part 'load_accoutrements.g.dart';

@HiveType(typeId: 9)
class LoadAccoutrement extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  int weight;

  @HiveField(2)
  int quantity;

  // Constructor to generate a UUID automatically
  LoadAccoutrement({
    required this.name,
    required this.weight,
    required this.quantity,

  });

  // Function to create a copy of the Gear object with updated attributes
  LoadAccoutrement copyWith({String? name, int? weight, int? quantity}) {
    return LoadAccoutrement(
      name: name ?? this.name,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,

    );
  }

  // Convert Gear to JSON
  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "weight": weight,
      "quantity": quantity,

    };
  }

  // Convert JSON back into Gear
  factory LoadAccoutrement.fromJson(Map<String, dynamic> json) {
    return LoadAccoutrement(
      name: json["name"],
      weight: json["weight"],
      quantity: json["quantity"],

    );
  }
}


