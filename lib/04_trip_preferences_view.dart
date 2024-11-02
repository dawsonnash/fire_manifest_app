import 'dart:ui';
import 'package:fire_app/04_add_trip_preference.dart';
import 'package:fire_app/Data/crewmember.dart';
import 'package:fire_app/Data/saved_preferences.dart';
import 'package:fire_app/04_add_load_preference.dart';
import 'package:fire_app/02_edit_crewmember.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';


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
    tripPreferenceDataList();

    // Data population for testing
    savedPreferences.testDataTripPreference();


  }
  // Function to load the list of Gear items from the Hive box
  void tripPreferenceDataList() {
    setState(() {
      // crewmemberList = crewmemberBox.values.toList();
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
                                    onPressed: (){
                                      null;
                                      // Navigator.push(
                                      //   context,
                                      //   MaterialPageRoute(
                                      //     builder: (context) => EditCrewmember(
                                      //       crewMember: crewMember,
                                      //       onUpdate: loadCrewMemberList, // refresh list on return
                                      //     ),
                                      //   ),
                                      // );
                                    }
                                )
                              ],
                            ),
                            leading: Icon(Icons.south_america_sharp),
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddTripPreference()),
                        );
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
                              setState((){});
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
