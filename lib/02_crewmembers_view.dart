import 'dart:ui';
import 'package:fire_app/02_add_crewmember.dart';
import 'package:fire_app/Data/crewmember.dart';
import 'package:fire_app/02_edit_crewmember.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'CodeShare/colors.dart';
import 'Data/crew.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class CrewmembersView extends StatefulWidget {
  const CrewmembersView({super.key});

  @override
  State<CrewmembersView> createState() => _CrewmembersViewState();
}

class _CrewmembersViewState extends State<CrewmembersView> {
  late final Box<CrewMember> crewmemberBox;
  List<CrewMember> crewmemberList = [];

  @override
  void initState() {
    super.initState();
    // Open the Hive box and load the list of crewmembers
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    loadCrewMemberList();
  }

  // Function to load the list of crewmembers from the Hive box
  void loadCrewMemberList() {
    setState(() {
      crewmemberList = crewmemberBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    List<CrewMember> sortedCrewMemberList = sortCrewListByPosition(crewmemberList);

    TextStyle panelTextStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: AppColors.textColorPrimary,
    );
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: AppColors.appBarColor,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back, // The back arrow icon
            color: AppColors.textColorPrimary, // Set the desired color
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Navigate back when pressed
          },
        ),
        title: Text(
          'Crew Members',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
        ),
        actions: [
          IconButton(
              onPressed: () {
                showModalBottomSheet(
                  backgroundColor: AppColors.textFieldColor2,
                  context: context,
                  builder: (BuildContext context) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text(
                            'Delete All Crew Members',
                            style: TextStyle(color: AppColors.textColorPrimary),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(); // Close the dialog without deleting
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.textFieldColor2,
                                  title: Text(
                                    'Confirm Deletion',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete all crew members?',
                                    style: TextStyle(fontSize: 16, color: AppColors.textColorPrimary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(); // Close the dialog without deleting
                                      },
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: AppColors.cancelButton),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        crew.deleteAllCrewMembers();
                                        setState(() {});
                                        Navigator.of(context).pop(); // Close the dialog after deletion
                                        Navigator.of(context).pop(); // Home screen
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
                          },
                        ),
                      ],
                    );
                  },
                );
              },
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textColorPrimary,
              ))
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent, // Background color for dark mode
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                    ? Stack(
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Blur effect
                            child: Image.asset(
                              'assets/images/logo1.png',
                              fit: BoxFit.cover, // Cover the entire background
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Container(
                            color: AppColors.logoImageOverlay, // Semi-transparent overlay
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ],
                      )
                    : null) // No image if background is disabled
                : ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), // Always display in light mode
                    child: Image.asset(
                      'assets/images/logo1.png',
                      fit: BoxFit.cover, // Cover the entire background
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
          Container(
            color: Colors.white.withValues(alpha: 0.05),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      crewmemberList.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Card(
                                    color: AppColors.textFieldColor,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: ListTile(
                                        iconColor: AppColors.primaryColor,
                                        title: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'No crew members created...',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.textColorPrimary,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8), // Adds spacing between the list and the panel

                                  GestureDetector(
                                    onTap: ()  {
                                      Navigator.of(context).pop(); // Navigate back when pressed
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const AddCrewmember()),
                                      );
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                      children: [
                                        Icon(FontAwesomeIcons.circlePlus, color: AppColors.primaryColor,),
                                        SizedBox(width: 8), // Space between the icon and the text
                                        Text(
                                          'Crew Member',
                                          textAlign: TextAlign.center,
                                          softWrap: true,
                                          style: panelTextStyle,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: sortedCrewMemberList.length,
                              itemBuilder: (context, index) {
                                final crewMember = sortedCrewMemberList[index];

                                // Display crewmember data in a scrollable list
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.textFieldColor, // Background color
                                    border: Border(top: BorderSide(color: Colors.black, width: 1)), // Add a border
                                  ),
                                  child: ListTile(
                                    iconColor: AppColors.primaryColor,
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${crewMember.name}, ${crewMember.flightWeight} lbs',
                                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    ' ${crewMember.getPositionTitle(crewMember.position)}'
                                                    '${(crewMember.personalTools?.isNotEmpty ?? false) ? ' • ' : ''}', // Conditionally add the dot
                                                    style: TextStyle(fontSize: 14, color: AppColors.textColorPrimary),
                                                  ),
                                                  Expanded(
                                                    child: Text(
                                                      (crewMember.personalTools ?? []).map((gearItem) => gearItem.name).join(', '),
                                                      style: TextStyle(fontSize: 14, color: AppColors.textColorPrimary),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                            icon: Icon(Icons.edit, color: AppColors.textColorPrimary, size: 32),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditCrewmember(
                                                    crewMember: crewMember,
                                                    onUpdate: loadCrewMemberList, // refresh list on return
                                                  ),
                                                ),
                                              );
                                            })
                                      ],
                                    ),
                                    leading: Icon(Icons.person),
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
        ],
      ),
    );
  }
}
