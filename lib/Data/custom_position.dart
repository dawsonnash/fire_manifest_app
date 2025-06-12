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

  // JSON serialization (optional but good to keep for export/import later)
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

  // Static convenience function to add a position
  static Future<void> addPosition(String title) async {
    final box = Hive.box<CustomPosition>('customPositionsBox');
    int nextCode = -1;
    if (box.isNotEmpty) {
      int minCode = box.values.map((e) => e.code).reduce((a, b) => a < b ? a : b);
      nextCode = minCode - 1;
    }
    await box.add(CustomPosition(code: nextCode, title: title));
  }

  static Future<void> deletePosition(int codeToDelete) async {
    final box = Hive.box<CustomPosition>('customPositionsBox');
    final CustomPosition? target = box.values.firstWhereOrNull(
          (pos) => pos.code == codeToDelete,
    );
    if (target != null) {
      await target.delete();
    }
  }


}
