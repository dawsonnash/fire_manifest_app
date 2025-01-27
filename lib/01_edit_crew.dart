import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fire_app/02_add_crewmember.dart';
import 'package:fire_app/02_crewmembers_view.dart';
import 'package:fire_app/03_gear_view.dart';
import 'package:fire_app/04_trip_preferences_view.dart';
import '03_add_gear.dart';
import 'CodeShare/colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'Data/crew.dart';

class EditCrew extends StatefulWidget {
  const EditCrew({super.key});



  @override
  State<EditCrew> createState() => _EditCrewState();
}

class _EditCrewState extends State<EditCrew> {

  @override
  void initState() {
    super.initState();
  }

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

    TextStyle headerTextStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
      // decoration: TextDecoration.underline,
      // decorationColor: AppColors.primaryColor, // Set the color of the underline
      shadows: [
        Shadow(
          offset: Offset(0, 0),
          blurRadius: 80.0,
          color: Colors.black,
        ),
      ],
    );

    TextStyle subHeaderTextStyle = TextStyle(
      fontSize: 18,
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
            resizeToAvoidBottomInset: true, // Allow resizing when keyboard opens

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
            body: Container(
              color: Colors.white.withValues(alpha: 0.05),
              child: Column(
                children: [
                  // Crew Name and Total Weight
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: (screenWidth - panelWidth) / 2, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // children: [
                        //   GestureDetector(
                        //     onTap: () {
                        //       setState(() {
                        //         isEditing = true; // Enter editing mode on tap
                        //       });
                        //     },
                        //     onDoubleTap: () {
                        //       setState(() {
                        //         isEditing = true; // Enter editing mode on double-tap
                        //       });
                        //     },
                        //     onLongPress: () {
                        //       setState(() {
                        //         isEditing = true; // Enter editing mode on long press
                        //       });
                        //     },
                        //     child: isEditing
                        //         ? TextField(
                        //       autofocus: true,
                        //       controller: TextEditingController(text: crewName),
                        //       style: headerTextStyle,
                        //       textAlign: TextAlign.center,
                        //       onSubmitted: (value) {
                        //         if (value.trim().isNotEmpty) {
                        //           setState(() {
                        //             crewName = value.trim(); // Update the crew name
                        //             isEditing = false; // Exit editing mode
                        //           });
                        //           widget.onCrewNameChanged(crewName); // Notify parent of the change
                        //         } else {
                        //           setState(() {
                        //             isEditing = false; // Exit editing mode without saving
                        //           });
                        //         }
                        //       },
                        //       onEditingComplete: () {
                        //         setState(() {
                        //           isEditing = false; // Exit editing mode
                        //         });
                        //       },
                        //       decoration: InputDecoration(
                        //         border: InputBorder.none, // No borders for a seamless look
                        //         hintText: 'Enter crew name',
                        //       ),
                        //     )
                        //         :
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end, // Aligns the text and underline to the right
                          children: [
                            IntrinsicWidth(
                              child: Container(
                                padding: EdgeInsets.only(bottom: 4.0),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(color: AppColors.fireColor, width: 2.0),
                                  ),
                                ),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: screenWidth * 0.8, // Limit the maximum width
                                  ),
                                  child: Text(
                                    AppData.crewName,
                                    style: headerTextStyle,
                                    textAlign: TextAlign.right,
                                    maxLines: 2, // Limit to 2 lines
                                    overflow: TextOverflow.ellipsis, // Ellipsis if overflowed
                                    softWrap: true, // Ensure wrapping
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            '${crew.crewMembers.length} persons',
                            style: subHeaderTextStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          '${crew.totalCrewWeight.toInt()} lbs',
                          style: subHeaderTextStyle,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  Flexible(
                    child: TabBarView(
                      children: [
                        // Add Tab
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddCrewmember()),
                                  );
                                  setState(() {});
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
                                        'Crew Member',
                                        style: panelTextStyle,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddGear()),
                                  );
                                  setState(() {});
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
                                        'Gear',
                                        style: panelTextStyle,
                                        textAlign: TextAlign.center,
                                        softWrap: true,
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
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const CrewmembersView()),
                                  );
                                  setState(() {});
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
                                        'Crew Member',
                                        style: panelTextStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              GestureDetector(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const GearView()),
                                  );
                                  setState(() {});
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
                                        'Gear',
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
                            Icon(
                              FontAwesomeIcons.sliders, // Add icon
                              color: AppColors.primaryColor,
                              size: 28, // Adjust size as needed
                            ),
                            const SizedBox(width: 8), // Space between the icon and text
                            Text(
                              'Trip Preferences',
                              style: panelTextStyle,
                              textAlign: TextAlign.center,
                              softWrap: true,
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
