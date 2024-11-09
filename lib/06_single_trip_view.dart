import 'dart:ui';
import 'package:fire_app/06_single_load_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Data/trip.dart';

class SingleTripView extends StatefulWidget {

  // This page requires a trip to be passed to it
  final Trip trip;
  //final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const SingleTripView({
    super.key,
    required this.trip,
    //required this.onUpdate,
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

        ],
      ),
    );
  }
}
