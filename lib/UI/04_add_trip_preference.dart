import 'dart:ui';

import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/UI/04_add_load_preference.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../CodeShare/variables.dart';
import '../Data/crew.dart';
import '../Data/crewmember.dart';
import '../Data/positional_preferences.dart';
import '../Data/trip_preferences.dart';

class AddTripPreference extends StatefulWidget {
  final VoidCallback onUpdate; // Callback to update previous page

  const AddTripPreference({required this.onUpdate, super.key});

  @override
  State<AddTripPreference> createState() => _AddTripPreferenceState();
}

class _AddTripPreferenceState extends State<AddTripPreference> {
  // New TripPreference object
  late TripPreference tripPreference;
  List<PositionalPreference> positionalPreferenceList = [];

  //List Gear

  @override
  void initState() {
    super.initState();

    int untitledNumber = 1;
    String untitledName = 'Untitled';
    for (int i = 0; i < savedPreferences.tripPreferences.length; i++) {
      TripPreference currentTripPreference = savedPreferences.tripPreferences[i];

      // Check if the Untitled name with the number already exists
      bool tripPrefNameExists = currentTripPreference.tripPreferenceName.toLowerCase() == (untitledName + untitledNumber.toString()).toLowerCase();

      if (tripPrefNameExists) {
        untitledNumber++;
      }
    }
    // Initialize the TripPreference object with a default name
    tripPreference = TripPreference(tripPreferenceName: 'Untitled$untitledNumber');

    // Add the new tripPreference to savedPreferences and save it to Hive
    savedPreferences.addTripPreference(tripPreference);
  }

  // Function to edit title
  void _editTitle() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController titleController = TextEditingController(text: tripPreference.tripPreferenceName);
        String? errorMessage; // Variable to hold error message

        return StatefulBuilder(
          // Enables state updates inside the dialog
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                "Edit Trip Preference Name",
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
              content: TextField(
                controller: titleController,
                maxLength: 20,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: "Trip Preference Name",
                  labelStyle: TextStyle(color: AppColors.textColorPrimary),
                  errorText: errorMessage, // Display error if exists
                ),
                style: TextStyle(color: AppColors.textColorPrimary),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Dismiss dialog
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    bool tripNameExists = savedPreferences.tripPreferences.any(
                      (preference) => preference.tripPreferenceName == titleController.text && preference != tripPreference, // Exclude current name if editing the same trip
                    );

                    if (tripNameExists) {
                      setState(() {
                        errorMessage = "Trip Preference name already exists";
                      });

                      // Clear the error message after 2 seconds
                      Future.delayed(Duration(seconds: 2), () {
                        setState(() {
                          errorMessage = null;
                        });
                      });
                    } else if (titleController.text.trim().isEmpty) {
                      setState(() {
                        errorMessage = "Trip Preference name cannot be empty";
                      });

                      // Clear the error message after 2 seconds
                      Future.delayed(Duration(seconds: 2), () {
                        setState(() {
                          errorMessage = null;
                        });
                      });
                    } else {
                      setState(() {
                        tripPreference.tripPreferenceName = titleController.text.trim();
                        tripPreference.save(); // Save changes to Hive
                      });
                      Navigator.of(context).pop(); // Dismiss dialog
                    }
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(color: AppColors.saveButtonAllowableWeight),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Loads all preferences upon screen opening or after creating new one
  void loadPositionalPreferenceList() {
    setState(() {
      positionalPreferenceList = tripPreference.positionalPreferences.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double panelHeight = 80.0; // Height for the panels
    final double panelWidth = screenWidth * 0.6;

    BoxDecoration panelDecoration = BoxDecoration(
      color: AppColors.panelColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
        color: Colors.black, // Outline color
        width: 2.0, // Outline width
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );

    TextStyle panelTextStyle = TextStyle(
      fontSize: AppData.text22,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
    );

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // The back arrow icon
            color: AppColors.textColorPrimary, // Set the desired color
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when pressed
          },
        ),
        title: Text(
          tripPreference.tripPreferenceName,
          style: TextStyle(fontSize: AppData.text24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.textColorPrimary,
            ),
            onPressed: _editTitle,
          ),
        ],
        backgroundColor: AppColors.appBarColor,
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent,
            // Background color for dark mode
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                    ? Stack(
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            // Blur effect
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
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    // Always display in light mode
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.cover, // Cover the entire background
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),

          Stack(
            children: [
              Container(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  // Ensures the column only takes required space
                  children: [
                    Flexible(
                      child: tripPreference.positionalPreferences.isEmpty && tripPreference.gearPreferences.isEmpty
                          ? Card(
                              color: AppColors.textFieldColor,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: ListTile(
                                  iconColor: AppColors.primaryColor,
                                  title: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'No Load Preferences added...',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: AppData.text22,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textColorPrimary,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              // Ensures the list takes only the necessary height

                              itemCount: tripPreference.positionalPreferences.length + tripPreference.gearPreferences.length,
                              itemBuilder: (context, index) {
                                // If index is within the positionalPreferences range
                                if (index < tripPreference.positionalPreferences.length) {
                                  final posPref = tripPreference.positionalPreferences[index];

                                  // Dynacmic title - individual or saw teams
                                  String titleText = posPref.crewMembersDynamic.map((member) {
                                    if (member is CrewMember) {
                                      return member.name; // Single crew member
                                    } else if (member is List<CrewMember>) {
                                      // Check which saw team this list matches and return the appropriate name
                                      if (member == crew.getSawTeam(1)) return 'Saw Team 1';
                                      if (member == crew.getSawTeam(2)) return 'Saw Team 2';
                                      if (member == crew.getSawTeam(3)) return 'Saw Team 3';
                                      if (member == crew.getSawTeam(4)) return 'Saw Team 4';
                                      if (member == crew.getSawTeam(5)) return 'Saw Team 5';
                                      if (member == crew.getSawTeam(6)) return 'Saw Team 6';
                                    }
                                    return '';
                                  }).join(', ');

                                  return Card(
                                    color: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.textFieldColor,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: ListTile(
                                        title: Text(
                                          posPref.crewMembersDynamic.map((item) {
                                            if (item is CrewMember) {
                                              return item.name; // Display individual crew member name
                                            } else if (item is List<CrewMember>) {
                                              // Check which Saw Team the list matches and return the appropriate Saw Team name
                                              for (int i = 1; i <= 6; i++) {
                                                List<CrewMember> sawTeam = crew.getSawTeam(i);
                                                if (sawTeam.every((member) => item.contains(member)) && item.length == sawTeam.length) {
                                                  return 'Saw Team $i'; // Return Saw Team name
                                                }
                                              }
                                            }
                                            return '';
                                          }).join(', '),
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
                                        ),
                                        subtitle: Text("Load Preference: ${loadPreferenceMap[posPref.loadPreference]}", style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary)),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              tripPreference.positionalPreferences.removeAt(index);
                                              tripPreference.save(); // Save changes to Hive
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                // Handle gear preferences
                                final gearIndex = index - tripPreference.positionalPreferences.length;
                                final gearPref = tripPreference.gearPreferences[gearIndex];
                                return Card(
                                  color: Colors.transparent,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.textFieldColor,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: ListTile(
                                      title: Text(
                                        gearPref.gear.map((item) => '${item.name} (x${item.quantity})').join(', '),
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text20, color: AppColors.textColorPrimary),
                                      ),
                                      subtitle: Text(
                                        "Load Preference: ${loadPreferenceMap[gearPref.loadPreference]}",
                                        style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            tripPreference.gearPreferences.removeAt(gearIndex);
                                            tripPreference.save(); // Save changes to Hive
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: 8),
                    // Adds spacing between the list and the panel
                    // Add Load Preference Button
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddLoadPreference(
                              tripPreference: tripPreference,
                              onUpdate: loadPositionalPreferenceList, // refresh list on return
                            ),
                          ),
                        );
                        if (result != null) {
                          setState(() {
                            tripPreference.positionalPreferences.add(result);
                          });
                        }
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        // Padding around the text and icon
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          // Rounded corners
                          boxShadow: AppColors.isDarkMode
                              ? [] // No shadow in dark mode
                              : [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    // Shadow color
                                    spreadRadius: 0,
                                    // Spread of the shadow
                                    blurRadius: 20,
                                    // Blur effect
                                    offset: Offset(0, 0), // Offset in x and y direction
                                  ),
                                ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          // Ensures the container width is only as wide as its content
                          children: [
                            Icon(
                              FontAwesomeIcons.circlePlus,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 8),
                            // Space between the icon and the text
                            Text(
                              'Load Preference',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: panelTextStyle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
