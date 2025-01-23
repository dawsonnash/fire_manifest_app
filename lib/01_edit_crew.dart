import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fire_app/02_add_crewmember.dart';
import 'package:fire_app/02_crewmembers_view.dart';
import 'package:fire_app/03_gear_view.dart';
import 'package:fire_app/04_trip_preferences_view.dart';
import '03_add_gear.dart';
import 'CodeShare/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class EditCrew extends StatelessWidget {
  const EditCrew({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double panelHeight = 125.0; // Height for the panels
    final double panelWidth = screenWidth * 0.8; // 80% of the screen width

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

    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          // Background
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent,
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                ? Stack(
              children: [
                ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                  child: Image.asset(
                    'assets/images/logo1.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Container(
                  color: AppColors.logoImageOverlay,
                ),
              ],
            )
                : null)
                : ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Image.asset(
                'assets/images/logo1.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),

          Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.appBarColor,
              toolbarHeight: 0,
              bottom: TabBar(
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.tabIconColor,
                indicatorColor: AppColors.primaryColor,
                tabs: [
                  Tab(text: 'Add', icon: Icon(Icons.add)),
                  Tab(text: 'Edit', icon: Icon(Icons.edit)),
                ],
              ),
            ),
            backgroundColor: Colors.transparent,
            body: Container(            color: Colors.white.withValues(alpha: 0.05),


              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        // Add Tab
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddCrewmember()),
                                  );
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.add, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Add Crew Member',
                                        style: panelTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddGear()),
                                  );
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.add, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Add Gear',
                                        style: panelTextStyle,
                                      ),
                                    ],
                                  ),
                                ),

                              ),
                            ],
                          ),
                        ),

                        // Edit Tab
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CrewmembersView()),
                                  );
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.edit, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Edit Crew Member',
                                        style: panelTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const GearView()),
                                  );
                                },
                                child: Container(
                                  width: panelWidth,
                                  height: panelHeight,
                                  decoration: panelDecoration,
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                    children: [
                                      Icon(
                                        Icons.edit, // Add icon
                                        color: AppColors.primaryColor,
                                        size: 32, // Adjust size as needed
                                      ),
                                      const SizedBox(width: 8), // Space between the icon and text
                                      Text(
                                        'Edit Gear',
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
                  ),

                  // Trip Preferences Panel
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TripPreferences()),
                        );
                      },
                      child: Container(
                        width: screenWidth * 0.9,
                        height: panelHeight,
                        decoration: panelDecoration,
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                          children: [
                            Icon(FontAwesomeIcons.sliders, // Add icon
                              color: AppColors.primaryColor,
                              size: 28, // Adjust size as needed
                            ),
                            const SizedBox(width: 8), // Space between the icon and text
                            Text(
                              'Trip Preferences',
                              style: panelTextStyle,
                            ),
                          ],
                        ),
                      ),
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
