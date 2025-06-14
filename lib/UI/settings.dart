import 'dart:convert';
import 'dart:io';
import 'dart:math' as math; // Import this at the top of your file
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/Data/trip_preferences.dart';
import 'package:fire_app/UI/quick_guide.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../CodeShare/keyboardActions.dart';
import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/crew_loadout.dart';
import '../Data/crewmember.dart';
import '../Data/custom_position.dart';
import '../Data/gear.dart';

class SettingsView extends StatefulWidget {
  final bool isDarkMode;
  final bool enableBackgroundImage;
  final Function(bool) onThemeChanged;
  final Function(bool) onBackgroundImageChange;
  final String crewName;
  final String userName;
  final int safetyBuffer;
  final double textScale;
  final Function(String) onCrewNameChanged;
  final Function(String) onUserNameChanged;
  final Function(int) onSafetyBufferChange;
  final Function(double) onTextScaleChange;

  const SettingsView({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.enableBackgroundImage,
    required this.onBackgroundImageChange,
    required this.crewName,
    required this.userName,
    required this.safetyBuffer,
    required this.textScale,
    required this.onCrewNameChanged,
    required this.onUserNameChanged,
    required this.onSafetyBufferChange,
    required this.onTextScaleChange,

  });

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {

  final GlobalKey _scaffoldKey = GlobalKey();

  late bool isDarkMode;
  late bool enableBackgroundImage;
  late double textScale;
  late TextEditingController crewNameController;
  late TextEditingController userNameController;
  late TextEditingController safetyBufferController;
  List<String> loadoutNames = [];
  String? selectedLoadout;
  String lastSavedTimestamp = "N/A"; // Default value
  bool isOutOfSync = false; // Tracks sync status of current crew loadout vs current crew data

  @override
  void initState() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
    isDarkMode = widget.isDarkMode;
    enableBackgroundImage = widget.enableBackgroundImage;
    crewNameController = TextEditingController(text: widget.crewName); // Initialize with the current crew name
    userNameController = TextEditingController(text: widget.userName); // Initialize with the current user name
    safetyBufferController = TextEditingController(text: widget.safetyBuffer.toString());
    textScale = widget.textScale;

    _loadLoadoutNames().then((_) {
      if (selectedLoadout != null) {
        _checkSyncStatus(selectedLoadout!); // Check sync status ONCE when Settings opens
      }
    });
  }

  @override
  void dispose() {
    crewNameController.dispose(); // Dispose the controller to free resources
    userNameController.dispose(); // Dispose the controller to free resources
    safetyBufferController.dispose();
    super.dispose();
  }

  Future<void> _loadLoadoutNames() async {
    List<String> savedLoadouts = await CrewLoadoutStorage.getAllLoadoutNames();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastUsedLoadout = prefs.getString('last_selected_loadout');

    setState(() {
      loadoutNames = savedLoadouts;

      if (lastUsedLoadout != null && loadoutNames.contains(lastUsedLoadout)) {
        // If there was a previous selection, restore it
        selectedLoadout = lastUsedLoadout;
      } else {
        // If no valid previous selection, keep it null (Select a Loadout)
        selectedLoadout = null;
        lastSavedTimestamp = "N/A";
        isOutOfSync = false;
      }
    });

    if (selectedLoadout != null) {
      await _loadLastSavedTimestamp(selectedLoadout!);
      await _checkSyncStatus(selectedLoadout!);
    }
  }

  bool _areTripPreferencesEqual(TripPreference a, TripPreference b) {
    // Extract unique crew member names from positional preferences (handles lists & individuals)
    Set<String> aCrewNames = a.positionalPreferences
        .expand((pp) => pp.crewMembersDynamic.expand((cm) => cm is CrewMember
            ? [cm.name] // Individual crew member
            : (cm as List<CrewMember>).map((m) => m.name))) // List of crew members
        .toSet();

    Set<String> bCrewNames = b.positionalPreferences.expand((pp) => pp.crewMembersDynamic.expand((cm) => cm is CrewMember ? [cm.name] : (cm as List<CrewMember>).map((m) => m.name))).toSet();

    // Extract unique gear names from gear preferences
    Set<String> aGearNames = a.gearPreferences.expand((gp) => gp.gear.map((g) => g.name)).toSet();

    Set<String> bGearNames = b.gearPreferences.expand((gp) => gp.gear.map((g) => g.name)).toSet();

    // **Compare only presence of crew names and gear names** (ignoring any attribute changes)
    return setEquals(aCrewNames, bCrewNames) && setEquals(aGearNames, bGearNames);
  }

  Map<String, List<String>> _getCrewMemberDifferences(
      List<CrewMember> currentList,
      List<CrewMember> savedList,
      Map<int, String> currentCustomPositionsMap,
      Map<int, String> savedCustomPositionsMap
      ) {
    List<String> removed = [];
    List<String> added = [];
    List<String> modified = [];

    // Helper function to get title from both standard + custom positions
    String getTitle(int code, Map<int, String> customMap) {
      if (positionMap.containsKey(code)) {
        return positionMap[code]!;
      } else if (customMap.containsKey(code)) {
        return customMap[code]!;
      }
      return "Unknown Position (code $code)";
    }


    for (var saved in savedList) {

      var current = currentList.firstWhere(
            (c) => c.name == saved.name,
        orElse: () => CrewMember(name: "", flightWeight: -1, position: -1, personalTools: []),
      );

      if (current.name.isEmpty) {
        removed.add(saved.name);
        continue;
      }

      List<String> changes = [];

      if (current.flightWeight != saved.flightWeight) {
        changes.add("\n-- ${saved.flightWeight} → ${current.flightWeight} lb");
      }


      String savedTitle = getTitle(saved.position, savedCustomPositionsMap);
      String currentTitle = getTitle(current.position, currentCustomPositionsMap);

      print("saved.position: ${saved.position}, savedTitle: '$savedTitle'");
      print("current.position: ${current.position}, currentTitle: '$currentTitle'");

      bool positionChanged = current.position != saved.position;
      bool positionTitleChanged = savedTitle != currentTitle;

      if (positionChanged || positionTitleChanged) {
        changes.add("\n-- $savedTitle → $currentTitle");
      }

      // Tool differences (keep as-is)
      Map<String, List<String>> toolChanges = _getToolDifferences(current.personalTools ?? [], saved.personalTools ?? []);
      List<String> toolSummary = [];

      if (toolChanges["removed"]!.isNotEmpty) {
        toolSummary.add("Removed ${toolChanges["removed"]!.join(", ")}");
      }
      if (toolChanges["added"]!.isNotEmpty) {
        toolSummary.add("Added ${toolChanges["added"]!.join(", ")}");
      }

      if (toolSummary.isNotEmpty) {
        changes.add("\n-- ${toolSummary.join(", ")}");
      }

      if (changes.isNotEmpty) {
        modified.add("${saved.name}: ${changes.join(", ")}");
      }
    }

    // New crew members check
    for (var current in currentList) {
      if (!savedList.any((saved) => saved.name == current.name)) {
        added.add(current.name);
      }
    }

    return {
      "removed": removed,
      "added": added,
      "modified": modified,
    };
  }

  Map<String, List<String>> _getGearDifferences(List<Gear> currentList, List<Gear> savedList) {
    List<String> removed = [];
    List<String> added = [];
    List<String> modified = [];

    for (var saved in savedList) {
      var current = currentList.firstWhere(
        (g) => g.name == saved.name, // Match by name
        orElse: () => Gear(name: "", weight: 0, quantity: 0, isPersonalTool: false, isHazmat: false),
      );

      if (current.name.isEmpty) {
        removed.add(saved.name); // Store only the name for removed gear
        continue;
      }

      List<String> changes = [];
      if (current.weight != saved.weight) {
        changes.add("\n-- ${saved.weight} → ${current.weight} lb");
      }
      if (current.quantity != saved.quantity) {
        changes.add("\n-- Quantity: ${saved.quantity} → ${current.quantity}");
      }
      if (current.isHazmat != saved.isHazmat) {
        changes.add("\n-- Hazmat: ${saved.isHazmat ? 'Yes' : 'No'} → ${current.isHazmat ? 'Yes' : 'No'}");
      }

      if (changes.isNotEmpty) {
        modified.add("${saved.name}: ${changes.join(", ")}");
      }
    }

    // Detect **new gear items**
    for (var current in currentList) {
      if (!savedList.any((saved) => saved.name == current.name)) {
        added.add(current.name); // Store only the name for new gear
      }
    }

    return {
      "removed": removed,
      "added": added,
      "modified": modified,
    };
  }

  Map<String, List<String>> _getToolDifferences(List<Gear> currentTools, List<Gear> savedTools) {
    List<String> removed = [];
    List<String> added = [];
    List<String> modified = [];

    for (var saved in savedTools) {
      var current = currentTools.firstWhere(
        (t) => t.name == saved.name, // Match by name
        orElse: () => Gear(name: "", weight: 0, quantity: 0, isPersonalTool: false, isHazmat: false),
      );

      if (current.name.isEmpty) {
        removed.add(saved.name); // Store only the name for removed tools
        continue;
      }

      // Compare attributes
      List<String> changes = [];
      if (current.weight != saved.weight) {
        changes.add("\n-- ${saved.weight} → ${current.weight}lb");
      }

      if (current.isHazmat != saved.isHazmat) {
        changes.add("\n-- Hazmat: ${saved.isHazmat ? 'Yes' : 'No'} → ${current.isHazmat ? 'Yes' : 'No'}");
      }

      if (changes.isNotEmpty) {
        modified.add("${saved.name}: ${changes.join(", ")}");
      }
    }

    // Detect newly added tools
    for (var current in currentTools) {
      if (!savedTools.any((saved) => saved.name == current.name)) {
        added.add(current.name);
      }
    }

    return {
      "removed": removed,
      "added": added,
      "modified": modified,
    };
  }

  Future<void> _checkSyncStatus(String loadoutName) async {
    Map<String, dynamic>? lastSavedData = await CrewLoadoutStorage.loadLoadout(loadoutName);

    if (lastSavedData == null) {
      setState(() {
        isOutOfSync = true;
      });
      return;
    }

    // Include custom positions
    String lastSavedCrewJson = jsonEncode(lastSavedData["crew"]);
    String lastSavedPreferencesJson = jsonEncode(lastSavedData["savedPreferences"]);
    String lastSavedCustomPositionsJson = jsonEncode(lastSavedData["customPositions"]);

    Map<String, dynamic> currentCrewData = {
      "crew": crew.toJson(),
      "savedPreferences": savedPreferences.toJson(),
      "customPositions": Hive.box<CustomPosition>('customPositionsBox')
          .values
          .map((pos) => pos.toJson())
          .toList(),
    };

    String currentCrewJson = jsonEncode(currentCrewData["crew"]);
    String currentPreferencesJson = jsonEncode(currentCrewData["savedPreferences"]);
    String currentCustomPositionsJson = jsonEncode(currentCrewData["customPositions"]);

    setState(() {
      isOutOfSync = (lastSavedCrewJson != currentCrewJson) ||
          (lastSavedPreferencesJson != currentPreferencesJson) ||
          (lastSavedCustomPositionsJson != currentCustomPositionsJson);
    });
  }

  void _showSyncDifferencesDialog() async {
    Map<String, dynamic>? lastSavedData = await CrewLoadoutStorage.loadLoadout(selectedLoadout!);

    if (lastSavedData == null) {
      return;
    }

    // Build current custom positions map from Hive
    Map<int, String> currentCustomPositionsMap = {
      for (var pos in Hive.box<CustomPosition>('customPositionsBox').values)
        pos.code: pos.title
    };

    // Build saved custom positions map from loaded JSON
    Map<int, String> savedCustomPositionsMap = {
      for (var pos in (lastSavedData["customPositions"] ?? []) as List)
        pos['code']: pos['title']
    };

    // Extract saved and current data
    List<CrewMember> savedCrew = (lastSavedData["crew"]["crewMembers"] as List).map((json) => CrewMember.fromJson(json)).toList();
    List<CrewMember> currentCrew = crew.crewMembers;

    List<Gear> savedGear = (lastSavedData["crew"]["gear"] as List).map((json) => Gear.fromJson(json)).toList();
    List<Gear> currentGear = crew.gear;

    List<Gear> savedTools = (lastSavedData["crew"]["personalTools"] as List).map((json) => Gear.fromJson(json)).toList();
    List<Gear> currentTools = crew.personalTools;

    List<TripPreference> savedTripPreferences = (lastSavedData["savedPreferences"]["tripPreferences"] as List).map((json) => TripPreference.fromJson(json)).toList();
    List<TripPreference> currentTripPreferences = savedPreferences.tripPreferences;

    // Compare Differences
    Map<String, List<String>> crewChanges = _getCrewMemberDifferences(
        currentCrew,
        savedCrew,
        currentCustomPositionsMap,
        savedCustomPositionsMap
    );
    Map<String, List<String>> gearChanges = _getGearDifferences(currentGear, savedGear);
    Map<String, List<String>> toolChanges = _getToolDifferences(currentTools, savedTools);

    // Compare Trip Preferences
    List<String> missingPreferences =
        savedTripPreferences.where((saved) => !currentTripPreferences.any((current) => current.tripPreferenceName == saved.tripPreferenceName)).map((p) => p.tripPreferenceName).toList();

    List<String> newPreferences =
        currentTripPreferences.where((current) => !savedTripPreferences.any((saved) => saved.tripPreferenceName == current.tripPreferenceName)).map((p) => p.tripPreferenceName).toList();

    // Detect modified trip preferences (without specifics)
    List<String> modifiedPreferences = savedTripPreferences
        .where((saved) => currentTripPreferences.any((current) => current.tripPreferenceName == saved.tripPreferenceName && !_areTripPreferencesEqual(current, saved)))
        .map((p) => p.tripPreferenceName)
        .toList();
    // Display differences in a dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Loadout Changes',
            style: TextStyle(fontSize: AppData.miniDialogTitleTextSize, color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (crewChanges["removed"]!.isNotEmpty || crewChanges["added"]!.isNotEmpty || crewChanges["modified"]!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.people, color: AppColors.textColorPrimary, size: AppData.text18), // Crew icon
                      SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(" Crew Members", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16, fontWeight: FontWeight.bold)),
                            if (crewChanges["removed"]!.isNotEmpty) ...[
                              Text("Removed", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.red, fontWeight: FontWeight.bold)),
                              for (var name in crewChanges["removed"]!) Text('- $name', style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (crewChanges["added"]!.isNotEmpty) ...[
                              Text("Added", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.green, fontWeight: FontWeight.bold)),
                              for (var name in crewChanges["added"]!) Text('- $name', style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (crewChanges["modified"]!.isNotEmpty) ...[
                              Text("Modified", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.orange, fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: crewChanges["modified"]!.map((change) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: AppData.padding8), // Space after each entry
                                    child: Text(change, style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 5),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (gearChanges.isNotEmpty || toolChanges.isNotEmpty || missingPreferences.isNotEmpty || newPreferences.isNotEmpty || modifiedPreferences.isNotEmpty)
                    Divider(color: AppColors.textColorPrimary),
                ],
                if (gearChanges["removed"]!.isNotEmpty || gearChanges["added"]!.isNotEmpty || gearChanges["modified"]!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.work_outline, color: Colors.orange, size: AppData.text18), // Gear icon
                      SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(" Gear", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16, fontWeight: FontWeight.bold)),
                            if (gearChanges["removed"]!.isNotEmpty) ...[
                              Text("Removed", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.red, fontWeight: FontWeight.bold)),
                              for (var name in gearChanges["removed"]!) Text('- $name', style: TextStyle(color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (gearChanges["added"]!.isNotEmpty) ...[
                              Text("Added", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.green, fontWeight: FontWeight.bold)),
                              for (var name in gearChanges["added"]!) Text('- $name', style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (gearChanges["modified"]!.isNotEmpty) ...[
                              Text("Modified", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.orange, fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: gearChanges["modified"]!.map((change) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: AppData.padding8), // Space after each entry
                                    child: Text(change, style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 5),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.textColorPrimary),
                ],
                if (toolChanges["removed"]!.isNotEmpty || toolChanges["added"]!.isNotEmpty || toolChanges["modified"]!.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.handyman_outlined, color: Colors.blue, size: AppData.text18), // Tool icon
                      SizedBox(width: 5),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(" Tools", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16, fontWeight: FontWeight.bold)),
                            if (toolChanges["removed"]!.isNotEmpty) ...[
                              Text("Removed", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              for (var name in toolChanges["removed"]!) Text('- $name', style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (toolChanges["added"]!.isNotEmpty) ...[
                              Text("Added", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.green, fontWeight: FontWeight.bold)),
                              for (var name in toolChanges["added"]!) Text('- $name', style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (toolChanges["modified"]!.isNotEmpty) ...[
                              Text("Modified", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.orange, fontWeight: FontWeight.bold)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: toolChanges["modified"]!.map((change) {
                                  return Padding(
                                    padding: EdgeInsets.only(top: AppData.padding8), // Space after each entry
                                    child: Text(change, style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                                  );
                                }).toList(),
                              ),
                              SizedBox(height: 5),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(color: AppColors.textColorPrimary),
                ],
                if (missingPreferences.isNotEmpty || newPreferences.isNotEmpty || modifiedPreferences.isNotEmpty) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(FontAwesomeIcons.sliders, color: Colors.purple, size: AppData.text18), // Preferences icon
                      SizedBox(width: AppData.sizedBox8), // Space between icon and text
                      Expanded(
                        // Ensures Column takes up the correct space
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, // Aligns text to the left
                          children: [
                            Text(" Trip Preferences", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16, fontWeight: FontWeight.bold)),
                            if (missingPreferences.isNotEmpty) ...[
                              Text("Removed", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.red, fontWeight: FontWeight.bold)),
                              Text(missingPreferences.map((p) => "- $p").join("\n"), style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5), // Adds spacing between sections
                            ],
                            if (newPreferences.isNotEmpty) ...[
                              Text("Added", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.green, fontWeight: FontWeight.bold)),
                              Text(newPreferences.map((p) => "- $p").join("\n"), style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                              SizedBox(height: 5),
                            ],
                            if (modifiedPreferences.isNotEmpty) ...[
                              Text("Modified", style: TextStyle(fontSize: AppData.loadoutBodyText, color: Colors.orange, fontWeight: FontWeight.bold)),
                              Text(modifiedPreferences.map((p) => "- $p").join("\n"), style: TextStyle(fontSize: AppData.loadoutBodyText, color: AppColors.textColorPrimary)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Close", style: TextStyle(fontSize: AppData.bottomDialogTextSize, color: AppColors.textColorPrimary)),
            ),
          ],
        );
      },
    );
  }

// Helper function to load last saved timestamp
  Future<void> _loadLastSavedTimestamp(String loadoutName) async {
    Map<String, dynamic>? loadoutData = await CrewLoadoutStorage.loadLoadout(loadoutName);

    setState(() {
      lastSavedTimestamp = loadoutData?["lastSaved"] ?? "N/A"; // Default to "N/A" if missing
    });
  }

  Future<void> exportCrewData(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: CircularProgressIndicator(
            color: AppColors.fireColor,
          ),
        ),
      );

      Map<String, dynamic> exportData = {
        "crew": crew.toJson(),
        "savedPreferences": savedPreferences.toJson(),
        "customPositions": Hive.box<CustomPosition>('customPositionsBox').values.map((pos) => pos.toJson()).toList(),

      };

      String jsonData = jsonEncode(exportData);
      Directory directory = await getTemporaryDirectory();
      String formattedDate = DateFormat('MMM_dd').format(DateTime.now());
      String filePath = '${directory.path}/CrewData_$formattedDate.json';

      File file = File(filePath);
      await file.writeAsString(jsonData);

      await Future.delayed(Duration(milliseconds: 200)); // Allow UI settle

      // Dismiss loading indicator
      Navigator.of(context, rootNavigator: true).pop();

      final Size screenSize = MediaQuery.of(context).size;
      final Rect shareOrigin = Rect.fromLTWH(
        0,
        0,
        screenSize.width,
        screenSize.height / 2,
      );

      Share.shareXFiles(
        [XFile(filePath)],
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      print('Error exporting data: $e');
      Navigator.of(context, rootNavigator: true).pop(); // make sure dialog closes on error
    }
  }


  void selectFileForImport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'], // Restrict to JSON files
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      confirmDataWipe(file);
    } else {
      print("File selection canceled.");
    }
  }

  void confirmDataWipe(PlatformFile file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Warning',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: AppData.miniDialogTitleTextSize),
          ),
          content: Text(
            'Importing this file will overwrite all existing crew data (Crew Members, Gear, Tools, Trip Preferences). Proceed?',
            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the warning dialog

                // Call importCrewData() with a callback that updates UI
                importCrewData(file, () {
                  setState(() {}); // Force UI to rebuild
                });

                // Show successful save popup
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                    content: Center(
                      child: Text(
                        'Crew Imported!',
                        // Maybe change look
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: AppData.text22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
                FirebaseAnalytics.instance.logEvent(
                  name: 'crewDataFile_imported',
                  parameters: {
                    'file_name': 'nonExistent',
                  },
                );
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void importCrewData(PlatformFile file, Function updateUI) async {
    try {
      // Read file contents
      String jsonString = await File(file.path!).readAsString();
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Validate required fields
      if (!jsonData.containsKey("crew") || !jsonData.containsKey("savedPreferences")) {
        showErrorDialog("Invalid JSON format. Missing required fields.");
        FirebaseAnalytics.instance.logEvent(
          name: 'import_error',

          parameters: {
            'error_message': "Invalid JSON format. Missing required fields.",
          },
        );
        return;
      }

      // Before importing crew data — handle custom positions
      if (jsonData.containsKey("customPositions")) {
        var customBox = Hive.box<CustomPosition>('customPositionsBox');
        List<dynamic> importedCustomPositions = jsonData["customPositions"];

        for (var posJson in importedCustomPositions) {
          CustomPosition pos = CustomPosition.fromJson(posJson);

          // Only add if code not already exists (prevents duplicates)
          bool alreadyExists = customBox.values.any((p) => p.code == pos.code);
          if (!alreadyExists) {
            await customBox.add(pos);
          }
        }
      }
      // Import Crew Data
      Crew importedCrew = Crew.fromJson(jsonData["crew"]);

      // Import Trip Preferences (SavedPreferences)
      SavedPreferences importedSavedPreferences = SavedPreferences.fromJson(jsonData["savedPreferences"]);

      updateUI();
      // Clear old data
      await Hive.box<CrewMember>('crewmemberBox').clear();
      await Hive.box<Gear>('gearBox').clear();
      await Hive.box<Gear>('personalToolsBox').clear();
      await Hive.box<TripPreference>('tripPreferenceBox').clear();
      savedPreferences.deleteAllTripPreferences();

      // Save Crew Data
      var crewMemberBox = Hive.box<CrewMember>('crewmemberBox');
      for (var member in importedCrew.crewMembers) {
        await crewMemberBox.add(member);
      }

      var gearBox = Hive.box<Gear>('gearBox');
      for (var gearItem in importedCrew.gear) {
        await gearBox.add(gearItem);
      }

      var personalToolsBox = Hive.box<Gear>('personalToolsBox');
      for (var tool in importedCrew.personalTools) {
        await personalToolsBox.add(tool);
      }

      // Save Trip Preferences to Hive
      var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
      for (var tripPref in importedSavedPreferences.tripPreferences) {
        await tripPreferenceBox.add(tripPref);
      }
      savedPreferences.tripPreferences = tripPreferenceBox.values.toList();

      // Reload data from Hive
      await crew.loadCrewDataFromHive();
      await savedPreferences.loadPreferencesFromHive();

      //Check sync status after import**
      if (selectedLoadout != null) {
        await _checkSyncStatus(selectedLoadout!);
      }
      setState(() {});

      //Crew Name
    } catch (e) {
      showErrorDialog("Unexpected error during import: $e");
      FirebaseAnalytics.instance.logEvent(
        name: 'import_error',

        parameters: {
          'error_message': "$e",
        },
      );
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.red.shade900,
          title: Text(
            'Import Error',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'OK',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchYouTube() async {
    final Uri url = Uri.parse('https://www.youtube.com/playlist?list=PLc8D3YhNsr58uuDv_btNFiVRVgxtz0_5L');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
    FirebaseAnalytics.instance.logEvent(
      name: 'video_tutorials_opened',
    );
  }

  Future<void> _launchDiscord() async {
    final Uri url = Uri.parse('https://discord.gg/DxC5DTw2db');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
    FirebaseAnalytics.instance.logEvent(
      name: 'discord_launched',
    );
  }

  Future<void> _launchPrivacyPolicy() async {
    final Uri url = Uri.parse('https://dawsonnash.github.io/fire_manifesting_policies/');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
    FirebaseAnalytics.instance.logEvent(
      name: 'privacy_policy_viewed',
    );
  }

  Future<void> _launchTermsAndConditions() async {
    final Uri url = Uri.parse('https://dawsonnash.github.io/fire_manifesting_policies/terms');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
    FirebaseAnalytics.instance.logEvent(
      name: 'terms_and_conditions_viewed',
    );
  }

  Future<void> _reportBugs() async {
    final TextEditingController feedbackController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Report Bugs',
            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
          ),
          content: TextField(
            controller: feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Describe any bugs you've experienced here...",
              hintStyle: TextStyle(color: AppColors.textColorPrimary),
              filled: true,
              fillColor: AppColors.textFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textColorPrimary, width: 1),
              ),
            ),
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
              ),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  final String subject = Uri.encodeComponent('Bug Fixes');
                  final String body = Uri.encodeComponent(feedback);

                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'dev@firemanifesting.com', // Replace with your email address
                    query: 'subject=$subject&body=$body',
                  );

                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      throw 'Could not launch $emailUri';
                    }
                  } catch (e) {
                    print('Error launching email: $e');
                  }
                }

                Navigator.of(context).pop(); // Close the dialog after submission
              },
              child: Text(
                'Send',
                style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitFeedback() async {
    final TextEditingController feedbackController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Submit Feedback',
            style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
          ),
          content: TextField(
            controller: feedbackController,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: "Submit any questions or app suggestions here. The developer will review and get back to you as soon as possible.",
              hintStyle: TextStyle(color: AppColors.textColorPrimary),
              filled: true,
              fillColor: AppColors.textFieldColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.textColorPrimary, width: 1),
              ),
            ),
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
              ),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  final String subject = Uri.encodeComponent('Feedback/Questions');
                  final String body = Uri.encodeComponent(feedback);

                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'dev@firemanifesting.com', // Replace with your email address
                    query: 'subject=$subject&body=$body',
                  );

                  try {
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri);
                    } else {
                      throw 'Could not launch $emailUri';
                    }
                  } catch (e) {
                    print('Error launching email: $e');
                  }
                }

                Navigator.of(context).pop(); // Close the dialog after submission
              },
              child: Text(
                'Send',
                style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize),
              ),
            ),
          ],
        );
      },
    );
  }

  void importExportBottomSheet(BuildContext parentContext) {
    int selectedIndex = 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.textFieldColor2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Select an Option',
                          style: TextStyle(
                            fontSize: AppData.miniDialogTitleTextSize,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColorPrimary,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.info_outline, color: Colors.white, size: AppData.text24),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: AppColors.textFieldColor2,
                                title: Text(
                                  "Crew Sharing",
                                  style: TextStyle(
                                    color: AppColors.textColorPrimary,
                                    fontWeight: FontWeight.normal,
                                    fontSize: AppData.miniDialogTitleTextSize,
                                  ),
                                ),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Crew sharing allows you to share your crew data (Crew Members, Gear, and Tools) with other users. To share:\n",
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
                                      ),
                                      Text(
                                        "1. For exporting, select 'Export'. If on iOS, the file will appear in your share sheet and can be saved or AirDropped.\n",
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
                                      ),
                                      Text(
                                        "2. For importing, select 'Import' and choose the CrewData JSON file from your Files.",
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: Text("OK", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize)),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 120 * AppData.tabletScalingFactor,
                    child: CupertinoPicker(
                      itemExtent: 50 * AppData.tabletScalingFactor,
                      onSelectedItemChanged: (int index) {
                        setState(() => selectedIndex = index);
                      },
                      children:  [
                        Center(child: Text('Export', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text20))),
                        Center(child: Text('Import', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text20))),
                      ],
                    ),
                  ),
                  SizedBox(height: 60),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: AppData.bottomDialogTextSize, color: AppColors.cancelButton),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close modal first
                          await Future.delayed(Duration(milliseconds: 100)); // Allow frame to settle

                          if (selectedIndex == 0) {
                            if (crew.crewMembers.isEmpty && crew.gear.isEmpty) {
                              showDialog(
                                context: parentContext,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: AppColors.textFieldColor2,
                                    title: Text("No crew to export", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize)),
                                    content: Text("There are no Crew Members or Gear in your inventory.",
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize)),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: Text("OK", style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize)),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            } else {
                              await exportCrewData(parentContext);
                              FirebaseAnalytics.instance.logEvent(name: 'crewDataFile_exported');
                            }
                          } else {
                            selectFileForImport();
                          }
                        },
                        child: Text(
                          selectedIndex == 0 ? 'Export' : 'Import',
                          style: TextStyle(fontSize: AppData.bottomDialogTextSize, color: AppColors.saveButtonAllowableWeight),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _promptNewLoadoutName(String previousLoadout, bool isEmptyCrew, bool isEdit) {
    TextEditingController nameController = isEdit ? TextEditingController(text: previousLoadout) : TextEditingController();
    String? errorMessage;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                isEdit ? 'Edit Loadout Name' : 'Save New Loadout',
                style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    textCapitalization: TextCapitalization.words,
                    inputFormatters: [LengthLimitingTextInputFormatter(30)],
                    decoration: InputDecoration(
                      errorText: errorMessage,
                      errorStyle: TextStyle(
                        fontSize: AppData.errorText,
                        color: Colors.red,
                      ),
                      hintText: "Enter Loadout Name",
                      hintStyle: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
                    ),
                    style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Cancel", style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
                ),
                TextButton(
                  onPressed: () async {
                    String loadoutName = nameController.text.trim();

                    if (loadoutName.isNotEmpty) {
                      List<String> existingLoadouts = await CrewLoadoutStorage.getAllLoadoutNames();
                      bool nameExists = existingLoadouts.any(
                        (existingName) => existingName.toLowerCase() == loadoutName.toLowerCase(),
                      );

                      if (nameExists) {
                        if (loadoutName == previousLoadout) {
                          setDialogState(() {
                            errorMessage = "Name is unchanged";
                          });
                        } else {
                          setDialogState(() {
                            errorMessage = "Name already exists";
                          });
                        }

                        Future.delayed(Duration(seconds: 2), () {
                          setDialogState(() {
                            errorMessage = null;
                          });
                        });
                      } else {
                        if (isEdit) {
                          bool success = await CrewLoadoutStorage.renameLoadout(previousLoadout, loadoutName);
                          if (success) {
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setString('last_selected_loadout', loadoutName);

                            setState(() {
                              if (selectedLoadout == previousLoadout) {
                                selectedLoadout = loadoutName; // Keep the selection
                              }
                            });

                            await _loadLoadoutNames();
                          }
                        } else {
                          _saveNewLoadout(loadoutName, isEmptyCrew);
                          FirebaseAnalytics.instance.logEvent(
                            name: 'crew_loadout_built',

                            parameters: {
                              'loadout_name': loadoutName.trim(),
                              'isEmptyCrew': isEmptyCrew ? 'yes' : 'no',
                              'crew_crewmember_length': crew.crewMembers.length.toString(),
                              'crew_gear_length': crew.gear.length.toString(),
                            },
                          );
                        }
                        Navigator.of(context).pop();
                      }
                    } else {
                      setDialogState(() {
                        errorMessage = "Name cannot be empty";
                      });

                      Future.delayed(Duration(seconds: 2), () {
                        setDialogState(() {
                          errorMessage = null;
                        });
                      });
                    }
                  },
                  child: Text("Save", style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveNewLoadout(String loadoutName, bool isEmptyCrew) async {
    String timestamp = DateFormat('EEE, dd MMM yy, h:mm a').format(DateTime.now());
    // Export all custom positions to JSON
    var customPositionsBox = Hive.box<CustomPosition>('customPositionsBox');
    List<Map<String, dynamic>> customPositionsJson = customPositionsBox.values.map((pos) => pos.toJson()).toList();

    Map<String, dynamic> loadoutData = isEmptyCrew
        ? {
            "crew": {
              "crewMembers": [], // Empty list instead of null
              "gear": [],
              "personalTools": [],
              "totalCrewWeight": 0.0
            },
            "savedPreferences": {
              "tripPreferences": [] // Empty trip preferences list
            },
      "customPositions": customPositionsJson,

      "lastSaved": timestamp,
          }
        : {
            "crew": crew.toJson(),
            "savedPreferences": savedPreferences.toJson(),
      "customPositions": customPositionsJson,
      "lastSaved": timestamp,
          };

    await CrewLoadoutStorage.saveLoadout(loadoutName, loadoutData);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_loadout', loadoutName); // Save it as last used

    // Refresh dropdown and select the new loadout
    setState(() {
      loadoutNames.add(loadoutName); // Add the new loadout to the list
      selectedLoadout = loadoutName; // Set it as the selected option
      lastSavedTimestamp = timestamp; // UI timestamp
    });

    // Check if it's an empty loadout
    if (isEmptyCrew) {
      await _loadSelectedLoadout(loadoutName);
    } else {
      await _checkSyncStatus(loadoutName);
    }

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Saved $loadoutName',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: AppData.text22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _updateCurrentLoadout(String loadoutName) async {
    String timestamp = DateFormat('EEE, dd MMM yy, h:mm a').format(DateTime.now());

    // Export all custom positions to JSON
    var customPositionsBox = Hive.box<CustomPosition>('customPositionsBox');
    List<Map<String, dynamic>> customPositionsJson = customPositionsBox.values.map((pos) => pos.toJson()).toList();

    Map<String, dynamic> loadoutData = {
      "crew": crew.toJson(),
      "savedPreferences": savedPreferences.toJson(),
      "customPositions": customPositionsJson,
      "lastSaved": timestamp, // Update timestamp
    };
    await CrewLoadoutStorage.saveLoadout(loadoutName, loadoutData);

    setState(() {
      lastSavedTimestamp = timestamp; //Update UI timestamp
    });

    // Recheck sync
    await _checkSyncStatus(loadoutName);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Loadout Updated!',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: AppData.text22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _deleteLoadout(String loadoutName) async {
    await CrewLoadoutStorage.deleteLoadout(loadoutName);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_selected_loadout'); // Remove from saved preferences

    setState(() {
      loadoutNames.remove(loadoutName); // Remove from list

      if (selectedLoadout == loadoutName) {
        // If the deleted loadout was the active one, reset selection
        selectedLoadout = null;
        lastSavedTimestamp = "N/A";
        isOutOfSync = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Loadout Deleted!',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: AppData.text22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _applyLoadout(String loadoutName, Map<String, dynamic> loadoutData) async {
    try {

      // First add custom positions if they dont already exist
      if (loadoutData.containsKey("customPositions")) {
        List<dynamic> importedCustomPositions = loadoutData["customPositions"];
        var customBox = Hive.box<CustomPosition>('customPositionsBox');

        for (var posJson in importedCustomPositions) {
          CustomPosition importedPosition = CustomPosition.fromJson(posJson);

          bool exists = customBox.values.any((existing) => existing.code == importedPosition.code);
          if (!exists) {
            await customBox.add(importedPosition);
          }
        }
      }

      // Convert JSON back to objects
      Crew importedCrew = Crew.fromJson(loadoutData["crew"]);
      SavedPreferences importedPreferences = SavedPreferences.fromJson(loadoutData["savedPreferences"]);

      // Save the last selected loadout persistently
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_selected_loadout', loadoutName);

      // Clear existing data
      await Hive.box<CrewMember>('crewmemberBox').clear();
      await Hive.box<Gear>('gearBox').clear();
      await Hive.box<Gear>('personalToolsBox').clear();
      await Hive.box<TripPreference>('tripPreferenceBox').clear();
      savedPreferences.deleteAllTripPreferences();

      // Save new Crew Data
      var crewMemberBox = Hive.box<CrewMember>('crewmemberBox');
      for (var member in importedCrew.crewMembers) {
        await crewMemberBox.add(member);
      }

      var gearBox = Hive.box<Gear>('gearBox');
      for (var gearItem in importedCrew.gear) {
        await gearBox.add(gearItem);
      }

      var personalToolsBox = Hive.box<Gear>('personalToolsBox');
      for (var tool in importedCrew.personalTools) {
        await personalToolsBox.add(tool);
      }

      // Save new Trip Preferences
      var tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
      for (var tripPref in importedPreferences.tripPreferences) {
        await tripPreferenceBox.add(tripPref);
      }
      savedPreferences.tripPreferences = tripPreferenceBox.values.toList();

      // Reload data from Hive
      await crew.loadCrewDataFromHive();
      await savedPreferences.loadPreferencesFromHive();

      // Update last saved timestamp
      await _loadLastSavedTimestamp(loadoutName);

      // Re-check sync status after applying the loadout
      await _checkSyncStatus(loadoutName);
      // Update state
      setState(() {
        selectedLoadout = loadoutName;
      });
    } catch (e) {
      showErrorDialog("Error loading loadout: $e");
    }
  }

  Future<void> _loadSelectedLoadout(String loadoutName) async {
    // Fetch the saved loadout
    Map<String, dynamic>? loadoutData = await CrewLoadoutStorage.loadLoadout(loadoutName);

    if (loadoutData == null) {
      showErrorDialog("Loadout not found.");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_selected_loadout', loadoutName); // Save the selection persistently

    await _applyLoadout(loadoutName, loadoutData);
  }

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
      appBar: AppBar(
        title: Center(
          child: Text(
            'Settings',
            style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
          ),
        ),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Background color for dark mode
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                    ? Stack(
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Blur effect
                            child: Image.asset(
                              'assets/images/logo1.png',
                              fit: BoxFit.cover, // Cover the entire background
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Container(
                            color: AppColors.logoImageOverlay, // Semi-transparent overlay
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ],
                      )
                    : null) // No image if background is disabled
                : Stack(
                    children: [
                      ImageFiltered(
                        imageFilter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0), // Always display in light mode
                        child: Image.asset(
                          'assets/images/logo1.png',
                          fit: BoxFit.cover, // Cover the entire background
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      Container(
                        color: AppColors.logoImageOverlay, // Semi-transparent overlay
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ],
                  ),
          ),
          Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                children: [
                  // Help Title
                  ListTile(
                    leading: Icon(Icons.help_outline, color: Colors.white, size: AppData.text20),
                    title: Text(
                      'HELP',
                      style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                    ),
                  ),

                  // Help Section
                  Padding(
                    padding: const EdgeInsets.only(left: 48.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => QuickGuide(),
                                settings: RouteSettings(name: 'QuickGuidePage'),
                              ),
                            );
                          },
                          child: Text('Quick Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: AppData.text18)),
                        ),
                        TextButton(
                          onPressed: _launchYouTube,
                          child: Text('Video Tutorials', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: AppData.text18)),
                        ),
                        TextButton(
                          onPressed: _launchDiscord,
                          child: Text('Support Chat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: AppData.text18)),
                        ),
                        TextButton(
                          onPressed: _reportBugs,
                          child: Text('Report Bugs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: AppData.text18)),
                        ),
                        TextButton(
                          onPressed: _submitFeedback,
                          child: Text('Submit Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: AppData.text18)),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // App Settings Title
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.white, size: AppData.text20),
                    title: Text(
                      'APP SETTINGS',
                      style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                    ),
                  ),

                  // App Settings Sectioin
                  Padding(
                    padding: EdgeInsets.only(left: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display
                        ExpansionTile(
                          title: Text(
                            'Display',
                            style: TextStyle(fontSize: AppData.text18, color: Colors.white), // White text for the label
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                            color: Colors.white, // Match the arrow color with the text color
                            size: AppData.text24, // Set a fixed size for consistency
                          ),
                          children: [
                            // Dark Mode Toggle
                            // ListTile(
                            //   title: const Text(
                            //     'Dark Mode',
                            //     style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                            //   ),
                            //   trailing: Switch(
                            //     value: isDarkMode,
                            //     onChanged: (value) {
                            //       widget.onThemeChanged(value); // Notify parent widget
                            //       setState(() {
                            //         isDarkMode = value;
                            //         if (!isDarkMode) {
                            //           widget.onBackgroundImageChange(value); // Notify parent widget
                            //           enableBackgroundImage = false;
                            //           ThemePreferences.setBackgroundImagePreference(value);
                            //         }
                            //         ThemePreferences.setTheme(value); // Save dark mode preference
                            //       });
                            //     },
                            //     activeColor: Colors.green,
                            //     inactiveThumbColor: Colors.grey,
                            //     inactiveTrackColor: Colors.white24,
                            //   ),
                            // ),
                            // Enable Background Image Toggle (Visible only if Dark Mode is ON)
                            //  if (isDarkMode)
                            ListTile(
                              title: Text(
                                'Enable Background Image',
                                style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                              ),
                              trailing: Switch(
                                value: enableBackgroundImage,
                                onChanged: (value) {
                                  widget.onBackgroundImageChange(value); // Notify parent widget
                                  setState(() {
                                    enableBackgroundImage = value;
                                  });
                                  ThemePreferences.setBackgroundImagePreference(value); // Save preference

                                  if (value == true) {
                                    FirebaseAnalytics.instance.logEvent(
                                      name: 'background_image_enabled',

                                    );
                                  }
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.white24,
                              ),
                            ),
                            // Text Scale Slider
                            ListTile(
                              title: Text(
                                'Text Size',
                                style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                              ),
                              subtitle: Row(
                                children: [
                                  Text('Aa', style: TextStyle(fontSize: 14.8, color: Colors.white70)),
                                  Expanded(
                                    child: Slider(
                                      value: widget.textScale,
                                      onChanged: (value) {
                                        setState(() {
                                            widget.onTextScaleChange(value);
                                            ThemePreferences.setTextScale(value);
                                        });
                                      },
                                      min: AppData.minTextFactor,
                                      max: AppData.maxTextFactor,
                                      divisions: 3, // 4 options total
                                      activeColor: AppColors.fireColor,
                                      inactiveColor: Colors.white30,
                                    ),
                                  ),
                                  Text('Aa', style: TextStyle(fontSize: 23.4, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Crew Details
                        ExpansionTile(
                          title: Row(
                            children: [
                              Text(
                                'Crew Details',
                                style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline, // Info icon
                                  color: Colors.white,
                                  size: AppData.text22, // Adjust size if needed
                                ),
                                onPressed: () {
                                  // Show an info dialog or tooltip when clicked
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        backgroundColor: AppColors.textFieldColor2,
                                        title: Text(
                                          "Crew Details Info",
                                          style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.miniDialogTitleTextSize, ),
                                        ),
                                        content:
                                            Text("This information is used to fill in the respective portions in the generated PDF manifests.", style: TextStyle(fontSize: AppData.miniDialogBodyTextSize,color: AppColors.textColorPrimary)),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child: Text(
                                              "OK",
                                              style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize,),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                            color: Colors.white, // Match the arrow color with the text color
                            size: AppData.text24, // Set a fixed size for consistency
                          ),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Crew Name Section
                                    ExpansionTile(
                                      title: Text(
                                        'Crew Name',
                                        style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                                      ),
                                      trailing: Icon(
                                        Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                                        color: Colors.white, // Match the arrow color with the text color
                                        size: AppData.text24, // Set a fixed size for consistency
                                      ),
                                      children: [
                                        ListTile(
                                          title: Container(
                                            width: double.infinity, // Ensure it takes full width
                                            decoration: BoxDecoration(
                                              color: AppColors.settingsTabs,
                                              border: Border.all(
                                                color: Colors.white, // Outline color
                                                width: 1, // Outline thickness
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8, right: 8),
                                              child: TextField(
                                                controller: crewNameController,
                                                // Pre-fill with current crew name
                                                style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(30),
                                                ],
                                                textCapitalization: TextCapitalization.words,
                                                decoration: InputDecoration(
                                                  hintText: 'Enter Crew Name',
                                                  hintStyle: const TextStyle(color: Colors.white54),
                                                  enabledBorder: const UnderlineInputBorder(
                                                    borderSide: BorderSide(color: Colors.white54),
                                                  ),
                                                  focusedBorder: UnderlineInputBorder(
                                                    borderSide: BorderSide(color: AppColors.fireColor),
                                                  ),
                                                ),
                                                onSubmitted: (value) async {
                                                  String trimmedName = value.trim();
                                                  setState(() {
                                                    if (value.trim().isNotEmpty) {
                                                      widget.onCrewNameChanged(value.trim()); // Notify parent widget of the change
                                                    }
                                                  });
                                                  // Call a callback or save preference
                                                  ThemePreferences.setCrewName(value.trim());

                                                  if (trimmedName.isNotEmpty) {
                                                    await FirebaseAnalytics.instance.setUserProperty(
                                                      name: 'crew_name',
                                                      value: trimmedName,
                                                    );

                                                    // Add this to make sure it shows up in DebugView
                                                    await FirebaseAnalytics.instance.logEvent(
                                                      name: 'crew_name_set',
                                                      parameters: {
                                                        'value': trimmedName,
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // User's Name
                                    ExpansionTile(
                                      title: Text(
                                        'Your Name',
                                        style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                                      ),
                                      trailing: Icon(
                                        Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                                        color: Colors.white, // Match the arrow color with the text color
                                        size: AppData.text24, // Set a fixed size for consistency
                                      ),
                                      children: [
                                        ListTile(
                                          title: Container(
                                            width: double.infinity, // Ensure it takes full width
                                            decoration: BoxDecoration(
                                              color: AppColors.settingsTabs,
                                              border: Border.all(
                                                color: Colors.white, // Outline color
                                                width: 1, // Outline thickness
                                              ),
                                            ),
                                            child: Padding(
                                              padding: EdgeInsets.only(left: 8, right: 8),
                                              child: TextField(
                                                controller: userNameController,
                                                // Pre-fill with current user name
                                                style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(30),
                                                ],
                                                textCapitalization: TextCapitalization.words,
                                                decoration: InputDecoration(
                                                  hintText: 'Enter Your Name',
                                                  hintStyle: const TextStyle(color: Colors.white54),
                                                  enabledBorder: const UnderlineInputBorder(
                                                    borderSide: BorderSide(color: Colors.white54),
                                                  ),
                                                  focusedBorder: UnderlineInputBorder(
                                                    borderSide: BorderSide(color: AppColors.fireColor),
                                                  ),
                                                ),
                                                onSubmitted: (value) async {
                                                  String trimmedName = value.trim();

                                                  setState(() {
                                                    if (value.trim().isNotEmpty) {
                                                      widget.onUserNameChanged(value.trim());
                                                    }
                                                  });
                                                  // Call a callback or save preference
                                                  ThemePreferences.setUserName(value.trim());

                                                  if (trimmedName.isNotEmpty) {
                                                    await FirebaseAnalytics.instance.setUserProperty(
                                                      name: 'user_name',
                                                      value: trimmedName,
                                                    );

                                                    // Add this to make sure it shows up in DebugView
                                                    await FirebaseAnalytics.instance.logEvent(
                                                      name: 'user_name_set',
                                                      parameters: {
                                                        'value': trimmedName,
                                                      },
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),

                        // External Manifesting Settings
                        ExpansionTile(
                          title: Text(
                            'External Manifesting',
                            style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: AppData.text24,
                          ),
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Safety Buffer Section
                                ExpansionTile(
                                  title: Text(
                                    'Safety Buffer',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: AppData.text18,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white,
                                    size: AppData.text24,
                                  ),
                                  children: [
                                    ListTile(
                                      title: Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: AppColors.settingsTabs,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: 8),
                                          child: KeyboardActions(
                                            config: keyboardActionsConfig(
                                              focusNodes: [_focusNode],
                                            ),
                                            disableScroll: true,
                                            child: TextField(
                                              focusNode: _focusNode,
                                              controller: safetyBufferController,
                                              // Pre-fill with current user name
                                              style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                                              keyboardType: TextInputType.number,
                                              textInputAction: TextInputAction.done,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(3),
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],
                                              decoration: InputDecoration(
                                                hintText: 'Enter Safety Buffer (lb)',
                                                hintStyle: const TextStyle(color: Colors.white54),
                                                enabledBorder: const UnderlineInputBorder(
                                                  borderSide: BorderSide(color: Colors.white54),
                                                ),
                                                focusedBorder: UnderlineInputBorder(
                                                  borderSide: BorderSide(color: AppColors.fireColor),
                                                ),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  int? parsedValue = int.tryParse(value.trim());
                                                  if (parsedValue != null) {
                                                    widget.onSafetyBufferChange(parsedValue);
                                                    ThemePreferences.setSafetyBuffer(parsedValue);

                                                  }
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Load Accoutrements Styled Like a Header (Aligned with Safety Buffer)
                                // Padding(
                                //   padding: EdgeInsets.only(left: 16, top: 8, bottom: 8), // Adjust left padding to match ExpansionTile
                                //   child: GestureDetector(
                                //     onTap: () {
                                //       // Bottom modal here like personal tools
                                //     },
                                //     child: Row(
                                //       children: [
                                //         Expanded(
                                //           child: Row(
                                //             children: [
                                //               Text(
                                //                 'Load Accoutrements ',
                                //                 style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                                //               ),
                                //               IconButton(
                                //                 icon: Icon(
                                //                   Icons.info_outline, // Info icon
                                //                   color: Colors.white,
                                //                   size: AppData.text22, // Adjust size if needed
                                //                 ),
                                //                 onPressed: () {
                                //                   showDialog(
                                //                     context: context,
                                //                     builder: (BuildContext context) {
                                //                       return AlertDialog(
                                //                         backgroundColor: AppColors.textFieldColor2,
                                //                         title: Text(
                                //                           "Load Accoutrements Info",
                                //                           style: TextStyle(color: AppColors.textColorPrimary),
                                //                         ),
                                //                         content: Text(
                                //                             "These are items that are included in each external cargo manifest (per net/sling load). These items are necessary for sling operations, e.g., cargo net, lead line, swivel. They are automatically included into the weight considerations when you make an external trip.",
                                //                             style: TextStyle(color: AppColors.textColorPrimary)),
                                //                         actions: [
                                //                           TextButton(
                                //                             onPressed: () {
                                //                               Navigator.of(context).pop(); // Close the dialog
                                //                             },
                                //                             child: Text(
                                //                               "OK",
                                //                               style: TextStyle(color: AppColors.textColorPrimary, fontSize: ),
                                //                             ),
                                //                           ),
                                //                         ],
                                //                       );
                                //                     },
                                //                   );
                                //                 },
                                //               ),
                                //             ],
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Crew Loadout Title
                  ListTile(
                    leading: Icon(Icons.swap_horiz, color: Colors.white, size: AppData.text20),
                    title: Text(
                      'CREW LOADOUTS',
                      style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                    ),
                  ),

                  // Crew Loadout Selector
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppData.padding16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Dropdown Container
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: EdgeInsets.symmetric(horizontal: AppData.padding8),
                                decoration: BoxDecoration(
                                  color: AppColors.textFieldColor,
                                  borderRadius: BorderRadius.circular(4.0),
                                  border: Border.all(color: AppColors.borderPrimary, width: 2.0),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                      dropdownColor: AppColors.textFieldColor2,
                                      value: selectedLoadout,
                                      hint: Text(
                                        'Select a Loadout',
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16,),
                                      ),
                                      style: TextStyle(
                                        color: AppColors.textColorPrimary,
                                        fontSize: AppData.text16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      iconEnabledColor: AppColors.textColorPrimary,
                                      itemHeight: null,
                                      isExpanded: true,
                                      // Ensures the dropdown fills available space
                                      items: [
                                        ...loadoutNames.map((String loadout) {
                                          return DropdownMenuItem<String>(
                                            value: loadout,
                                            child: GestureDetector(
                                              onLongPress: () {
                                                _promptNewLoadoutName(loadout, false, true); // Open rename dialog
                                              },
                                              child: Container(width: double.infinity, child: Text(loadout, style: TextStyle(color: AppColors.textColorPrimary))),
                                            ),
                                          );
                                        }),
                                        // **Reset to Last Saved (Only appears if out of sync)**
                                        if (isOutOfSync)
                                          DropdownMenuItem<String>(
                                            value: 'Reset Last',
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.refresh, color: Colors.orange, size: AppData.text20), // Reset icon
                                                  SizedBox(width: AppData.sizedBox8),
                                                  Text('Reset to Last Saved', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.normal)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        if (selectedLoadout != null)
                                          DropdownMenuItem<String>(
                                            value: 'Delete Current Loadout',
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,

                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete_forever, color: Colors.red, size: AppData.text20), // Reset icon
                                                  SizedBox(width: AppData.sizedBox8),
                                                  Text('Delete Current Loadout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.normal)),
                                                ],
                                              ),
                                            ),
                                          ),
                                        // Save Current Loadout Option
                                        DropdownMenuItem<String>(
                                          value: 'Save Current',
                                          child: Row(
                                            children: [
                                              Icon(Icons.save_outlined, color: Colors.green, size: AppData.text20), // Save icon
                                              SizedBox(width: AppData.sizedBox8), // Space between icon and text
                                              Text('Save New', style: TextStyle(color: Colors.green, fontWeight: FontWeight.normal)),
                                            ],
                                          ),
                                        ),
                                        // Save Empty Crew (Start Fresh)
                                        DropdownMenuItem<String>(
                                          value: 'Start Empty',
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Row(
                                              children: [
                                                Icon(Icons.add, color: Colors.blue, size: AppData.text20), // Fresh start icon
                                                SizedBox(width: AppData.sizedBox8),
                                                Text('Start Empty Crew', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.normal)),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: (String? newValue) async {
                                        String? previousLoadout = selectedLoadout;
                                        if (newValue == 'Delete Current Loadout') {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                  'Confirm Deletion',
                                                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary, fontSize: AppData.miniDialogTitleTextSize),
                                                ),
                                                content: Text(
                                                  'Are you sure you want to delete this loadout ($selectedLoadout)?',
                                                  style: TextStyle(fontSize: AppData.miniDialogBodyTextSize, color: AppColors.textColorPrimary),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(); // Close the dialog without deleting
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize, ),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      // Perform deletion
                                                      _deleteLoadout(selectedLoadout!);
                                                      // Close the dialogs
                                                      Navigator.of(context).pop(); // Close confirmation dialog
                                                    },
                                                    child: Text(
                                                      'Delete',
                                                      style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                          return;
                                        }
                                        if (newValue == 'Reset Last') {
                                          if (selectedLoadout != null) {
                                            // Confirm reset before applying
                                            bool? confirmed = await showDialog(
                                              context: context,
                                              barrierDismissible: true, // Allows tapping outside to cancel
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: AppColors.textFieldColor2,
                                                  title: Text(
                                                    'Confirm Reset',
                                                    style: TextStyle(fontSize: AppData.miniDialogTitleTextSize, color: Colors.red, fontWeight: FontWeight.bold),
                                                  ),
                                                  content: Text(
                                                    'Resetting will revert your crew loadout to the last saved version. This will erase any unsaved changes. Proceed?',
                                                    style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize, ),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(false); // Cancel reset
                                                      },
                                                      child: Text(
                                                        'Cancel',
                                                        style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(true); // Confirm reset
                                                      },
                                                      child: Text(
                                                        'Reset',
                                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.bottomDialogTextSize, ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            if (confirmed == true) {
                                              // Apply reset (reload last saved loadout)
                                              await _loadSelectedLoadout(selectedLoadout!);
                                              setState(() {
                                                isOutOfSync = false; // Now back in sync
                                              });
                                            }
                                          }
                                          return;
                                        }
                                        if (newValue == 'Save Current') {
                                          _promptNewLoadoutName(previousLoadout ?? "New Loadout", false, false);
                                          return;
                                        }
                                        if (newValue == 'Start Empty') {
                                          if (isOutOfSync) {
                                            // Ask for confirmation before switching
                                            bool? confirmed = await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: AppColors.textFieldColor2,
                                                  title: Text(
                                                    'Confirm Start Empty Crew',
                                                    style: TextStyle(fontSize: AppData.miniDialogTitleTextSize,color: Colors.red, fontWeight: FontWeight.bold),
                                                  ),
                                                  content: Text(
                                                    'Starting a new empty crew will erase any recent changes made to your current crew loadout.'
                                                    'This action is irreversible. Proceed?',
                                                    style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize,),
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(false); // Return false to cancel
                                                      },
                                                      child: Text(
                                                        'Cancel',
                                                        style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(true); // Return true to confirm
                                                      },
                                                      child: Text(
                                                        'Confirm',
                                                        style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );

                                            // If the user cancels, restore the previous selection
                                            if (confirmed == false || confirmed == null) {
                                              setState(() {
                                                selectedLoadout = previousLoadout;
                                              });
                                              return;
                                            }
                                          }
                                          // Pass true for isEmptyCrew -> Creates empty crew loadout
                                          _promptNewLoadoutName(previousLoadout ?? "New Loadout", true, false);
                                          return;
                                        }
                                        if (newValue == null || (newValue == previousLoadout)) {
                                          return;
                                        }

                                        // Standard Switching
                                        if (isOutOfSync) {
                                          // Ask for confirmation before switching
                                          bool? confirmed = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                  'Confirm Switch',
                                                  style: TextStyle(fontSize: AppData.miniDialogTitleTextSize,color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                                content: Text(
                                                  'Switching to the loadout, $newValue, will erase any recent changes made to your current crew loadout.'
                                                  'This action is irreversible. Proceed?',
                                                  style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize, ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(false); // Return false to cancel
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(true); // Return true to confirm
                                                    },
                                                    child: Text(
                                                      'Confirm',
                                                      style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          // If the user cancels, restore the previous selection
                                          if (confirmed == false || confirmed == null) {
                                            setState(() {
                                              selectedLoadout = previousLoadout;
                                            });
                                            return;
                                          }
                                        }
                                        if (previousLoadout == null) {
                                          // Ask for confirmation before switching
                                          bool? confirmed = await showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: AppColors.textFieldColor2,
                                                title: Text(
                                                  'Confirm Switch',
                                                  style: TextStyle(fontSize: AppData.miniDialogTitleTextSize,color: Colors.red, fontWeight: FontWeight.bold),
                                                ),
                                                content: Text(
                                                  'Switching to the loadout, $newValue, will erase your current crew data which is not saved to any loadouts.'
                                                  'This action is irreversible. Proceed?',
                                                  style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize, ),
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(false); // Return false to cancel
                                                    },
                                                    child: Text(
                                                      'Cancel',
                                                      style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context).pop(true); // Return true to confirm
                                                    },
                                                    child: Text(
                                                      'Confirm',
                                                      style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          );

                                          // If the user cancels, restore the previous selection
                                          if (confirmed == false || confirmed == null) {
                                            setState(() {
                                              selectedLoadout = previousLoadout;
                                            });
                                            return;
                                          }
                                        }

                                        await _loadSelectedLoadout(newValue);

                                        // Now update the UI
                                        setState(() {
                                          selectedLoadout = newValue;
                                        });
                                      }),
                                ),
                              ),
                            ),

                            SizedBox(width: 10), // Space between dropdown and buttons

                            // Sync Button
                            Tooltip(
                              message: "Update",
                              child: IconButton(
                                icon: Transform(
                                  alignment: Alignment.center,
                                  transform: Matrix4.rotationY(math.pi), // Flips the icon horizontally
                                  child: Icon(
                                    Icons.sync,
                                    color: (selectedLoadout != null && isOutOfSync) ? Colors.green : Colors.grey,
                                    size: AppData.text32,
                                  ),
                                ),

                                onPressed: (selectedLoadout != null && isOutOfSync)
                                    ? () async {
                                        bool? confirmed = await showDialog(
                                          context: context,
                                          barrierDismissible: true, // Allows tapping outside to dismiss
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              backgroundColor: AppColors.textFieldColor2,
                                              title: Text(
                                                'Confirm Update',
                                                style: TextStyle(fontSize: AppData.miniDialogTitleTextSize, color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
                                              ),
                                              content: Text(
                                                'Updating this loadout will overwrite all previously saved crew data (Crew Members, Gear, Trip Preferences) '
                                                'from $lastSavedTimestamp with your current crew data. This action is irreversible. Proceed?',
                                                style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.miniDialogBodyTextSize, ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(false); // Return false to cancel
                                                  },
                                                  child: Text(
                                                    'Cancel',
                                                    style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.of(context).pop(true); // Return true to confirm
                                                    FirebaseAnalytics.instance.logEvent(
                                                      name: 'crew_loadout_synced',
                                                    );
                                                  },
                                                  child: Text(
                                                    'Confirm',
                                                    style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        // If the user cancels (taps outside or presses cancel), do nothing
                                        if (confirmed == null || !confirmed) {
                                          return;
                                        }

                                        // If confirmed, proceed with updating the loadout
                                        await _updateCurrentLoadout(selectedLoadout!);
                                      }
                                    : null, // Button is disabled if loadout is null or already in sync
                              ),
                            ),
                          ],
                        ),
                        if (selectedLoadout != null && selectedLoadout!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (isOutOfSync) {
                                        _showSyncDifferencesDialog();
                                      }
                                    },
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        children: [
                                          Icon(
                                            !isOutOfSync ? Icons.check : Icons.sync_disabled_outlined,
                                            color: !isOutOfSync ? Colors.green : Colors.red,
                                            size: AppData.text22,
                                          ),
                                          Text(
                                            ' Last Updated: $lastSavedTimestamp ',
                                            style: TextStyle(
                                              fontSize: AppData.text14,
                                              color: isOutOfSync ? Colors.red : Colors.green.withOpacity(0.8),
                                              fontWeight: isOutOfSync ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                          if (isOutOfSync)
                                            Icon(
                                              Icons.info_outline,
                                              color: Colors.red,
                                              size: AppData.text22,
                                            ),
                                        ],
                                      ),
                                    )
                                  
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Share data
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => importExportBottomSheet(context),
                        icon: Icon(Icons.people_outline_rounded, color: Colors.white, size: AppData.text20),
                      ),
                      TextButton(
                        onPressed: () => importExportBottomSheet(context),
                        child: Text('Crew Sharing', style: TextStyle(color: Colors.white, fontSize: AppData.text18)),
                      ),
                    ],
                  ),

                  Divider(color: Colors.white),

                  // Legal Section
                  ListTile(
                    leading: Icon(Icons.gavel, color: Colors.white, size: AppData.text20),
                    title: Text(
                      'LEGAL',
                      style: TextStyle(fontSize: AppData.text18, color: Colors.white),
                    ),
                  ),
                  GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () {
                              _launchTermsAndConditions();
                            },
                            child: Text(
                              'Terms and Conditions',
                              style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 48.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: _launchPrivacyPolicy,
                            child: Text(
                              'Privacy Policy',
                              style: TextStyle(color: Colors.white, fontSize: AppData.text18),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
