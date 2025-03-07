
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

    // Load values into the global manager
    loadAccoutrementManager.loadAccoutrements = loadAccoutrementBox.values.toList();
  }


}
// Global Crew object. This is THE main crew object that comes inherit to the app
final LoadAccoutrementManager loadAccoutrementManager = LoadAccoutrementManager();

