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
        title: Row(
          children: [
            const Text(
            'Gear',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
            Spacer(),
            IconButton(
                onPressed: (){
                  showModalBottomSheet(
                    context: context,
                    builder: (BuildContext context) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: Icon(Icons.delete),
                            title: Text('Delete All Gear'),
                            onTap: () {
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
                                          setState(() {});
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
                                          Navigator.of(context).pop();
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
                            },                        ),
                        ],
                      );
                    },
                  );
                },

                icon: Icon(Icons.more_vert))
        ],
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

          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    // ListView
                    ListView.builder(
                      itemCount: sortedGearList.length,
                      padding: EdgeInsets.only(
                        bottom: 80, // Ensure space for the button at the bottom
                      ),
                      itemBuilder: (context, index) {
                        final gear = sortedGearList[index];
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
                                        gear.name,
                                        style: const TextStyle(
                                            fontSize: 22, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${gear.weight} lbs x ${gear.quantity}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.black, size: 32),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => EditGear(
                                          gear: gear,
                                          onUpdate: loadGearList, // Refresh the list on return
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            leading: const Icon(Icons.work_outline_outlined),
                          ),
                        );
                      },
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
