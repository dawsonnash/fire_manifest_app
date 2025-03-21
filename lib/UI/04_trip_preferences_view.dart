import 'dart:ui';
import 'package:fire_app/UI/04_add_trip_preference.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '04_edit_trip_preference.dart';
import '../CodeShare/variables.dart';
import '../Data/trip_preferences.dart';
import 'package:hive/hive.dart';

class TripPreferences extends StatefulWidget {
  const TripPreferences({super.key});

  @override
  State<TripPreferences> createState() => _TripPreferencesState();
}

class _TripPreferencesState extends State<TripPreferences> {
  // late final Box<CrewMember> crewmemberBox;
  List<TripPreference> tripPreferenceList = [];
  late final Box<TripPreference> tripPreferenceBox;

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of Gear items
    tripPreferenceBox = Hive.box<TripPreference>('tripPreferenceBox');
    loadTripPreferenceList();
    // savedPreferences.printTripPreferencesFromHive();
  }

  // Function to load all trip preferences upon screen opening
  void loadTripPreferenceList() {
    setState(() {
      tripPreferenceList = tripPreferenceBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Should probably keep this in a style file so we don't have to keep using it over and over again
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
      fontSize: 22,
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
        backgroundColor: AppColors.appBarColor,
        title: Text(
          'Trip Preferences',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
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
                            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
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
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Always display in light mode
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
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // Ensures the column only takes required space
                  children: [
                    Flexible(
                      child: tripPreferenceList.isEmpty
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
                                          'No Trip Preferences created...',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 22,
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
                              shrinkWrap: true, // Ensures the list takes only the necessary height
                              itemCount: tripPreferenceList.length,
                              itemBuilder: (context, index) {
                                final tripPreference = tripPreferenceList[index];

                                // Display TripPreference data in a scrollable list
                                return GestureDetector(
                                  onTap: () async {

                                    // Awaits the result from the next page so it updates in real time
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditTripPreference(tripPreference: tripPreference, onUpdate: loadTripPreferenceList),
                                      ),
                                    );
                                    // Calls the update function after returning from AddTripPreference
                                    loadTripPreferenceList();
                                  },
                                  child: Dismissible(
                                    key: Key(tripPreference.tripPreferenceName), // Unique key for each item
                                    direction: DismissDirection.endToStart, // Swipe from right to left
                                    background: Container(
                                      color: Colors.red, // Background color when swiping
                                      alignment: Alignment.centerRight,
                                      padding: EdgeInsets.symmetric(horizontal: 20),
                                      child: Icon(Icons.delete, color: Colors.white, size: 30), // Delete icon
                                    ),
                                    confirmDismiss: (direction) async {
                                      // Show a confirmation dialog before dismissing
                                      return await showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            backgroundColor: AppColors.textFieldColor2,
                                            title: Text(
                                              'Confirm Deletion',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                            ),
                                            content: Text(
                                              'Are you sure you want to delete this Trip Preference?',
                                              style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(false), // Cancel dismissal
                                                child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton)),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.of(context).pop(true), // Confirm dismissal
                                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    onDismissed: (direction) {
                                      // Perform the delete action after confirming
                                      savedPreferences.removeTripPreference(tripPreference);
                                      setState(() {
                                        tripPreferenceList.remove(tripPreference); // Remove from the list
                                      });

                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Center(
                                            child: Text(
                                              'Trip Preference Deleted!',
                                              style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  child: Card(
                                    color: AppColors.textFieldColor,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        // Could change color here
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: ListTile(
                                        iconColor: AppColors.primaryColor,
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tripPreference.tripPreferenceName,
                                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                                overflow: TextOverflow.ellipsis, // Add this
                                                maxLines: 1,
                                              ),
                                            ),
                                            IconButton(
                                                icon: Icon(Icons.more_vert, color: AppColors.textColorPrimary, size: 32),
                                                onPressed: () {
                                                  showModalBottomSheet(
                                                    backgroundColor: AppColors.textFieldColor2,
                                                    context: context,
                                                    builder: (BuildContext context) {
                                                      return Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: <Widget>[
                                                          ListTile(
                                                            leading: Icon(Icons.edit, color: AppColors.textColorPrimary),
                                                            title: Text(
                                                              'Edit Trip Preference',
                                                              style: TextStyle(color: AppColors.textColorPrimary),
                                                            ),
                                                            onTap: () async {
                                                              Navigator.of(context).pop(); //

                                                              // Awaits the result from the next page so it updates in real time
                                                              await Navigator.push(
                                                                context,
                                                                MaterialPageRoute(
                                                                  builder: (context) => EditTripPreference(tripPreference: tripPreference, onUpdate: loadTripPreferenceList),
                                                                ),
                                                              );
                                                              // Calls the update function after returning from AddTripPreference
                                                              loadTripPreferenceList();
                                                            },
                                                          ),
                                                          ListTile(
                                                            leading: Icon(Icons.delete, color: Colors.red),
                                                            title: Text(
                                                              'Delete Trip Preference',
                                                              style: TextStyle(color: AppColors.textColorPrimary),
                                                            ),
                                                            onTap: () {
                                                              Navigator.of(context).pop(); // Close the dialog without deleting

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
                                                                      'This Trip Preference will be erased!',
                                                                      style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                                                    ),
                                                                    actions: [
                                                                      TextButton(
                                                                        onPressed: () {
                                                                          Navigator.of(context).pop(); // Close the dialog without deleting
                                                                        },
                                                                        child: Text(
                                                                          'Cancel',
                                                                          style: TextStyle(color: AppColors.cancelButton),
                                                                        ),
                                                                      ),
                                                                      TextButton(
                                                                        onPressed: () {
                                                                          savedPreferences.removeTripPreference(tripPreference);

                                                                          // Show deletion pop-up
                                                                          ScaffoldMessenger.of(context).showSnackBar(
                                                                            SnackBar(
                                                                              content: Center(
                                                                                child: Text(
                                                                                  'Trip Preference Deleted!',
                                                                                  // Maybe change look
                                                                                  style: const TextStyle(
                                                                                    color: Colors.black,
                                                                                    fontSize: 32,
                                                                                    fontWeight: FontWeight.bold,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                              duration: Duration(seconds: 2),
                                                                              backgroundColor: Colors.red,
                                                                            ),
                                                                          );

                                                                          Navigator.of(context).pop(); // Dismiss the dialog
                                                                          loadTripPreferenceList();
                                                                        },
                                                                        child: const Text(
                                                                          'Delete',
                                                                          style: TextStyle(color: Colors.red),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  );
                                                                },
                                                              );
                                                            },
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                })
                                          ],
                                        ),
                                        leading: FaIcon(FontAwesomeIcons.fire),
                                      ),
                                    ),
                                  ),
                                ),
                                );
                              },
                            ),
                    ),
                    SizedBox(height: 8), // Adds spacing between the list and the panel

                    GestureDetector(
                      onTap: () async {
                        // Awaits the result from the next page so it updates in real time
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddTripPreference(onUpdate: loadTripPreferenceList),
                          ),
                        );
                        // Calls the update function after returning from AddTripPreference
                        loadTripPreferenceList();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Padding around the text and icon
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                          boxShadow: AppColors.isDarkMode
                              ? [] // No shadow in dark mode
                              : [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.5), // Shadow color
                              spreadRadius: 0, // Spread of the shadow
                              blurRadius: 20, // Blur effect
                              offset: Offset(0, 0), // Offset in x and y direction
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Ensures the container width is only as wide as its content
                          children: [
                            Icon(FontAwesomeIcons.circlePlus, color: AppColors.primaryColor,),
                            SizedBox(width: 8), // Space between the icon and the text
                            Text(
                              'Trip Preference',
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
