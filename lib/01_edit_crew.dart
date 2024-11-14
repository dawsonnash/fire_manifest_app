import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fire_app/02_add_crewmember.dart';
import 'package:fire_app/02_crewmembers_view.dart';
import 'package:fire_app/03_gear_view.dart';
import 'package:fire_app/04_trip_preferences_view.dart';
import '03_add_gear.dart';
import 'Data/crew.dart';

// This layout needs work to have dynamically adjusted UI. Needs user-testing

class EditCrew extends StatelessWidget {
  const EditCrew({super.key});

  @override
  Widget build(BuildContext context) {

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final double buttonWidth = screenWidth / 2 - 24;
    final double buttonHeight = screenHeight * 0.1;

    // Button style for all buttons
    final ButtonStyle buttonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.black,
      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      backgroundColor: Colors.deepOrangeAccent,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      elevation: 15,
      shadowColor: Colors.black,
      side: const BorderSide(color: Colors.black, width: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      fixedSize: Size(buttonWidth, buttonHeight),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
            'Edit Crew',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
            Text(
              ' ${crew.totalCrewWeight.toInt().toString()} lbs',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
        ],
        ),
      ),
      body: Stack(
        children: [
          // Background image
          Container(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: screenHeight * 0.05,
                ),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(16.0),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddCrewmember()),
                          );
                        },
                        style: buttonStyle,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 32,
                            ),
                            //const SizedBox(width: 8),
                            Flexible( // Allows text to be wrapped
                              child: Text(
                                'Crew Member',
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CrewmembersView()),
                          );
                        },
                        style: buttonStyle,
                        child: Row(
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: 32,
                            ),
                            //const SizedBox(width: 8),
                            Flexible( // Allows text to be wrapped
                              child: Text(
                                'Crew Members',
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddGear()),
                          );
                        },
                        style: buttonStyle,
                        child: Row(
                          //mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Flexible( // Allows text to be wrapped
                              child: Text(
                                'Gear',
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),

                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GearView()),
                          );
                        },
                        style: buttonStyle,
                        child: Row(
                          //mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: 32,
                            ),
                            const SizedBox(width: 8),
                            Flexible( // Allows text to be wrapped
                              child: Text(
                                'Gear',
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: screenWidth * 0.9, // 90% of screen width
                  height: buttonHeight * 2.2, // This 2.2 was just trialed and errored until it matched the height. Could be a downfall matching multiple device aspect ratios
                  child: Padding(
                    padding: const EdgeInsets.only(top:16.0, bottom: 16.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TripPreferences()),
                        );
                      },
                      style: buttonStyle, // Same style as other buttons
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.settings,
                            color: Colors.black,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                          'Trip Preferences',
                          textAlign: TextAlign.center,
                        ),
                      ],
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: screenHeight * 0.05,
                ),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
