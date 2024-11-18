import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'Data/gear.dart';
import 'Data/crewmember.dart';
import 'Data/trip.dart';
import 'Data/load.dart';

// TODO: make save button forward off page ??
// TODO: Add crewmember and gear weights below each object -- improve??

class BuildYourOwnManifest extends StatefulWidget {
  final Trip trip;

  const BuildYourOwnManifest({
    super.key,
    required this.trip,
  });

  @override
  State<BuildYourOwnManifest> createState() => _BuildYourOwnManifestState();
}

class _BuildYourOwnManifestState extends State<BuildYourOwnManifest> {
  late final Box<Gear> gearBox;
  late final Box<CrewMember> crewmemberBox;
  late final Box<Trip> tripBox;

  List<Gear> gearList = [];
  List<CrewMember> crewList = [];
  List<List<HiveObject>> loads = [[]]; // Start with one empty load

  @override
  void initState() {
    super.initState();
    gearBox = Hive.box<Gear>('gearBox');
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    tripBox = Hive.box<Trip>('tripBox');
    loadItems();
  }

  // Function to load the list of Gear and CrewMember items from Hive boxes
  void loadItems() {
    setState(() {
      gearList = gearBox.values.toList();
      crewList = crewmemberBox.values.toList();
    });
  }

  void _saveTrip() {
    // Update the trip's loads with the current state of loads on the right side
    widget.trip.loads = loads.asMap().entries.map<Load>((entry) { // Use `asMap` to access index
      int index = entry.key;
      List<HiveObject> loadItems = entry.value;

      int loadWeight = loadItems.fold(0, (sum, item) => sum + (item is Gear ? item.weight : (item as CrewMember).flightWeight));

      return Load(
        loadNumber: index + 1,
        weight: loadWeight,
        loadPersonnel: loadItems.whereType<CrewMember>().toList(),
        loadGear: loadItems.whereType<Gear>().toList(),
      );
    }).toList();

    // Save the updated trip to Hive
    tripBox.put(widget.trip.tripName, widget.trip);

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip Saved!',
          // Maybe change look
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  // Function to calculate available weight for a load
  int calculateAvailableWeight(List<HiveObject> loadItems) {
    final totalWeight = loadItems.fold(
        0,
            (sum, item) =>
        sum + (item is Gear ? item.weight : (item as CrewMember).flightWeight));
    return widget.trip.allowable - totalWeight;
  }

// Function to calculate available seats for a load
  int calculateAvailableSeats(List<HiveObject> loadItems) {
    final totalCrewMembers = loadItems.whereType<CrewMember>().length;
    return widget.trip.availableSeats - totalCrewMembers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text(
          widget.trip.tripName,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
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
          Row(
            children: [
              // Left Side (Draggable Items)
              Expanded(
                flex: 1,
                child: Container(
                  color: Colors.black.withOpacity(0.6),
                  child: Scrollbar(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: gearList.length + crewList.length,
                      itemBuilder: (context, index) {
                        final item = index < gearList.length
                            ? gearList[index]
                            : crewList[index - gearList.length];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Draggable<HiveObject>(
                              data: item,
                              feedback: Material(
                                color: Colors.transparent,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.deepOrangeAccent,
                                  child: Text(
                                    "${item is Gear ? item.name : (item as CrewMember).name}, ${item is Gear ? item.weight : (item as CrewMember).flightWeight} lbs",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                color: Colors.deepOrangeAccent.withOpacity(0.3),
                                child: Center(
                                  child: Text(
                                    "${item is Gear ? item.name : (item as CrewMember).name}, ${item is Gear ? item.weight : (item as CrewMember).flightWeight} lbs",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              onDragCompleted: () {
                                setState(() {
                                  if (item is Gear) {
                                    gearList.remove(item);
                                  } else {
                                    crewList.remove(item);
                                  }
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(8),
                                color: Colors.deepOrangeAccent,
                                child: Center(
                                  child: Text(
                                    item is Gear ? item.name : (item as CrewMember).name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Padding( // Display weight of gear/crewmember under each draggable target.
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                "${item is Gear ? item.weight : (item as CrewMember).flightWeight} lbs",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
              // Right Side (Drop Targets)
              Expanded(
                flex: 2,
                child: Container(
                  color: Colors.grey.withOpacity(0.8),
                  child: Scrollbar(
                    child: ListView(
                      padding: const EdgeInsets.all(8.0),
                      children: [
                        ...List.generate(loads.length, (index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Load ${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        gearList.addAll(
                                            loads[index].whereType<Gear>());
                                        crewList.addAll(
                                            loads[index].whereType<CrewMember>());
                                        loads.removeAt(index);
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                    ),
                                    child: const Text(
                                      'Delete Load',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Available Weight: ${calculateAvailableWeight(loads[index])} lbs',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: calculateAvailableWeight(loads[index]) <
                                        0
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Available Seats: ${calculateAvailableSeats(loads[index])}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: calculateAvailableSeats(loads[index]) <
                                        0
                                        ? Colors.red
                                        : Colors.black,
                                  ),
                                ),
                              ),
                              DragTarget<HiveObject>(
                                builder: (context, candidateData, rejectedData) {
                                  return Container(
                                    width: double.infinity,
                                    height: 150 + (loads[index].length * 40),
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 8),
                                    color: Colors.white.withOpacity(0.2),
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      children: [
                                        for (var item in loads[index])
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${item is Gear ? item.name : (item as CrewMember).name}, ${item is Gear ? item.weight : (item as CrewMember).flightWeight} lbs",
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                                onPressed: () {
                                                  setState(() {
                                                    loads[index].remove(item);
                                                    if (item is Gear) {
                                                      gearList.add(item);
                                                    } else if (item
                                                    is CrewMember) {
                                                      crewList.add(item);
                                                    }
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  );
                                },
                                onWillAccept: (data) => true,
                                onAccept: (data) {
                                  setState(() {
                                    loads[index].add(data);
                                  });
                                },
                              ),
                            ],
                          );
                        }),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                loads.add([]);
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                            ),
                            child: const Text(
                              'Add Load',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}



