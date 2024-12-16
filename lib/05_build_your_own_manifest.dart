import 'dart:ui';
import 'package:flutter/cupertino.dart';
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

  void _showSelectionDialog(int selectedLoadIndex) async {
    Map<Gear, int> selectedGearQuantities = {};
    List<dynamic> selectedItems = [];

    bool isCrewExpanded = false;
    bool isGearExpanded = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text(
                'Select Crew Members and Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              contentPadding: const EdgeInsets.all(16),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Crew Dropdown
                        ExpansionPanelList(
                          elevation: 8,
                          expandedHeaderPadding: const EdgeInsets.all(0),
                          expansionCallback: (int index, bool isExpanded) {
                            dialogSetState(() {
                              isCrewExpanded = !isCrewExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: isCrewExpanded,
                              backgroundColor: Colors.deepOrangeAccent,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  child: ListTile(
                                    title: const Text(
                                      'Crew Members',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: crewList.map((crew) {
                                  return Container(
                                    //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0.0),
                                      // Rounded corners
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset:
                                              Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Text(
                                        crew.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        crew.getPositionTitle(crew.position),
                                        style: const TextStyle(
                                            fontStyle: FontStyle.italic),
                                      ),
                                      value: selectedItems.contains(crew),
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          if (isChecked == true) {
                                            selectedItems.add(crew);
                                          } else {
                                            selectedItems.remove(crew);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Gear Dropdown
                        ExpansionPanelList(
                          elevation: 8,
                          expandedHeaderPadding: const EdgeInsets.all(0),
                          expansionCallback: (int index, bool isExpanded) {
                            dialogSetState(() {
                              isGearExpanded = !isGearExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: isGearExpanded,
                              backgroundColor: Colors.deepOrangeAccent,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  //color: Colors.deepOrangeAccent, // Set the background color for the header
                                  child: ListTile(
                                    title: const Text(
                                      'Gear',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: gearList.map((gear) {
                                  int remainingQuantity = gear.quantity -
                                      (selectedGearQuantities[gear] ?? 0);

                                  return Container(
                                    //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(0.0),
                                      // Rounded corners
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset:
                                              Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    gear.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                Text(
                                                  ' (x$remainingQuantity)  ',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (selectedItems.contains(gear))
                                            if (selectedItems.contains(gear))
                                              GestureDetector(
                                                onTap: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                            'Select Quantity for ${gear.name}'),
                                                        content: SizedBox(
                                                          height: 150,
                                                          child:
                                                              CupertinoPicker(
                                                            scrollController:
                                                                FixedExtentScrollController(
                                                              initialItem:
                                                                  (selectedGearQuantities[
                                                                              gear] ??
                                                                          1) -
                                                                      1,
                                                            ),
                                                            itemExtent: 32.0,
                                                            onSelectedItemChanged:
                                                                (int value) {
                                                              dialogSetState(
                                                                  () {
                                                                selectedGearQuantities[
                                                                        gear] =
                                                                    value + 1;
                                                              });
                                                            },
                                                            children: List<
                                                                Widget>.generate(
                                                              gear.quantity,
                                                              // Use the full quantity for selection
                                                              (int index) {
                                                                return Center(
                                                                  child: Text(
                                                                      '${index + 1}'),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () {
                                                              // Finalize the selection
                                                              dialogSetState(
                                                                  () {
                                                                int selectedQuantity =
                                                                    selectedGearQuantities[
                                                                            gear] ??
                                                                        1;
                                                                remainingQuantity =
                                                                    gear.quantity -
                                                                        selectedQuantity;
                                                              });
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                'Confirm'),
                                                          ),
                                                          TextButton(
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                child: Row(
                                                  children: [
                                                    Text(
                                                      'Qty: ${selectedGearQuantities[gear] ?? 1}',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                    const Icon(
                                                        Icons.arrow_drop_down,
                                                        color: Colors.black),
                                                  ],
                                                ),
                                              ),
                                        ],
                                      ),
                                      value: selectedItems.contains(gear),
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          if (isChecked == true) {
                                            selectedItems.add(gear);
                                            selectedGearQuantities[gear] =
                                                1; // Default quantity
                                          } else {
                                            selectedItems.remove(gear);
                                            selectedGearQuantities.remove(gear);
                                          }
                                        });
                                      },
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      for (var item in selectedItems) {
                        if (item is Gear) {
                          // Respect the selected quantity
                          int selectedQuantity =
                              selectedGearQuantities[item] ?? 1;

                          // Create a copy of the gear with the selected quantity
                          Gear gearWithSelectedQuantity = Gear(
                            name: item.name,
                            quantity: selectedQuantity,
                            weight: item
                                .weight, // Weight remains the same for each unit
                          );

                          // Add the gear copy to the load
                          loads[selectedLoadIndex]
                              .add(gearWithSelectedQuantity);

                          // Update the remaining quantity in the original gear list
                          item.quantity -= selectedQuantity;

                          // Remove the gear entirely if no quantity is left
                          if (item.quantity <= 0) {
                            gearList.remove(item);
                          }
                        } else if (item is CrewMember) {
                          // Add crew member directly
                          loads[selectedLoadIndex].add(item);
                          crewList.remove(item);
                        }
                      }
                    });
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to load the list of Gear and CrewMember items from Hive boxes
  void loadItems() {
    setState(() {
      // Create deep copies of the gear and crew member data
      gearList = gearBox.values.map((gear) {
        return Gear(
          name: gear.name,
          quantity: gear.quantity,
          weight: gear.weight,
        );
      }).toList();

      crewList = crewmemberBox.values.map((crew) {
        return CrewMember(
          name: crew.name,
          flightWeight: crew.flightWeight,
          position: crew.position,
        );
      }).toList();
    });
  }

  @override
  void dispose() {
    super.dispose();
    loadItems(); // Reload original data from Hive on back navigation
  }

  void _saveTrip() {
    // Update the trip's loads with the current state of loads on the right side
    widget.trip.loads = loads.asMap().entries.map<Load>((entry) {
      // Use `asMap` to access index
      int index = entry.key;
      List<HiveObject> loadItems = entry.value;

      int loadWeight = loadItems.fold(
          0,
          (sum, item) =>
              sum +
              (item is Gear ? item.weight : (item as CrewMember).flightWeight));

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
        content: Text(
          'Trip Saved!',
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
            sum +
            (item is Gear ? item.weight : (item as CrewMember).flightWeight));
    return totalWeight;
  }

// Function to calculate available seats for a load
  int calculateAvailableSeats(List<HiveObject> loadItems) {
    final totalCrewMembers = loadItems.whereType<CrewMember>().length;
    return totalCrewMembers;
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
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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

          Container(
            color: Colors.grey.withOpacity(0.1),
            child: Scrollbar(
              child: ListView(
                padding: const EdgeInsets.all(8.0),
                children: [
                  ...List.generate(loads.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Section
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey[200],
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(10),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'LOAD #${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  children: [
                                    Container(
                                      height: 30,
                                      child: Row(
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${calculateAvailableWeight(loads[index])}',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  //fontWeight: FontWeight.bold,
                                                  color:
                                                      calculateAvailableWeight(
                                                                  loads[
                                                                      index]) >
                                                              widget.trip
                                                                  .allowable
                                                          ? Colors.red
                                                          : Colors.black,
                                                ),
                                              ),
                                              Text(
                                                '/${widget.trip.allowable} lbs',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  //fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const VerticalDivider(
                                            width: 20,
                                            // Space between text and divider
                                            thickness: 1,
                                            // Thickness of the divider
                                            color:
                                                Colors.black, // Divider color
                                          ),
                                          Row(
                                            children: [
                                              Text(
                                                '${calculateAvailableSeats(loads[index])}',
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    //fontWeight: FontWeight.bold,
                                                    color: calculateAvailableSeats(
                                                                loads[index]) >
                                                            widget.trip
                                                                .availableSeats
                                                        ? Colors.red
                                                        : Colors.black),
                                              ),
                                              Text(
                                                '/${widget.trip.availableSeats} seats',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  //fontWeight: FontWeight.bold,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red, size: 32),
                                  onPressed: () {
                                    setState(() {
                                      // Iterate through the load being deleted
                                      for (var item in loads[index]) {
                                        if (item is Gear) {
                                          // Find the matching gear in the gearList
                                          var existingGear =
                                              gearList.firstWhere(
                                            (gear) => gear.name == item.name,
                                            orElse: () => Gear(
                                                name: item.name,
                                                quantity: 0,
                                                weight: item.weight),
                                          );

                                          // Update the quantity of the gear
                                          existingGear.quantity +=
                                              item.quantity;

                                          // If the gear doesn't exist in the gearList, add it
                                          if (!gearList
                                              .contains(existingGear)) {
                                            gearList.add(existingGear);
                                          }
                                        } else if (item is CrewMember) {
                                          // Ensure crew members are added back only once
                                          if (!crewList.contains(item)) {
                                            crewList.add(item);
                                          }
                                        }
                                      }

                                      // Remove the load from the list
                                      loads.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          // Body Section

                          // Body Section with Add Item Button
                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              children: [
                                for (var item in loads[index])
                                  Card(
                                    elevation: 2,
                                    color: Colors.white,
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 1.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0.0),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "${item is Gear ? item.name : (item as CrewMember).name}, "
                                                "${item is Gear ? item.weight : (item as CrewMember).flightWeight} lbs",
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              Text(
                                                item is Gear
                                                    ? 'Quantity: ${item.quantity}'
                                                    : (item as CrewMember)
                                                        .getPositionTitle(
                                                            item.position),
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                // Ensure the load and item are properly handled
                                                if (loads[index]
                                                    .contains(item)) {
                                                  loads[index].remove(item);

                                                  if (item is Gear) {
                                                    var existingGear =
                                                        gearList.firstWhere(
                                                      (gear) =>
                                                          gear.name ==
                                                          item.name,
                                                      orElse: () => Gear(
                                                          name: item.name,
                                                          quantity: 0,
                                                          weight: item.weight),
                                                    );

                                                    // Update the quantity or add back to the list
                                                    existingGear.quantity +=
                                                        item.quantity;
                                                    if (!gearList.contains(
                                                        existingGear)) {
                                                      gearList
                                                          .add(existingGear);
                                                    }
                                                  } else if (item
                                                      is CrewMember) {
                                                    if (!crewList
                                                        .contains(item)) {
                                                      crewList.add(item);
                                                    }
                                                  }
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Center(
                                  child: GestureDetector(
                                    onTap: () => _showSelectionDialog(index),
                                    // Handle the tap
                                    child: Container(
                                      width: double.infinity,
                                      // Make it span the entire width
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      // Add padding
                                      color: Colors.transparent,
                                      // Background color if desired, or leave transparent
                                      alignment: Alignment.center,
                                      // Center the text
                                      child: const Text(
                                        '+ Add Item',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors
                                              .black, // Change the text color
                                        ),
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
                  }),
                  // Add Load Button
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
        ],
      ),
    );
  }
}
