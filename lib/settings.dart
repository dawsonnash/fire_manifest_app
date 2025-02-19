import 'dart:ui';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/Data/trip_preferences.dart';
import 'package:fire_app/quick_guide.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'CodeShare/colors.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'Data/crew.dart';
import 'package:file_picker/file_picker.dart';

import 'Data/crew_loadout.dart';
import 'Data/crewmember.dart';
import 'Data/gear.dart';

class SettingsView extends StatefulWidget {
  final bool isDarkMode;
  final bool enableBackgroundImage;
  final Function(bool) onThemeChanged;
  final Function(bool) onBackgroundImageChange;
  final String crewName;
  final String userName;
  final Function(String) onCrewNameChanged;
  final Function(String) onUserNameChanged;

  const SettingsView(
      {super.key,
      required this.isDarkMode,
      required this.onThemeChanged,
      required this.enableBackgroundImage,
      required this.onBackgroundImageChange,
      required this.crewName,
      required this.userName,
      required this.onCrewNameChanged,
      required this.onUserNameChanged});

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {
  late bool isDarkMode;
  late bool enableBackgroundImage;
  late TextEditingController crewNameController;
  late TextEditingController userNameController;
  List<String> loadoutNames = [];
  String? selectedLoadout;
  String lastSavedTimestamp = "N/A"; // Default value
  bool isOutOfSync = false; // Tracks sync status of current crew loadout vs current crew data

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    enableBackgroundImage = widget.enableBackgroundImage;
    crewNameController = TextEditingController(text: widget.crewName); // Initialize with the current crew name
    userNameController = TextEditingController(text: widget.userName); // Initialize with the current user name

    _loadLoadoutNames().then((_) {
      if (selectedLoadout != null) {
        _checkSyncStatus(selectedLoadout!); // Check sync status ONCE when Settings opens
      }
    });  }

  @override
  void dispose() {
    crewNameController.dispose(); // Dispose the controller to free resources
    userNameController.dispose(); // Dispose the controller to free resources
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



  Future<void> _checkSyncStatus(String loadoutName) async {
    Map<String, dynamic>? lastSavedData = await CrewLoadoutStorage.loadLoadout(loadoutName);

    if (lastSavedData == null) {
      setState(() {
        isOutOfSync = true; // If no saved data, mark as out of sync
      });
      return;
    }

    // Convert saved crew and preferences to JSON
    String lastSavedCrewJson = jsonEncode(lastSavedData["crew"]);
    String lastSavedPreferencesJson = jsonEncode(lastSavedData["savedPreferences"]);

    // Convert current crew and preferences to JSON
    Map<String, dynamic> currentCrewData = {
      "crew": crew.toJson(),
      "savedPreferences": savedPreferences.toJson(),
    };
    String currentCrewJson = jsonEncode(currentCrewData["crew"]);
    String currentPreferencesJson = jsonEncode(currentCrewData["savedPreferences"]);

    // Compare Crew and Preferences JSONs
    setState(() {
      isOutOfSync = (lastSavedCrewJson != currentCrewJson) || (lastSavedPreferencesJson != currentPreferencesJson);
    });
  }


// Helper function to load last saved timestamp
  Future<void> _loadLastSavedTimestamp(String loadoutName) async {
    Map<String, dynamic>? loadoutData = await CrewLoadoutStorage.loadLoadout(loadoutName);

    setState(() {
      lastSavedTimestamp = loadoutData?["lastSaved"] ?? "N/A"; // Default to "N/A" if missing
    });
  }

  Future<void> exportCrewData() async {
    try {
      // Convert crew and saved preferences to JSON
      Map<String, dynamic> exportData = {
        "crewName": AppData.crewName,
        "crew": crew.toJson(),
        "savedPreferences": savedPreferences.toJson(),
      };

      String jsonData = jsonEncode(exportData);
      // Get directory for temporary storage
      Directory directory = await getApplicationDocumentsDirectory();

      // Get the current date in "dd_MMM" format
      String formattedDate = DateFormat('MMM_dd').format(DateTime.now());

      // Construct the file path with date suffix
      String filePath = '${directory.path}/CrewData_$formattedDate.json';

      // Write JSON data to file
      File file = File(filePath);
      await file.writeAsString(jsonData);

      // Share the file
      Share.shareXFiles([XFile(filePath)], text: 'Exported crew data');
    } catch (e) {
      print('Error exporting data: $e');
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
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Importing this file will delete all existing data besides your Saved Trips. This action is irreversible if you do not already have your data saved into a Crew Loadout. Proceed?',
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.cancelButton),
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
                  const SnackBar(
                    content: Center(
                      child: Text(
                        'Crew Imported!',
                        // Maybe change look
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    duration: Duration(seconds: 1),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.red),
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
        return;
      }

      // Import Crew Data
      Crew importedCrew = Crew.fromJson(jsonData["crew"]);

      // Import Trip Preferences (SavedPreferences)
      SavedPreferences importedSavedPreferences = SavedPreferences.fromJson(jsonData["savedPreferences"]);

      // Handle Crew Name separately
      if (jsonData.containsKey("crewName") && jsonData["crewName"].trim().isNotEmpty) {
        print("Found crewName: '${jsonData["crewName"]}'");

        AppData.crewName = jsonData["crewName"].trim(); // Update AppData

        // Notify parent widget to update UI
        widget.onCrewNameChanged(AppData.crewName);
        crewNameController.text = AppData.crewName;
      } else {
        print("crewName is missing or empty in JSON!");
      }

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

  Future<void> _reportBugs() async {
    final TextEditingController feedbackController = TextEditingController();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Report Bugs',
            style: TextStyle(color: AppColors.textColorPrimary),
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
                style: TextStyle(color: AppColors.cancelButton),
              ),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  final String subject = Uri.encodeComponent('FIRE MANIFESTING APP: Bug Fixes');
                  final String body = Uri.encodeComponent(feedback);

                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'dawsonak85@gmail.com', // Replace with your email address
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
                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
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
            style: TextStyle(color: AppColors.textColorPrimary),
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
                style: TextStyle(color: AppColors.cancelButton),
              ),
            ),
            TextButton(
              onPressed: () async {
                final feedback = feedbackController.text.trim();
                if (feedback.isNotEmpty) {
                  final String subject = Uri.encodeComponent('FIRE MANIFESTING APP: Feedback/Questions ');
                  final String body = Uri.encodeComponent(feedback);

                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'dawsonak85@gmail.com', // Replace with your email address
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
                style: TextStyle(color: AppColors.saveButtonAllowableWeight),
              ),
            ),
          ],
        );
      },
    );
  }

  void importExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedIndex = 0; // Initial selection index

        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.textFieldColor2,
            title: Row(
              children: [
                Text(
                  'Select an option',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textColorPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.info_outline, // Info icon
                    color: Colors.white,
                    size: 22, // Adjust size if needed
                  ),
                  onPressed: () {
                    // Show an info dialog or tooltip when clicked
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          backgroundColor: AppColors.textFieldColor2,
                          title: Text(
                            "Crew Sharing",
                            style: TextStyle(color: AppColors.textColorPrimary, fontWeight: FontWeight.normal),
                          ),
                          content: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min, // Prevents excessive height
                              children: [
                                Text("Crew sharing allows you to share your crew data (Crew Members, Gear, and Tools) with other users. To share:\n",
                                    style: TextStyle(color: AppColors.textColorPrimary)),
                                Text(
                                    "1. For exporting, select the 'Export' option, save to your files, and then send to the  other user. If on iOS, this can be done directly through Air Drop, but must still be saved to your files. The exported file will be be titled CrewData along with today's date and will have a .json extension.\n",
                                    style: TextStyle(color: AppColors.textColorPrimary)),
                                Text("2. For importing, select the 'Import' option and find the CrewData JSON file in your files.", style: TextStyle(color: AppColors.textColorPrimary)),
                              ],
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                              child: Text(
                                "OK",
                                style: TextStyle(color: AppColors.textColorPrimary),
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
            content: SizedBox(
              height: MediaQuery.of(context).size.height * 0.15, // Dynamic height
              child: CupertinoPicker(
                itemExtent: 50, // Height of each item in the picker
                onSelectedItemChanged: (int index) {
                  setState(() {
                    selectedIndex = index;
                  });
                },
                children: [
                  Center(child: Text('Export', style: TextStyle(fontSize: 18, color: AppColors.textColorPrimary))),
                  Center(child: Text('Import', style: TextStyle(fontSize: 18, color: AppColors.textColorPrimary))),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16, color: AppColors.cancelButton),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  // Export
                  if (selectedIndex == 0) {
                    if (crew.crewMembers.isEmpty && crew.gear.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            backgroundColor: AppColors.textFieldColor2,
                            title: Text(
                              "No crew to export",
                              style: TextStyle(color: AppColors.textColorPrimary),
                            ),
                            content: Text("There are no Crew Members or Gear in your inventory.", style: TextStyle(color: AppColors.textColorPrimary)),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                },
                                child: Text(
                                  "OK",
                                  style: TextStyle(color: AppColors.textColorPrimary),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      exportCrewData();
                    }
                  }
                  // Import
                  else {
                    selectFileForImport();
                  }
                },
                child: Text(
                  selectedIndex == 0 ? 'Export' : 'Import',
                  style: TextStyle(fontSize: 16, color: AppColors.saveButtonAllowableWeight),
                ),
              ),
            ],
          );
        });
      },
    );
  }

  void _promptNewLoadoutName() {
    TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text('Save New Loadout', style: TextStyle(color: AppColors.textColorPrimary)),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Enter Loadout Name",
              hintStyle: TextStyle(color: AppColors.textColorPrimary),
            ),
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancel", style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                String loadoutName = nameController.text.trim();
                if (loadoutName.isNotEmpty) {
                  _saveNewLoadout(loadoutName);
                  Navigator.of(context).pop();
                }
              },
              child: Text("Save", style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveNewLoadout(String loadoutName) async {
    String timestamp = DateFormat('dd MMM yy, h:mm a').format(DateTime.now());

    Map<String, dynamic> loadoutData = {
      "crew": crew.toJson(),
      "savedPreferences": savedPreferences.toJson(),
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
    //Check sync status
    await _checkSyncStatus(loadoutName);

    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Saved $loadoutName',
            // Maybe change look
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
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
    String timestamp = DateFormat('dd MMM yy, h:mm a').format(DateTime.now());

    Map<String, dynamic> loadoutData = {
      "crew": crew.toJson(),
      "savedPreferences": savedPreferences.toJson(),
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
                fontSize: 32,
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
      SnackBar(content: Text("$loadoutName deleted"), backgroundColor: Colors.red),
    );
  }


  Future<void> _applyLoadout(String loadoutName, Map<String, dynamic> loadoutData) async {
    try {
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
    String lastSaved = loadoutData.containsKey("lastSaved") ? loadoutData["lastSaved"] : "Unknown";


    // Ask for confirmation before wiping current data
    if (isOutOfSync ) {
      showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Warning',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Loading this crew will delete all existing data besides your Saved Trips. '
            'This action is irreversible if you do not already have your data saved into another Crew Loadout. Proceed?',
            style: TextStyle(color: AppColors.textColorPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cancel
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.cancelButton),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog
                await _applyLoadout(loadoutName, loadoutData);
              },
              child: Text(
                'Confirm',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    }
    else{
      // If in sync, switch immediately
      await _applyLoadout(loadoutName, loadoutData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
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
                    leading: Icon(Icons.help_outline, color: Colors.white),
                    title: const Text(
                      'HELP',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
                              MaterialPageRoute(builder: (context) => QuickGuide()),
                            );
                          },
                          child: const Text('Quick Guide', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 18)),
                        ),
                        TextButton(
                          onPressed: _reportBugs,
                          child: const Text('Report Bugs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 18)),
                        ),
                        TextButton(
                          onPressed: _submitFeedback,
                          child: const Text('Submit Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal, fontSize: 18)),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Settings Title
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.white),
                    title: const Text(
                      'APP SETTINGS',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),

                  // Settings Sectioin
                  Padding(
                    padding: EdgeInsets.only(left: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpansionTile(
                          title: Text(
                            'Display',
                            style: TextStyle(fontSize: 18, color: Colors.white), // White text for the label
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                            color: Colors.white, // Match the arrow color with the text color
                            size: 24, // Set a fixed size for consistency
                          ),
                          children: [
                            // Dark Mode Toggle
                            ListTile(
                              title: const Text(
                                'Dark Mode',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                              trailing: Switch(
                                value: isDarkMode,
                                onChanged: (value) {
                                  widget.onThemeChanged(value); // Notify parent widget
                                  setState(() {
                                    isDarkMode = value;
                                    if (!isDarkMode) {
                                      widget.onBackgroundImageChange(value); // Notify parent widget
                                      enableBackgroundImage = false;
                                      ThemePreferences.setBackgroundImagePreference(value);
                                    }
                                    ThemePreferences.setTheme(value); // Save dark mode preference
                                  });
                                },
                                activeColor: Colors.green,
                                inactiveThumbColor: Colors.grey,
                                inactiveTrackColor: Colors.white24,
                              ),
                            ),
                            // Enable Background Image Toggle (Visible only if Dark Mode is ON)
                            if (isDarkMode)
                              ListTile(
                                title: const Text(
                                  'Enable Background Image',
                                  style: TextStyle(fontSize: 18, color: Colors.white),
                                ),
                                trailing: Switch(
                                  value: enableBackgroundImage,
                                  onChanged: (value) {
                                    widget.onBackgroundImageChange(value); // Notify parent widget
                                    setState(() {
                                      enableBackgroundImage = value;
                                    });
                                    ThemePreferences.setBackgroundImagePreference(value); // Save preference
                                  },
                                  activeColor: Colors.green,
                                  inactiveThumbColor: Colors.grey,
                                  inactiveTrackColor: Colors.white24,
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
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.info_outline, // Info icon
                                  color: Colors.white,
                                  size: 22, // Adjust size if needed
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
                                          style: TextStyle(color: AppColors.textColorPrimary),
                                        ),
                                        content:
                                            Text("This information is used to fill in the respective portions in the generated PDF manifests.", style: TextStyle(color: AppColors.textColorPrimary)),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child: Text(
                                              "OK",
                                              style: TextStyle(color: AppColors.textColorPrimary),
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
                            size: 24, // Set a fixed size for consistency
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
                                        style: TextStyle(color: Colors.white, fontSize: 18),
                                      ),
                                      trailing: Icon(
                                        Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                                        color: Colors.white, // Match the arrow color with the text color
                                        size: 24, // Set a fixed size for consistency
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
                                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(30),
                                                ],
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
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    if (value.trim().isNotEmpty) {
                                                      widget.onCrewNameChanged(value.trim()); // Notify parent widget of the change
                                                    }
                                                  });
                                                  // Call a callback or save preference
                                                  ThemePreferences.setCrewName(value.trim());
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
                                        style: TextStyle(color: Colors.white, fontSize: 18),
                                      ),
                                      trailing: Icon(
                                        Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                                        color: Colors.white, // Match the arrow color with the text color
                                        size: 24, // Set a fixed size for consistency
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
                                                style: const TextStyle(color: Colors.white, fontSize: 18),
                                                inputFormatters: [
                                                  LengthLimitingTextInputFormatter(30),
                                                ],
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
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    if (value.trim().isNotEmpty) {
                                                      widget.onUserNameChanged(value.trim());
                                                    }
                                                  });
                                                  // Call a callback or save preference
                                                  ThemePreferences.setUserName(value.trim());
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
                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Legal Section
                  ListTile(
                    leading: Icon(Icons.gavel, color: Colors.white),
                    title: const Text(
                      'LEGAL',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: AppColors.textFieldColor2, // Dark grey background
                                    title: Text(
                                      'Terms and Conditions',
                                      style: TextStyle(color: AppColors.textColorPrimary, fontWeight: FontWeight.normal),
                                    ),
                                    content: SingleChildScrollView(
                                      child: Text(
                                        'The calculations provided by this app are intended for informational purposes only. '
                                        'While every effort has been made to ensure accuracy, users must independently verify and validate '
                                        'all data before relying on it for operational or decision-making purposes. The developers assume no '
                                        'liability for errors, omissions, or any outcomes resulting from the use of this app. By continuing, '
                                        'you acknowledge and accept full responsibility for reviewing and confirming all calculations.',
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: 18),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog
                                        },
                                        child: Text(
                                          'Close',
                                          style: TextStyle(color: AppColors.textColorPrimary),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'Terms and Conditions',
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Crew Loadout Title
                  ListTile(
                    leading: Icon(Icons.swap_horiz, color: Colors.white),
                    title: const Text(
                      'CREW LOADOUTS',
                      style: TextStyle(fontSize: 18, color: Colors.white),
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
                                      style: TextStyle(color: AppColors.textColorPrimary),
                                    ),
                                    style: TextStyle(
                                      color: AppColors.textColorPrimary,
                                      fontSize: AppData.text16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    iconEnabledColor: AppColors.textColorPrimary,
                                    isExpanded: true,
                                    // Ensures the dropdown fills available space
                                    items: [
                                      ...loadoutNames.map((String loadout) {
                                        return DropdownMenuItem<String>(
                                          value: loadout,
                                          child: Text(loadout, style: TextStyle(color: AppColors.textColorPrimary)),
                                        );
                                      }),
                                      DropdownMenuItem<String>(
                                        value: 'Save New',
                                        child: Text('+ Save New', style: TextStyle(color: Colors.green, fontWeight: FontWeight.normal)),
                                      ),
                                    ],
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        if (newValue == 'Save New') {
                                          _promptNewLoadoutName();
                                        } else {
                                          selectedLoadout = newValue;
                                          if (newValue != null) {
                                            _loadSelectedLoadout(newValue);
                                          } else {
                                            lastSavedTimestamp = "N/A"; // Clear timestamp when no loadout is selected
                                          }
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10), // Space between dropdown and buttons

                            // Delete Button
                            IconButton(
                              icon: Icon(Icons.delete, color: selectedLoadout != null ? Colors.red : Colors.grey),
                              onPressed: selectedLoadout != null && selectedLoadout != 'Save New'
                                  ? () =>
                              {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: AppColors.textFieldColor2,
                                      title: Text(
                                        'Confirm Deletion',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this loadout?',
                                        style: TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog without deleting
                                          },
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: AppColors.textColorPrimary),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Perform deletion
                                            _deleteLoadout(selectedLoadout!);
                                            // Close the dialogs
                                            Navigator.of(context).pop(); // Close confirmation dialog
                                          },
                                          child: const Text(
                                            'Delete',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                              }
                                  : null,
                            ),

                            // Save Button
                            IconButton(
                              icon: Icon(Icons.save_outlined, color: selectedLoadout != null ? Colors.green : Colors.grey),
                              onPressed: selectedLoadout != null && selectedLoadout != 'Save New'
                                  ? () => _updateCurrentLoadout(selectedLoadout!)
                                  : null,
                            ),
                          ],
                        ),

                        SizedBox(height: 5),
                        if (selectedLoadout != null && selectedLoadout!.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                !isOutOfSync ? Icons.check: Icons.sync_disabled_outlined, // Info icon
                                color: !isOutOfSync ? Colors.green : Colors.red,
                                size: 22, // Adjust size if needed
                              ),
                              Text(
                                ' Last Updated: $lastSavedTimestamp ${isOutOfSync ? "(Out of Sync!)" : ""}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isOutOfSync ? Colors.red : Colors.green.withOpacity(0.8),
                                  fontStyle: FontStyle.italic,
                                  fontWeight: isOutOfSync ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),

                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Share data
                  Row(
                    children: [
                      IconButton(
                          onPressed: importExportDialog,
                          icon: Icon(
                            Icons.sync,
                            color: Colors.white,
                            size: 28,
                          )),
                      TextButton(
                        onPressed: importExportDialog,
                        child: const Text('Crew Sharing', style: TextStyle(color: Colors.white, fontSize: 18)),
                      ),
                    ],
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
