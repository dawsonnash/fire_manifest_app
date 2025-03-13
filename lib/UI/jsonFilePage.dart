import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../CodeShare/colors.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import '../Data/gear.dart';
import '../Data/saved_preferences.dart';
import '../Data/trip_preferences.dart';
import '../main.dart';

class JsonFilePage extends StatefulWidget {
  final String filePath;
  final String jsonContent;

  const JsonFilePage({super.key, required this.filePath, required this.jsonContent});

  @override
  State<JsonFilePage> createState() => _JsonFilePageState();
}

class _JsonFilePageState extends State<JsonFilePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      confirmDataWipe();
    });
  }

  void confirmDataWipe() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent users from dismissing without action
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.textFieldColor2,
          title: Text(
            'Warning',
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Importing this file will overwrite all existing crew data (Crew Members, Gear, Tools, Trip Preferences). Proceed?',
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
                importCrewData(() {
                  setState(() {}); // Force UI to rebuild
                });

                // Show successful save popup
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Center(
                      child: Text(
                        'Crew Imported!',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 22,
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

  void importCrewData(Function updateUI) async {
    try {
      // Read file contents
      String jsonString = await File(widget.filePath).readAsString();
      Map<String, dynamic> jsonData = jsonDecode(jsonString);

      // Validate required fields
      if (!jsonData.containsKey("crew") || !jsonData.containsKey("savedPreferences")) {
        showErrorDialog("Invalid JSON format. Missing required fields.");
        return;
      }

      // Import Crew Data
      Crew importedCrew = Crew.fromJson(jsonData["crew"]);
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

      setState(() {});

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

  @override
  Widget build(BuildContext context) {
    AppData.updateScreenData(context);
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            'Loadout File Import',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
          ),
        ),
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          Container(
            child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                )),
          ),
          Padding(
            padding: EdgeInsets.all(18.0),
          )
        ],
      ),
    );
  }
}
