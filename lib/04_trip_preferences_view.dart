import 'dart:ui';
import 'package:fire_app/04_add_trip_preference.dart';
import 'package:fire_app/Data/crewmember.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/04_add_load_preference.dart';
import 'package:fire_app/02_edit_crewmember.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '04_edit_trip_preference.dart';


class TripPreferences extends StatefulWidget {
  const TripPreferences({super.key});

  @override
  State<TripPreferences> createState() => _TripPreferencesState();
}
class _TripPreferencesState extends State<TripPreferences>{

  // late final Box<CrewMember> crewmemberBox;
  List<TripPreference> tripPreferenceList = [];

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of Gear items
    // crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    loadTripPreferenceList();
  }

  // Function to load all trip preferences upon screen opening
  void loadTripPreferenceList() {
    setState(() {
      tripPreferenceList = savedPreferences.tripPreferences.toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    // Should probably keep this in a style file so we don't have to keep using it over and over again
    final ButtonStyle style =
    ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(
            fontSize: 24,
            fontWeight:
            FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 1.6, MediaQuery.of(context).size.height / 10)
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trip Preferences',
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child:
                  ListView.builder(
                    itemCount: tripPreferenceList.length,
                    itemBuilder: (context, index) {

                      final tripPreference = tripPreferenceList[index];

                      // Display TripPreference data in a scrollable list
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
                                Text(
                                  tripPreference.tripPreferenceName,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold
                                  ),
                                ),
                                IconButton(
                                    icon: const Icon(
                                        Icons.edit,
                                        color: Colors.black,
                                        size: 32
                                    ),
                                  onPressed: () async {
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
                                )
                              ],
                            ),
                            leading: Icon(Icons.south_america_sharp),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                          'Delete ${tripPreference.tripPreferenceName}?',
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                          )
                                      ),
                                      content: Text('This trip preference data (${tripPreference.tripPreferenceName}) will be erased!',
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

                                                // // Remove item from the Hive box
                                                // final keyToRemove = crewmemberBox.keys.firstWhere(
                                                //       (key) => crewmemberBox.get(key) == widget.crewMember,
                                                //   orElse: () => null,
                                                // );
                                                //
                                                // if (keyToRemove != null) {
                                                //   crewmemberBox.delete(keyToRemove);
                                                // }

                                                // Remove the crew member
                                                savedPreferences.deleteTripPreference(tripPreference);

                                                // Show deletion pop-up
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Trip Preference Deleted!',
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
                                                loadTripPreferenceList();
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

                            ),
                          ),
                        ),
                      );
                    },
                  ),

                ),

                // + Add Load Preference
                // Make scrollable with the list of loadouts
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () async {
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

                    style: style,
                      child: Row(
                        children: [
                          const Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 32
                          ),

                          Flexible( // Allows text to be wrapped
                            child: Text(
                              'Trip Preference',
                              textAlign: TextAlign.center,
                              softWrap: true,
                            ),
                          ),
                      ],
                      ),
                  ),
                ),

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
                            onPressed: (){
                              savedPreferences.deleteAllTripPreferences();
                              loadTripPreferenceList();
                            }
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
