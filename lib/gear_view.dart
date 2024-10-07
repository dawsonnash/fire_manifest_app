import 'dart:ui';
import 'package:fire_app/edit_crewmember.dart';
import 'package:fire_app/edit_gear.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Data/crew.dart';
import 'Data/gear.dart';
import 'main.dart';

class GearView extends StatefulWidget {
  const GearView({super.key});



  @override
  State<GearView> createState() => _GearViewState();
}
class _GearViewState extends State<GearView>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gear',
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
              itemCount: crew.gear.length,
              itemBuilder: (context, index) {

                final gear = crew.gear[index];

                // Display gear data in a scrollable list
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
                                gear.name,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold
                                ),
                              ),
                              Text(
                                '${gear.weight} lbs',
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
                                    builder: (context) => EditGear(
                                      gear: gear,
                                      onUpdate: () {
                                        setState(() {});  // Refresh the list
                                      },),
                                  ),
                                );                          }
                          )
                        ],
                      ),
                      leading: const Icon(Icons.work_outline_outlined),
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
