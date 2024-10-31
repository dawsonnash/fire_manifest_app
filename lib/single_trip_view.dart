import 'dart:ui';
import 'package:fire_app/single_load_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/trip.dart';
import 'package:hive/hive.dart';

class SingleTripView extends StatefulWidget {

  // This page requires a trip to be passed to it
  final Trip trip;
  final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const SingleTripView({
    super.key,
    required this.trip,
    required this.onUpdate,
  });

  @override
  State<SingleTripView> createState() => _SingleTripViewState();
}
class _SingleTripViewState extends State<SingleTripView>{

  @override
  void initState() {
    super.initState();
    print('Number of loads: ${widget.trip.loads.length}');

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,  // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
          widget.trip.tripName,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                  //hive: itemCount: tripList.length,
                  itemCount: widget.trip.loads.length,
                  itemBuilder: (context, index) {

                    // hive: final trip = tripList[index];
                    final load = widget.trip.loads[index];

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
                                    'Load ${load.loadNumber.toString()}',
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Text(
                                    'Weight: ${load.weight} lbs',
                                    style: const TextStyle(
                                      fontSize:18,
                                    ),
                                  )
                                ],
                              ),
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
                                        builder: (context) => SingleLoadView(
                                          load: load,
                                        ),
                                      ),
                                    );
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
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    right: 16.0,
                    top: 8.0,
                    bottom: 16.0,
                  ),
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
                    child: Row(
                      children: [
                        const Text(
                          'Delete Trip',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                              Icons.delete,
                              color: Colors.black,
                              size: 32
                          ),
                          onPressed: (){
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(
                                      'Delete ${widget.trip.tripName}?',
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      )
                                  ),
                                  content: Text('This trip (${widget.trip.tripName}) will be erased!',
                                      style: const TextStyle(
                                        fontSize: 18,
                                      )),
                                  actions: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();  // Dismiss the dialog
                                          },
                                          child: const Text('Cancel',
                                              style: TextStyle(
                                                fontSize: 22,
                                              )),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            // Remove the crew member
                                            savedTrips.removeTrip(widget.trip);
                                            widget.onUpdate(); // Callback function to update UI with new data

                                            // Show deletion pop-up
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('${widget.trip.tripName} Deleted!',
                                                  // Maybe change look
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                duration: Duration(seconds: 2),
                                                backgroundColor: Colors.red,
                                              ),
                                            );

                                            Navigator.of(context).pop();  // Dismiss the dialog
                                            Navigator.of(context).pop();  // Return to previous screen
                                          },
                                          child: const Text('OK',
                                              style: TextStyle(
                                                fontSize: 22,
                                              )),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            );
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
