import 'dart:ui';
import 'package:fire_app/Data/trip.dart';
import 'package:fire_app/06_single_trip_view.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class SavedTripsView extends StatefulWidget {
  const SavedTripsView({super.key});

  @override
  State<SavedTripsView> createState() => _SavedTripsState();

}

class _SavedTripsState extends State<SavedTripsView>{

  late final Box<Trip> tripBox;
  List<Trip> tripList = [];

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of Gear items
    tripBox = Hive.box<Trip>('tripBox');
    loadTripList();
  }
  // Function to load the list of Gear items from the Hive box
  void loadTripList() {
    setState(() {
     tripList = tripBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Trips',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepOrangeAccent,

      ),
      body: Stack(
        children: [
          Container(
            child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                // Blur effect
                child: Image.asset('assets/images/logo1.png',
                  fit: BoxFit.cover, // Cover  entire background
                  width: double.infinity,
                  height: double.infinity,
                )
            ),
          ),

          // Saved Trips list
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                child: ListView.builder(
                  //hive: itemCount: tripList.length,
                  itemCount: tripList.length,
                  // itemCount:savedTrips.savedTrips.length -- in memory
                  itemBuilder: (context, index) {

                    final trip = tripList[index];
                    //final trip = savedTrips.savedTrips[index];

                    // Display trip data in a scrollable list
                    return Card(
                      child: Container(
                        decoration: BoxDecoration(
                          // Could change color here
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: ListTile(
                          iconColor: Colors.black,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trip.tripName,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text(
                                    'Allowable: ${trip.allowable} lbs',
                                    style: const TextStyle(
                                      fontSize:18,
                                    ),
                                  )
                                ],
                              ),
                              // Set up to delete right now, not edit. Change later
                              IconButton(
                                  icon: const Icon(
                                      Icons.arrow_forward_ios,
                                      //Icons.edit,
                                      color: Colors.black,
                                      size: 32
                                  ),
                                  onPressed: (){

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => SingleTripView(
                                          trip: trip,
                                        ),
                                      ),
                                    );
                                    // For deletion
                                    // savedTrips.removeTrip(trip); -- in memory
                                    //tripBox.removeTrip(trip);
                                    //setState(() {});
                                  }
                              )
                            ],
                          ),
                          leading: Icon(Icons.flight),
                        ),
                      ),
                    );
                  },
                ),
              ),

                // Temporary delete All Button
                Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          spreadRadius: 1,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    //alignment: Alignment.center,
                    child: Row(
                      children: [
                        Text(
                          'Delete all',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                            icon: const Icon(
                                Icons.delete,
                                color: Colors.black,
                                size: 32
                            ),
                          onPressed: () {
                              savedTrips.deleteAllTrips();
                              loadTripList(); // Reset tripList after deletion, but for some reason doesn't work
                          },

                        )
                      ],
                    ),
                  ),
                ),
    ],
            ),
          ),


        ],
      ),
    );
  }
}
