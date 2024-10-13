import 'dart:ui';
import 'package:fire_app/edit_crewmember.dart';
import 'package:flutter/material.dart';
import 'Data/crew.dart';

class CrewmembersView extends StatefulWidget {
  const CrewmembersView({super.key});



  @override
  State<CrewmembersView> createState() => _CrewmembersViewState();
}
class _CrewmembersViewState extends State<CrewmembersView>{

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
            itemCount: crew.crewMembers.length,
            itemBuilder: (context, index) {

              final crewMember = crew.crewMembers[index];

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
                          crewMember.name,
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                          ),
                            ),
                            Text(
                              '${crewMember.flightWeight} lbs',
                              style: const TextStyle(
                                fontSize:18,
                              ),
                            )
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: 32
                          ),
                          onPressed: (){
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditCrewmember(
                                    crewMember: crewMember,
                                  onUpdate: () {
                                    setState(() {});  // Refresh the list
                                  },),
                              ),
                            );                          }
                        )
                    ],
                    ),
                    leading: Icon(Icons.person),
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
