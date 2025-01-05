import 'package:hive/hive.dart';

part 'customItem.g.dart';

@HiveType(typeId: 4) // Unique typeId for CustomItem
class CustomItem extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int weight;


  CustomItem({
    required this.name,
    required this.weight,
  });

}
