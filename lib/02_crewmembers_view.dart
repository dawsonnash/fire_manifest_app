import 'dart:ui';
import 'package:fire_app/Data/crewmember.dart';
import 'package:fire_app/02_edit_crewmember.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'Data/crew.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Crew Members',
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
                child: Image.asset(
                  'assets/images/logo1.png',
                  fit: BoxFit.cover, // Cover  entire background
                  width: double.infinity,
                  height: double.infinity,
                )),
          ),
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                    itemCount: sortedCrewMemberList.length,
                    itemBuilder: (context, index) {
                      final crewMember = sortedCrewMemberList[index];

                      // Display crewmember data in a scrollable list
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white, // Background color
                          border: Border(bottom: BorderSide(color: Colors.grey, width: 1)), // Add a border
                        ),
                        child: ListTile(
                          iconColor: Colors.black,

                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${crewMember.name}, ${crewMember.flightWeight} lbs',
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold),

                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          ' ${crewMember.getPositionTitle(crewMember.position)} - ',
                                          style: const TextStyle(
                                            fontSize: 14,

                                          ),

                                        ),
                                        Expanded(
                                          child: Text(
                                            (crewMember.personalTools ?? []).map((gearItem) => gearItem.name).join(', '),
                                            style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.black, size: 32),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditCrewmember(
                                          crewMember: crewMember,
                                          onUpdate:
                                              loadCrewMemberList, // refresh list on return
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
                  ),// Delete all
                    Positioned(
                      bottom: 10,
                      left: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () {
                          // if (savedTrips.savedTrips.isNotEmpty) {}
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text(
                                  'Confirm Deletion',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                content: const Text(
                                  'Are you sure you want to delete all crew members? Additionally, all Positional Preference data will be erased.',
                                  style: TextStyle(fontSize: 16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Close the dialog without deleting
                                    },
                                    child: const Text(
                                      'Cancel',
                                      style: TextStyle(
                                          color: Colors.grey),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      crew.deleteAllCrewMembers();
                                      setState(() {
                                      });
                                      Navigator.of(context).pop(); // Close the dialog after deletion
                                      Navigator.of(context).pop(); // Home screen
                                    },
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(
                                          color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },

                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.deepOrangeAccent,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.8),
                                spreadRadius: 60,
                                blurRadius: 20,
                                offset: Offset(0, 50),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          //alignment: Alignment.center,
                          child: Row(
                            children: [
                              Text(
                                'Delete All Crew Members',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Spacer(),
                              Icon(Icons.delete, color: Colors.black, size: 32),
                            ],
                          ),
                        ),
                      ),
                    ),

              ],
                ),
              ),

            ],
          ),
        ],
      ),
    );
  }
}
