import 'dart:ui';

import 'package:fire_app/add_crewmember.dart';
import 'package:fire_app/add_load_preference.dart';
import 'package:fire_app/crewmembers_view.dart';
import 'package:fire_app/gear_view.dart';
import 'package:fire_app/loadout_view.dart';
import 'package:flutter/material.dart';
import 'add_gear.dart';

// We should switch to a grid view for all Adding and Editing
// 3x3 for CrewMember, Gear, and Preferences

class EditCrew extends StatelessWidget {
  const EditCrew({super.key});

  @override
  Widget build(BuildContext context) {

    final ButtonStyle style =
    ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2, MediaQuery.of(context).size.height / 10)
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Edit Crew',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded( // Takes up all available space
            child: Stack(
              children: [

                Container(
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
                    child: Image.asset('assets/images/logo1.png',
                      fit: BoxFit.cover, // Cover  entire background
                      width: double.infinity,
                      height: double.infinity,
                    )
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      // Add Crew Member
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddCrewmember()),
                              );
                            },
                            style: style,
                            child: const Text(
                                'Add Crew Member',
                              textAlign: TextAlign.center,
                            )
                        ),
                      ),

                      // Add Gear
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddGear()),
                              );
                              },
                            style: style,
                            child: const Text(
                                'Add Gear',
                              textAlign: TextAlign.center,
                            )
                        ),
                      ),

                      // Edit Crew Members
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const CrewmembersView()),
                              );
                            },
                            style: style,
                            child: const Text(
                                'Edit Crew Members',
                              textAlign: TextAlign.center,
                            )
                        ),
                      ),

                      // Edit Gear
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const GearView()),
                              );
                            },
                            style: style,
                            child: const Text(
                                'Edit Gear',
                              textAlign: TextAlign.center,
                            )
                        ),
                      ),

                      // Add Load Preferences
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AddLoadPreference()),
                              );
                            },
                            style: style,
                            child: const Text(
                              'Add Load Preferences',
                              textAlign: TextAlign.center,
                            )
                        ),
                      ),

                      // Edit Load Preferences
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoadoutView()),
                              );
                            },
                            style: style,
                            child: const Text(
                              'View Load Preferences',
                              textAlign: TextAlign.center,
                            )
                        ),
                      ),
                    ],
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
