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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: crewmemberList.length,
                    itemBuilder: (context, index) {
                      final crewMember = crewmemberList[index];

                      // Display crewmember data in a scrollable list
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
                                        Text(
                                          (crewMember.personalTools ?? []).map((gearItem) => gearItem.name).join(', '),
                                          style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ],
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
                        ),
                      );
                    },
                  ),
                ),

                // Delete all (app testing only)
                Padding(
                  padding:
                      const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
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
                            icon: const Icon(Icons.delete,
                                color: Colors.black, size: 32),
                            onPressed: () {
                              crew.deleteAllCrewMembers();
                              setState(() {});
                            })
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
