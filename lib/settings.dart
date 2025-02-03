import 'dart:ui';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/Data/trip_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:url_launcher/url_launcher.dart';
import 'CodeShare/colors.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'Data/crew.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import 'Data/crewmember.dart';
import 'Data/gear.dart';


class SettingsView extends StatefulWidget {
  final bool isDarkMode;
  final bool enableBackgroundImage;
  final Function(bool) onThemeChanged;
  final Function(bool) onBackgroundImageChange;
  final String crewName;
  final Function(String) onCrewNameChanged;

  const SettingsView({super.key, required this.isDarkMode, required this.onThemeChanged, required this.enableBackgroundImage, required this.onBackgroundImageChange, required this.crewName, required this.onCrewNameChanged});

  @override
  State<SettingsView> createState() => _SettingsState();
}

class _SettingsState extends State<SettingsView> {
  late bool isDarkMode;
  late bool enableBackgroundImage;
  late TextEditingController crewNameController;

  @override
  void initState() {
    super.initState();
    isDarkMode = widget.isDarkMode;
    enableBackgroundImage = widget.enableBackgroundImage;
    crewNameController = TextEditingController(text: widget.crewName); // Initialize with the current crew name

  }
  @override
  void dispose() {
    crewNameController.dispose(); // Dispose the controller to free resources
    super.dispose();
  }

  Future<void> exportCrewData() async {
    try {
      // Convert crew object to JSON string
      String jsonData = jsonEncode(crew.toJson());

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
            'Importing this file will delete all existing data besides your Saved Trips. This action is irreversible. Proceed?',
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
                importCrewData(file); // Proceed with import
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
  void importCrewData(PlatformFile file) async {
    try {
      // Read file contents
      String jsonString = await File(file.path!).readAsString();

      // Decode JSON safely
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(jsonString);
      } catch (e) {
        showErrorDialog("Invalid JSON file. Could not be read.");
        return;
      }

      // Validate required fields
      if (!jsonData.containsKey("crewMembers") ||
          !jsonData.containsKey("gear") ||
          !jsonData.containsKey("personalTools") ||
          !jsonData.containsKey("totalCrewWeight")) {
        showErrorDialog("Invalid JSON format. Missing required fields.");
        return;
      }

      // Validate data types
      if (jsonData["crewMembers"] is! List ||
          jsonData["gear"] is! List ||
          jsonData["personalTools"] is! List ||
          jsonData["totalCrewWeight"] is! num) {
        showErrorDialog("Invalid JSON format. Incorrect data types.");
        return;
      }

      // Convert JSON to Crew object
      Crew importedCrew;
      try {
        importedCrew = Crew.fromJson(jsonData);
      } catch (e) {
        showErrorDialog("Error processing data. Ensure the file is in the correct format.");
        return;
      }

      // Clear old data first
      await Hive.box<CrewMember>('crewmemberBox').clear();
      await Hive.box<Gear>('gearBox').clear();
      await Hive.box<Gear>('personalToolsBox').clear();
      await Hive.box<TripPreference>('tripPreferenceBox').clear();
      savedPreferences.deleteAllTripPreferences();

      // Save imported data to Hive
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

      // Reload crew data from Hive
      await crew.loadCrewDataFromHive();
      setState(() {});

      print("Import successful! Crew data updated.");

    } catch (e) {
      showErrorDialog("Unexpected error during import: $e");
    }
  }

// Helper function to show an error dialog
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

  Future<void> _sendFeedback() async {
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

  void importExportDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        int selectedIndex = 0; // Initial selection index

        return StatefulBuilder(
          builder: (context, setState) {
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
                            title: Text("Crew Sharing", style: TextStyle(color: AppColors.textColorPrimary),),
                            content: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min, // Prevents excessive height
                                children: [
                                  Text("Crew sharing allows you to share your crew data (Crew Members, Gear, and Tools) with other users. To share:\n", style: TextStyle(color: AppColors.textColorPrimary)),
                                  Text("1. For exporting, select the 'Export' option, save to your files, and then send to the  other user. If on iOS, this can be done directly through Air Drop, but must still be saved to your files. The exported file will be be titled CrewData along with today's date and will have a .json extension.\n", style: TextStyle(color: AppColors.textColorPrimary)),
                                  Text("2. For importing, select the 'Import' option and find the CrewData JSON file in your files.", style: TextStyle(color: AppColors.textColorPrimary)),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(); // Close the dialog
                                },
                                child: Text("OK", style: TextStyle(color: AppColors.textColorPrimary),),
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

                      if (crew.crewMembers.isEmpty && crew.gear.isEmpty){
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: AppColors.textFieldColor2,
                              title: Text("No crew to export", style: TextStyle(color: AppColors.textColorPrimary),),
                              content: Text("There are no Crew Members or Gear in your inventory.", style: TextStyle(color: AppColors.textColorPrimary)),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Close the dialog
                                  },
                                  child: Text("OK", style: TextStyle(color: AppColors.textColorPrimary),),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      else {
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
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Center(
          child: Text(
            'Settings',
            style: TextStyle(fontSize: 24, color: AppColors.textColorPrimary),
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
                          onPressed: () => crew.printPersonalTools(),
                          child: const Text('Quick Guide', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                        TextButton(
                          onPressed: _sendFeedback,
                          child: const Text('Report Bugs', style: TextStyle(color: Colors.white, fontSize: 18)),
                        ),
                      ],
                    ),
                  ),

                  Divider(color: Colors.white),

                  // Settings Title
                  ListTile(
                    leading: Icon(Icons.settings, color: Colors.white),
                    title: const Text(
                      'SETTINGS',
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
                          title:  Text(
                            'Display',
                            style: TextStyle(fontSize: 18, color: Colors.white), // White text for the label
                          ),
                          trailing: Icon(
                            Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                            color: Colors.white,       // Match the arrow color with the text color
                            size: 24,                  // Set a fixed size for consistency
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

                              Text('Crew Details', style: TextStyle(color: Colors.white, fontSize: 18),),
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
                                        title: Text("Crew Details Info", style: TextStyle(color: AppColors.textColorPrimary),),
                                        content: Text("This information is used to fill in the respective portions in the generated PDF manifests.", style: TextStyle(color: AppColors.textColorPrimary)),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop(); // Close the dialog
                                            },
                                            child: Text("OK", style: TextStyle(color: AppColors.textColorPrimary),),
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
                            color: Colors.white,       // Match the arrow color with the text color
                            size: 24,                  // Set a fixed size for consistency
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
                                      title: Text('Crew Name', style: TextStyle(color: Colors.white, fontSize: 18),),
                                      trailing: Icon(
                                        Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                                        color: Colors.white,       // Match the arrow color with the text color
                                        size: 24,                  // Set a fixed size for consistency
                                      ),
                                      children: [
                                        ListTile(
                                        title:  Container(
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
                                              controller: crewNameController, // Pre-fill with current crew name
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
                                                focusedBorder:  UnderlineInputBorder(
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
                                                ThemePreferences.setCrewName(value.trim()); // Save crew name preference (optional)
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                          ],
                                    ),

                                    // User's Name
                                    ExpansionTile(
                                      title: Text('Your Name', style: TextStyle(color: Colors.white, fontSize: 18),),
                                      trailing: Icon(
                                        Icons.keyboard_arrow_down, // Use a consistent icon for the dropdown
                                        color: Colors.white,       // Match the arrow color with the text color
                                        size: 24,                  // Set a fixed size for consistency
                                      ),
                                      children: [
                                        ListTile(
                                          title:   Container(
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
                                                //controller: userNameController, // Pre-fill with current crew name
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
                                                  focusedBorder:  UnderlineInputBorder(
                                                    borderSide: BorderSide(color: AppColors.fireColor),
                                                  ),
                                                ),
                                                onSubmitted: (value) {
                                                  setState(() {
                                                    // if (value.trim().isNotEmpty) {
                                                    //   widget.onCrewNameChanged(value.trim()); // Notify parent widget of the change
                                                    // }
                                                  });
                                                  // Call a callback or save preference
                                                  //ThemePreferences.setCrewName(value.trim()); // Save crew name preference (optional)
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
                                      style: TextStyle(color: AppColors.textColorPrimary),
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

                  // Share data
                  Row(
                    children: [
                      IconButton(onPressed: importExportDialog, icon: Icon(Icons.sync, color: Colors.white, size: 28,)),
                      TextButton(
                        onPressed: importExportDialog,
                        child: const Text('Share Crew', style: TextStyle(color: Colors.white, fontSize: 18)),
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
