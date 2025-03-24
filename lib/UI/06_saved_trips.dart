import 'dart:ui';

import 'package:fire_app/CodeShare/variables.dart';
import 'package:fire_app/Data/trip.dart';
import 'package:fire_app/UI/06_single_trip_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

class SavedTripsView extends StatefulWidget {
  const SavedTripsView({super.key});

  @override
  State<SavedTripsView> createState() => _SavedTripsState();
}

class _SavedTripsState extends State<SavedTripsView> {
  late final Box<Trip> tripBox;
  List<Trip> tripList = [];

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of Gear items
    tripBox = Hive.box<Trip>('tripBox');
    loadTripList();

    // Add listener for changes to the box
    tripBox.watch().listen((event) {
      // Reload the list whenever there's a change
      if (mounted) {
        loadTripList();
      }
    });
  }

  // Function to load the list of Gear items from the Hive box
  void loadTripList() {
    setState(() {
      tripList = tripBox.values.toList();
      tripList.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }

  String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final duration = now.difference(timestamp);

    final seconds = duration.inSeconds;
    final minutes = duration.inMinutes;
    final hours = duration.inHours;
    final days = duration.inDays;

    if (seconds < 60) {
      return '${seconds}s';
    } else if (minutes < 60) {
      return '${minutes}m';
    } else if (hours < 24) {
      return '${hours}h';
    } else {
      return '${days}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        // Centers the title
        title: Text(
          'Saved Trips',
          style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        actions: [
          IconButton(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textColorPrimary,
              ),
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: AppColors.textFieldColor2,
                  context: context,
                  builder: (BuildContext context) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: AppData.bottomModalPadding),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete All Trips',
                              style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.modalTextSize, ),
                            ),
                            onTap: () {
                              if (savedTrips.savedTrips.isEmpty) {
                                Navigator.of(context).pop(); // Close confirmation dialog
                                return;
                              }
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
                                      'Are you sure you want to delete all trips?',
                                      style: TextStyle(fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(); // Close the dialog without deleting
                                        },
                                        child: Text(
                                          'Cancel',
                                          style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.bottomDialogTextSize, ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // Perform deletion
                                          savedTrips.deleteAllTrips();

                                          // Update the parent widget state
                                          setState(() {
                                            loadTripList();
                                          });

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
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              })
        ],

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
          // Saved Trips list
          if (savedTrips.savedTrips.isEmpty)
            Center(
              // Ensure the card is centered on the screen
              child: Padding(
                padding: EdgeInsets.all(12), // Padding inside the card
                child: Text(
                  "No trips created...",
                  style: TextStyle(
                    color: AppColors.textColorPrimary,
                    fontSize: AppData.text20,
                    fontWeight: AppColors.isDarkMode ? FontWeight.normal : FontWeight.bold,
                    shadows: AppColors.isDarkMode
                        ? null // No shadow in dark mode
                        : [
                            Shadow(
                              offset: Offset(0, 0),
                              blurRadius: 60.0,
                              color: Colors.white,
                            ),
                          ],
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
            ),

          Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        ListView.builder(
                          //hive: itemCount: tripList.length,
                          itemCount: tripList.length,
                          // itemCount:savedTrips.savedTrips.length -- in memory
                          itemBuilder: (context, index) {
                            final trip = tripList[index];
                            //final trip = savedTrips.savedTrips[index];

                            // Display trip data in a scrollable list
                            return Dismissible(
                              key: ValueKey(trip.tripName),
                              // Unique key for each trip
                              direction: DismissDirection.endToStart,
                              // Swipe from right to left
                              background: Container(
                                color: Colors.red, // Background color when swiped
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: AppData.text32,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                // Show a confirmation dialog before deleting
                                return await showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: AppColors.textFieldColor2,
                                      title: Text(
                                        'Confirm Deletion',
                                        style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.miniDialogTitleTextSize, ),
                                      ),
                                      content: Text(
                                        'Are you sure you want to delete this trip?',
                                        style: TextStyle(fontSize: AppData.miniDialogBodyTextSize, color: AppColors.textColorPrimary),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(); // Close the dialog without deleting
                                          },
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.bottomDialogTextSize, ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Perform deletion
                                            savedTrips.removeTrip(trip);

                                            // Update the parent widget state
                                            setState(() {
                                              loadTripList();
                                            });

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
                              },
                              onDismissed: (direction) {
                                // Perform the delete operation
                                setState(() {
                                  savedTrips.removeTrip(trip);
                                });
                              },
                              child: GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SingleTripView(trip: trip),
                                    ),
                                  );
                                  setState(() {}); // Refresh the list after returning
                                },
                                child: Center(
                                  child: Card(
                                    color: Colors.transparent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.textFieldColor,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      constraints: BoxConstraints(
                                        maxWidth: AppData.savedTripsMax,
                                      ),
                                      child: ListTile(
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Flexible(
                                                        child: Text(
                                                          trip.tripName,
                                                          style: TextStyle(
                                                            fontSize: AppData.text22,
                                                            fontWeight: FontWeight.bold,
                                                            color: AppColors.textColorPrimary,
                                                          ),
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        '•',
                                                        style: TextStyle(
                                                          fontSize: AppData.text22,
                                                          color: AppColors.textColorPrimary,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Text(
                                                        formatTimestamp(trip.timestamp),
                                                        style: TextStyle(
                                                          fontSize: AppData.text16,
                                                          fontWeight: FontWeight.w400,
                                                          color: AppColors.textColorPrimary,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Allowable: ${trip.allowable} lb',
                                                      style: TextStyle(
                                                        fontSize: AppData.text18,
                                                        color: AppColors.textColorPrimary,
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.arrow_forward_ios,
                                                color: AppColors.textColorPrimary,
                                                size: AppData.text28,
                                              ),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) => SingleTripView(
                                                      trip: trip,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                        leading: trip.isExternal!
                                            ? Transform.scale(
                                                scale: 1.5,
                                                child: SvgPicture.asset(
                                                  'assets/icons/sling_icon.svg', // Your SVG file path
                                                  width: 24, // Adjust size as needed
                                                  height: 24,
                                                  colorFilter: ColorFilter.mode(AppColors.primaryColor, BlendMode.srcIn), // Apply color dynamically
                                                ),
                                              )
                                            : Icon(
                                                FontAwesomeIcons.helicopter,
                                                color: AppColors.primaryColor,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
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
