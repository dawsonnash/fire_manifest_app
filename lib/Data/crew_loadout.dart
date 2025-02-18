import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CrewLoadoutStorage {

  /// Get directory for storing crew loadouts
  static Future<Directory> _getLoadoutDirectory() async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final Directory loadoutDir = Directory('${appDir.path}/crew_loadouts');

    if (!await loadoutDir.exists()) {
      await loadoutDir.create(recursive: true);
    }

    return loadoutDir;
  }

  /// Save a new crew loadout as a JSON file
  static Future<void> saveLoadout(String name, Map<String, dynamic> loadoutData) async {
    Directory loadoutDir = await _getLoadoutDirectory();
    String filePath = '${loadoutDir.path}/$name.json';

    File file = File(filePath);
    await file.writeAsString(jsonEncode(loadoutData));

    print('Loadout saved: $filePath');

  }

  /// Load a crew loadout from a JSON file
  static Future<Map<String, dynamic>?> loadLoadout(String name) async {
    Directory loadoutDir = await _getLoadoutDirectory();
    String filePath = '${loadoutDir.path}/$name.json';

    File file = File(filePath);
    if (await file.exists()) {
      String jsonString = await file.readAsString();
      return jsonDecode(jsonString);
    } else {
      print('Loadout file not found: $filePath');
      return null;
    }
  }

  /// Delete a saved loadout
  static Future<void> deleteLoadout(String name) async {
    Directory loadoutDir = await _getLoadoutDirectory();
    String filePath = '${loadoutDir.path}/$name.json';

    File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
      print('Deleted loadout: $filePath');
    }
  }

  /// Get all saved loadouts (sorted by oldest first)
  static Future<List<File>> _getLoadoutFiles() async {
    Directory loadoutDir = await _getLoadoutDirectory();
    List<FileSystemEntity> files = loadoutDir.listSync();
    List<File> jsonFiles = [];

    for (var file in files) {
      if (file is File && file.path.endsWith('.json')) {
        jsonFiles.add(file);
      }
    }

    jsonFiles.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync())); // Sort oldest first
    return jsonFiles;
  }


  /// Get a list of saved loadout names (without ".json" extension)
  static Future<List<String>> getAllLoadoutNames() async {
    List<File> loadoutFiles = await _getLoadoutFiles();
    return loadoutFiles.map((file) => file.uri.pathSegments.last.replaceAll('.json', '')).toList();
  }
}
