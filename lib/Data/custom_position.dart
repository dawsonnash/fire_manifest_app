import 'package:hive/hive.dart';
import 'package:collection/collection.dart';

part 'custom_position.g.dart';

@HiveType(typeId: 11)
class CustomPosition extends HiveObject {
  @HiveField(0)
  int code;

  @HiveField(1)
  String title;

  CustomPosition({
    required this.code,
    required this.title,
  });

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'title': title,
    };
  }

  factory CustomPosition.fromJson(Map<String, dynamic> json) {
    return CustomPosition(
      code: json['code'],
      title: json['title'],
    );
  }

  // KEY to store persistent counter inside Hive
  static const String _counterKey = 'custom_position_counter';

  // Static convenience function to add af position
  static Future<void> addPosition(String title) async {
    final box = Hive.box<CustomPosition>('customPositionsBox');
    final counterBox = Hive.box('appDataBox');

    // Get last counter value or initialize to 0
    int lastCode = counterBox.get(_counterKey, defaultValue: 0);

    // Decrement (always goes lower)
    int nextCode = lastCode - 1;

    // Save new counter value
    await counterBox.put(_counterKey, nextCode);

    // Add new position with unique code
    await box.add(CustomPosition(code: nextCode, title: title));
  }

  static Future<void> deletePosition(int codeToDelete) async {
    final box = Hive.box<CustomPosition>('customPositionsBox');
    final target = box.values.firstWhereOrNull((pos) => pos.code == codeToDelete);
    if (target != null) {
      await target.delete();
    }
  }
}
