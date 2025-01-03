import 'dart:ui';
import 'package:fire_app/03_edit_gear.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'Data/crew.dart';
import 'Data/gear.dart';


class GearView extends StatefulWidget {
  const GearView({super.key});



  @override
  State<GearView> createState() => _GearViewState();
}
class _GearViewState extends State<GearView>{

  late final Box<Gear> gearBox;
  List<Gear> gearList = [];

  @override
  void initState() {
    super.initState();

    // Open the Hive box and load the list of Gear items
    gearBox = Hive.box<Gear>('gearBox');
    loadGearList();
  }

  // Function to load the list of Gear items from the Hive box
  void loadGearList() {
    setState(() {
      gearList = gearBox.values.toList();
    });
  }

  @override
  Widget build(BuildContext context) {

    List<Gear> sortedGearList = sortGearListAlphabetically(gearList);

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
            child: Column(
              children: [
                Expanded(
                child: ListView.builder(
                  itemCount: sortedGearList.length,
                  itemBuilder: (context, index) {

                    final gear = sortedGearList[index];

                    // Display gear data
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
                              Expanded(
                                child: Column(
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
                                      '${gear.weight} lbs x ${gear.quantity}',
                                      style: const TextStyle(
                                        fontSize:16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  ],
                                ),
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
                                          onUpdate: loadGearList, // Refresh the list on return
                                        ),
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

                // Delete All
                Padding(
                  padding:
                  const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
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
                              'Are you sure you want to delete all gear?',
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
                                  crew.deleteAllGear();
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
                            'Delete All Gear',
                            style: const TextStyle(
                              fontSize: 24,
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
    );
  }
}
