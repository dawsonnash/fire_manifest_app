import 'dart:ui';
import 'package:fire_app/Data/trip.dart';
import 'package:fire_app/06_single_trip_view.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
        title: Row(
          children: [
            Text(
            'Saved Trips',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.more_vert, color: Colors.white,),
              onPressed: (){
                showModalBottomSheet(
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete All Trips', style: TextStyle(color: Colors.black),),
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text(
                                    'Confirm Deletion',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to delete all trips?',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context)
                                            .pop(); // Close the dialog without deleting
                                      },
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                            color: Colors.grey),
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
                                        Navigator.of(context).pop(); // Close bottom sheet
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
                          },                        ),
                      ],
                    );
                  },
                );
              }
            )
        ],
        ),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          Container(
            color: Colors.black,
            // child: ImageFiltered(
            //     imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
            //     // Blur effect
            //     child: Image.asset(
            //       'assets/images/logo1.png',
            //       fit: BoxFit.cover, // Cover  entire background
            //       width: double.infinity,
            //       height: double.infinity,
            //     )),
          ),

          // Saved Trips list
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
                          return GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SingleTripView(trip: trip),
                                ),
                              );
                              setState(() {}); // Refresh the list after returning
                            },
                            child: Card(
                              child: Container(
                                decoration: BoxDecoration(
                                  // Could change color here
                                  color: Colors.grey[900]?.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                child: ListTile(
                                  iconColor: Colors.black,
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
                                                    style: const TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                    overflow: TextOverflow.ellipsis, // Ensures the name truncates with ellipses
                                                    maxLines: 1, // Restricts to a single line
                                                  ),
                                                ),
                                                const SizedBox(width: 8), // Add space between the trip name and the dot
                                                const Text(
                                                  '•', // Small dot
                                                  style: TextStyle(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                const SizedBox(width: 8), // Add space between the dot and the timestamp
                                                Text(
                                                  formatTimestamp(trip.timestamp),
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w400,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            Text(
                                              'Allowable: ${trip.allowable} lbs',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                color: Colors.white,

                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                      // Set up to delete right now, not edit. Change later
                                      IconButton(
                                          icon: const Icon(Icons.arrow_forward_ios,
                                              //Icons.edit,
                                              color: Colors.deepOrangeAccent,
                                              size: 32),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => SingleTripView(
                                                  trip: trip,
                                                ),
                                              ),
                                            );
                                          })
                                    ],
                                  ),
                                  leading: Icon(FontAwesomeIcons.helicopter, color: Colors.deepOrangeAccent,),
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
