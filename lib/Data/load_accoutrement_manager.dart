
import 'package:hive/hive.dart';

import 'load_accoutrements.dart';

class LoadAccoutrementManager {
  List<LoadAccoutrement> loadAccoutrements = [];


  // Explicit constructor
  LoadAccoutrementManager({
    this.loadAccoutrements = const [],

  });

  // Convert loadAccoutrement to JSON
  Map<String, dynamic> toJson() {
    return {
      "loadAccoutrements": loadAccoutrements.map((member) => member.toJson()).toList(),
    };
  }

  // Convert JSON back into Crew object
  factory LoadAccoutrementManager.fromJson(Map<String, dynamic> json) {
    LoadAccoutrementManager crewLoadAccoutrements = LoadAccoutrementManager();
    crewLoadAccoutrements.loadAccoutrements = (json["loadAccoutrements"] as List)
        .map((item) => LoadAccoutrement.fromJson(item))
        .toList();
    return crewLoadAccoutrements;
  }

  // Loads Load Accoutrements from Hive or initializes defaults on first launch
  Future<void> loadLoadAccoutrementsFromHive() async {
    var loadAccoutrementBox = Hive.box<LoadAccoutrement>('loadAccoutrementBox');
    var settingsBox = Hive.box('settingsBox'); // Box to track first launch

    // Check if this is the first app launch
    bool isFirstLaunch = settingsBox.get('isFirstLaunch', defaultValue: true);

    if (isFirstLaunch) {
      await _initializeDefaultLoadAccoutrements(); // Populate only ONCE
      await settingsBox.put('isFirstLaunch', false); // Set flag to prevent future resets
    }

    // Load values into the global manager
    loadAccoutrementManager.loadAccoutrements = loadAccoutrementBox.values.toList();
  }

  // Initializes default Load Accoutrements **only on first app launch**
  Future<void> _initializeDefaultLoadAccoutrements() async {
    var loadAccoutrementBox = Hive.box<LoadAccoutrement>('loadAccoutrementBox');

    List<LoadAccoutrement> defaultLoadAccoutrements = [
      LoadAccoutrement(name: "Cargo net (12’ x 12’)", weight: 20),
      LoadAccoutrement(name: "Cargo net (20’ x 20’)", weight: 45),
      LoadAccoutrement(name: "Lead line (12’)", weight: 10),
      LoadAccoutrement(name: "Swivel", weight: 5),
    ];

    for (var item in defaultLoadAccoutrements) {
      await loadAccoutrementBox.add(item);
    }
  }
}
// Global Crew object. This is THE main crew object that comes inherit to the app
final LoadAccoutrementManager loadAccoutrementManager = LoadAccoutrementManager();

