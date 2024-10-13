import 'package:hive/hive.dart';
part 'gear.g.dart';

@HiveType(typeId: 0) // Needs to be a unique ID across app
class Gear extends HiveObject{
  @HiveField(0) // needs to be unique ID across class
  String name;
  @HiveField(1)
  int weight;
  // bool hazmat;

  Gear({required this.name, required this.weight});
}
