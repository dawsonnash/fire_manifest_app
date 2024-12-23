import 'dart:ui';
import 'package:fire_app/06_saved_trips.dart';
import 'package:fire_app/06_single_trip_view.dart';
import 'package:fire_app/Data/crew.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'Data/gear.dart';
import 'Data/crewmember.dart';
import 'Data/trip.dart';
import 'Data/load.dart';
import 'Data/customItem.dart';

// Double integers when calculating quantity dont always work out. a 45 lb QB can become 44

class BuildYourOwnManifest extends StatefulWidget {
  final Trip trip;

  const BuildYourOwnManifest({
    super.key,
    required this.trip,
  });

  @override
  State<BuildYourOwnManifest> createState() => _BuildYourOwnManifestState();
}

// This is what displays on each load
String itemDisplay(dynamic item) {
  if (item is Gear) {
    return "${item.name}, ${item.weight} lbs";
  } else if (item is CrewMember) {
    return "${item.name}, ${item.flightWeight} lbs";
  } else if (item is CustomItem) {
    return "${item.name}, ${item.weight} lbs";
  } else {
    return "Unknown item type";
  }
}




class _BuildYourOwnManifestState extends State<BuildYourOwnManifest> {
  late final Box<Gear> gearBox;
  late final Box<CrewMember> crewmemberBox;
  late final Box<Trip> tripBox;

  List<bool> _isExpanded = [];

  List<Gear> gearList = [];
  List<CrewMember> crewList = [];
  List<List<dynamic>> loads = [[]]; // Allow multiple types

  @override
  void initState() {
    super.initState();
    gearBox = Hive.box<Gear>('gearBox');
    crewmemberBox = Hive.box<CrewMember>('crewmemberBox');
    tripBox = Hive.box<Trip>('tripBox');
    _isExpanded = List.generate(loads.length, (_) => true);
    loadItems();
  }

  void _showSelectionDialog(int selectedLoadIndex) async {
    Map<Gear, int> selectedGearQuantities = {};
    List<dynamic> selectedItems = [];

    List<CrewMember> sortedCrewList = sortCrewListByPosition(crewList);
    List<Gear> sortedGearList = sortGearListAlphabetically(gearList);
    bool isCrewExpanded = false;
    bool isGearExpanded = false;
    bool isCustomItemExpanded = false;

    String customItemName = '';
    int customItemWeight = 0;
    int customItemQuantity = 1;

    // Define focus nodes for each TextField
    final customItemNameFocus = FocusNode();
    final customItemWeightFocus = FocusNode();
    final customItemQuantityFocus = FocusNode();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: const Text(
                'Add Crew Members and Gear',
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
                        // Crew Member Dropdown
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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: sortedCrewList.map((crew) {
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
                                          offset: Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Text(
                                        ' ${crew.name}, ${crew.flightWeight} lbs',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        crew.getPositionTitle(crew.position),
                                        style: const TextStyle(fontStyle: FontStyle.italic),
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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: sortedGearList.map((gear) {
                                  int remainingQuantity = gear.quantity - (selectedGearQuantities[gear] ?? 0);

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
                                          offset: Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    gear.name,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                    overflow: TextOverflow.ellipsis,
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
                                                  final int gearQuantity = gear.quantity;
                                                  if (gearQuantity > 1) {
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext context) {
                                                        return AlertDialog(
                                                          title: Text('Select Quantity for ${gear.name}'),
                                                          content: SizedBox(
                                                            height: 150,
                                                            child: CupertinoPicker(
                                                              scrollController: FixedExtentScrollController(
                                                                initialItem: (selectedGearQuantities[gear] ?? 1) - 1,
                                                              ),
                                                              itemExtent: 32.0,
                                                              onSelectedItemChanged: (int value) {
                                                                dialogSetState(() {
                                                                  selectedGearQuantities[gear] = value + 1;
                                                                });
                                                              },
                                                              children: List<Widget>.generate(
                                                                gear.quantity,
                                                                // Use the full quantity for selection
                                                                (int index) {
                                                                  return Center(
                                                                    child: Text('${index + 1}'),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                // Finalize the selection
                                                                dialogSetState(() {
                                                                  int selectedQuantity = selectedGearQuantities[gear] ?? 1;
                                                                  remainingQuantity = gear.quantity - selectedQuantity;
                                                                });
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: const Text('Confirm'),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: const Text('Cancel'),
                                                            ),
                                                          ],
                                                        );
                                                      },
                                                    );
                                                  }
                                                },
                                                child: Row(
                                                  children: [
                                                    if (gear.quantity > 1)
                                                      Text(
                                                        'Qty: ${selectedGearQuantities[gear] ?? 1}',
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 14,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    if (gear.quantity > 1) const Icon(Icons.arrow_drop_down, color: Colors.black),
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
                                            selectedGearQuantities[gear] = 1; // Default quantity
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
                        const SizedBox(height: 16),

                        // Custom Item Dropdown
                        ExpansionPanelList(
                          expansionCallback: (index, isExpanded) {
                            dialogSetState(() {
                              isCustomItemExpanded = !isCustomItemExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: isCustomItemExpanded,
                              backgroundColor: Colors.deepOrangeAccent,
                              headerBuilder: (context, isExpanded) => ListTile(
                                title: const Text(
                                  'Add Custom Item',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              body: Container(
                                color: Colors.white,
                                child: Column(
                                  children: [
                                    // Custom Item Name Field
                                    TextField(
                                      decoration: const InputDecoration(labelText: 'Item Name'),
                                      textCapitalization: TextCapitalization.words,
                                      focusNode: customItemNameFocus,
                                      // Attach focus node
                                      textInputAction: TextInputAction.next,
                                      // Specify the action
                                      onSubmitted: (_) {
                                        // Move focus to the next field
                                        FocusScope.of(context).requestFocus(customItemWeightFocus);
                                      },
                                      onChanged: (value) {
                                        customItemName = value;
                                      },
                                    ),
                                    const SizedBox(height: 8),

                                    // Custom Item Weight Field
                                    TextField(
                                      decoration: const InputDecoration(labelText: 'Weight (lbs)'),
                                      keyboardType: TextInputType.number,
                                      focusNode: customItemWeightFocus,
                                      // Attach focus node
                                      textInputAction: TextInputAction.next,
                                      // Specify the action
                                      onSubmitted: (_) {
                                        // Move focus to the next field
                                        FocusScope.of(context).requestFocus(customItemQuantityFocus);
                                      },
                                      onChanged: (value) {
                                        customItemWeight = int.tryParse(value) ?? 0;
                                      },
                                    ),
                                  ],
                                ),
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
                      // Add selected custom item if name and weight are provided
                      if (customItemName.isNotEmpty && customItemWeight > 0) {
                        // Add the custom item to the load
                        loads[selectedLoadIndex].add(
                          CustomItem(
                            name: customItemName,
                            weight: customItemWeight,
                          ),
                        );

                        // Clear fields after adding
                        customItemName = '';
                        customItemWeight = 0;
                        customItemQuantity = 1;
                      }

                      for (var item in selectedItems) {
                        if (item is Gear) {
                          // Respect the selected quantity
                          int selectedQuantity = selectedGearQuantities[item] ?? 1;

                          // Check if a gear with the same name already exists in the load
                          final existingGearIndex = loads[selectedLoadIndex].indexWhere(
                            (loadItem) => loadItem is Gear && loadItem.name == item.name,
                          );

                          if (existingGearIndex != -1) {
                            // If it exists, update its quantity and weight
                            Gear existingGear = loads[selectedLoadIndex][existingGearIndex] as Gear;
                            existingGear.quantity += selectedQuantity;
                            existingGear.weight = existingGear.quantity * item.weight; // Recalculate weight
                          } else {
                            // If it doesn't exist, add the new gear item to the load
                            loads[selectedLoadIndex].add(
                              Gear(
                                name: item.name,
                                quantity: selectedQuantity,
                                weight: item.weight * selectedQuantity, // Calculate total weight
                                isPersonalTool: item.isPersonalTool,
                              ),
                            );
                          }

                          // Update the remaining quantity in the original inventory
                          item.quantity -= selectedQuantity;
                          if (item.quantity <= 0) {
                            gearList.remove(item);
                          }
                        } else if (item is CrewMember) {
                          // Add crew member directly
                          loads[selectedLoadIndex].add(item);

                          // Loop through and add all personal tools
                          if (item.personalTools != null) {
                            for (var tool in item.personalTools!) {
                              final existingToolIndex = loads[selectedLoadIndex].indexWhere(
                                (loadItem) => loadItem is Gear && loadItem.name == tool.name,
                              );

                              if (existingToolIndex != -1) {
                                // Update the existing tool's quantity and weight
                                Gear existingTool = loads[selectedLoadIndex][existingToolIndex] as Gear;
                                existingTool.quantity += tool.quantity;
                                existingTool.weight = existingTool.quantity * tool.weight;
                              } else {
                                // Add the tool as a new gear item
                                loads[selectedLoadIndex].add(
                                  Gear(
                                    name: tool.name,
                                    quantity: tool.quantity,
                                    weight: tool.weight * tool.quantity,
                                    isPersonalTool: tool.isPersonalTool,
                                  ),
                                );
                              }
                            }
                          }

                          // Remove crew member from the available list
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
          isPersonalTool: gear.isPersonalTool,
        );
      }).toList();

      crewList = crewmemberBox.values.map((crew) {
        return CrewMember(
          name: crew.name,
          flightWeight: crew.flightWeight,
          position: crew.position,
          personalTools: crew.personalTools,
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
    widget.trip.loads = loads.asMap().entries.map<Load>((entry) {
      int index = entry.key;
      List loadItems = entry.value;

      int loadWeight = loadItems.fold(0, (sum, item) {
        if (item is Gear) {
          return sum + (item.weight * item.quantity);
        } else if (item is CrewMember) {
          return sum + item.flightWeight;
        } else if (item is CustomItem) {
          return sum + item.weight;
        }
        return sum;
      });

      return Load(
        loadNumber: index + 1,
        weight: loadWeight,
        loadPersonnel: loadItems.whereType<CrewMember>().toList(),
        loadGear: loadItems.whereType<Gear>().toList(),
        customItems: loadItems.whereType<CustomItem>().toList(), // Save CustomItems
      );
    }).toList();

    // Save the updated trip to Hive
    tripBox.put(widget.trip.tripName, widget.trip);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Trip Saved!',
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SingleTripView(trip: widget.trip),
      ),
    );
  }

  // Function to calculate available weight for a load
  int calculateAvailableWeight(List<dynamic> loadItems) {
    final totalWeight = loadItems.fold(0, (sum, item) {
      if (item is Gear) {
        return sum + item.weight; // Use the total weight directly
      } else if (item is CrewMember) {
        return sum + item.flightWeight;
      } else if (item is CustomItem) {
        return sum + item.weight;
      } else {
        return sum; // Unknown type, ignore it
      }
    });
    return totalWeight;
  }

// Function to calculate available seats for a load
  int calculateAvailableSeats(List<dynamic> loadItems) {
    final totalCrewMembers = loadItems.whereType<CrewMember>().length;
    return totalCrewMembers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.trip.tripName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              'Allowable: ${widget.trip.allowable} lbs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
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
                    // Track expanded state for each load
                    bool isExpanded = _isExpanded[index];

                    // Sort the load dynamically by CrewMember first, then Gear
                    loads[index].sort((a, b) {
                      if (a is CrewMember && b is Gear) {
                        return -1; // CrewMember comes before Gear
                      } else if (a is Gear && b is CrewMember) {
                        return 1; // Gear comes after CrewMember
                      } else {
                        return 0; // Keep original order if they are the same type
                      }
                    });

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
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
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded[index] = !_isExpanded[index];
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                    ? Colors.black // Warning color
                                    : Colors.deepOrangeAccent, // Normal color
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(10),
                                  bottom: Radius.circular(10),
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
                                        style: TextStyle(
                                          color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                              ? Colors.white // Warning color
                                              : Colors.black,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                                        decoration: BoxDecoration(
                                          color: Colors.transparent,
                                          // Background color
                                          borderRadius: BorderRadius.circular(10), // Rounded corners
                                        ),
                                        height: 30,
                                        child: Row(
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  '${calculateAvailableWeight(loads[index])} lbs',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                                        ? Colors.white // Warning color
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            VerticalDivider(
                                              width: 20,
                                              // Space between text and divider
                                              thickness: 1,
                                              // Thickness of the divider
                                              color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                                  ? Colors.white // Warning color
                                                  : Colors.black, // Divider color
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '${calculateAvailableSeats(loads[index])}',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                                        ? Colors.white // Warning color
                                                        : Colors.black,
                                                  ),
                                                ),
                                                Text(
                                                  '/${widget.trip.availableSeats} seats',
                                                  style: TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                    color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                                        ? Colors.white // Warning color
                                                        : Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Load deletion Icon
                                  IconButton(
                                    icon: Icon(Icons.delete,
                                        color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                            ? Colors.white // Warning color
                                            : Colors.black,
                                        size: 32),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text(
                                              'Confirm Deletion',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            content: const Text(
                                              'Are you sure you want to delete this load?',
                                              style: TextStyle(fontSize: 16),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Close the dialog without deleting
                                                },
                                                child: const Text(
                                                  'Cancel',
                                                  style: TextStyle(color: Colors.grey),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  // Execute deletion logic
                                                  setState(() {
                                                    // Iterate through all items in the load
                                                    for (var item in loads[index]) {
                                                      if (item is CrewMember) {
                                                        // Add crew member back to the crew list
                                                        if (!crewList.contains(item)) {
                                                          crewList.add(item);
                                                        }
                                                      } else if (item is Gear) {
                                                        if (item.isPersonalTool) {
                                                          gearList.removeWhere((gear) => gear.name == item.name && gear.isPersonalTool);
                                                        } else {
                                                          // General gear: update or add back to gearList
                                                          final existingGear = gearList.firstWhere(
                                                            (gear) => gear.name == item.name && !gear.isPersonalTool,
                                                            orElse: () => Gear(name: item.name, quantity: 0, weight: item.weight ~/ item.quantity),
                                                          );

                                                          existingGear.quantity += item.quantity;

                                                          // Add to gearList if it's not already present
                                                          if (!gearList.contains(existingGear)) {
                                                            gearList.add(existingGear);
                                                          }
                                                        }
                                                      }
                                                    }
                                                    // Remove all personal tools from the gearList
                                                    gearList.removeWhere((gear) => gear.isPersonalTool);

                                                    // Remove the load from the list
                                                    loads.removeAt(index);
                                                    _isExpanded.removeAt(index); // Ensure the lists stay in sync
                                                  });

                                                  Navigator.of(context).pop(); // Close the dialog after deletion
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

                                  // Expansion Icon
                                  Icon(
                                    isExpanded ? Icons.expand_less : Icons.expand_more,
                                    color: calculateAvailableWeight(loads[index]) > widget.trip.allowable || calculateAvailableSeats(loads[index]) > widget.trip.availableSeats
                                        ? Colors.white // Warning color
                                        : Colors.black,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Body Section with Add Item Button
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.all(0.0),
                              child: Column(
                                children: [
                                  if (calculateAvailableWeight(loads[index]) > widget.trip.allowable)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 1.0),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          // Background color
                                          borderRadius: BorderRadius.circular(8),
                                          // Rounded corners
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'OVERWEIGHT',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 1.0), // Adjust padding as needed
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          // Background color
                                          borderRadius: BorderRadius.circular(8),
                                          // Rounded corners
                                        ),
                                        alignment: Alignment.center,
                                        child: const Text(
                                          'NOT ENOUGH SEATS',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),

                                  for (var item in loads[index]
                                    ..sort((a, b) {
                                      if (a is CustomItem && (b is Gear || b is CrewMember)) {
                                        return 1; // CustomItem comes after Gear or CrewMember
                                      } else if ((a is Gear || a is CrewMember) && b is CustomItem) {
                                        return -1; // Gear or CrewMember comes before CustomItem
                                      }
                                      return 0; // Keep relative order for same types
                                    }))
                                    // Swipe Deletion
                                    Dismissible(
                                      key: ValueKey(item),
                                      // Unique key for each item
                                      direction: DismissDirection.endToStart,
                                      // Allow swipe from right to left
                                      background: Container(
                                        color: Colors.red,
                                        // Red background for delete action
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        child: const Icon(Icons.delete, color: Colors.white), // Trash icon
                                      ),
                                      onDismissed: (direction) {
                                        setState(() {
                                          if (loads[index].contains(item)) {
                                            loads[index].remove(item);

                                            if (item is Gear) {
                                              var existingGear = gearList.firstWhere(
                                                (gear) => gear.name == item.name,
                                                orElse: () => Gear(
                                                  name: item.name,
                                                  quantity: 0,
                                                  weight: item.weight ~/ item.quantity, // Correct per-unit weight
                                                  isPersonalTool: item.isPersonalTool,
                                                ),
                                              );

                                              // Update the quantity and total weight
                                              existingGear.quantity += item.quantity;

                                              if (!gearList.contains(existingGear)) {
                                                gearList.add(existingGear);
                                              }
                                            } else if (item is CrewMember) {
                                              // Handle personal tools
                                              if (item.personalTools != null) {
                                                for (var tool in item.personalTools!) {
                                                  // Check if the tool exists in the gearList first
                                                  final gearListIndex = gearList.indexWhere(
                                                        (gear) => gear.name == tool.name,
                                                  );

                                                  if (gearListIndex != -1) {
                                                    // Decrement the quantity of the tool in the gearList
                                                    Gear gearTool = gearList[gearListIndex];
                                                    gearTool.quantity -= tool.quantity;
                                                    gearTool.weight -= tool.weight * tool.quantity; // Adjust weight

                                                    // If the quantity reaches zero, remove the tool from the gearList
                                                    if (gearTool.quantity <= 0) {
                                                      gearList.removeAt(gearListIndex);
                                                    }
                                                  } else {
                                                    // Check if the tool exists in the current load
                                                    final toolIndex = loads[index].indexWhere(
                                                          (loadItem) => loadItem is Gear && loadItem.name == tool.name,
                                                    );

                                                    if (toolIndex != -1) {
                                                      // Decrement the quantity of the tool in the load
                                                      Gear loadTool = loads[index][toolIndex];
                                                      loadTool.quantity -= tool.quantity;
                                                      loadTool.weight -= tool.weight * tool.quantity; // Adjust weight

                                                      // If the quantity reaches zero, remove the tool from the load
                                                      if (loadTool.quantity <= 0) {
                                                        loads[index].removeAt(toolIndex);
                                                      }
                                                    }
                                                  }
                                                }
                                              }

                                              // Add the crew member back to the crew list if necessary
                                              if (!crewList.contains(item)) {
                                                crewList.add(item);
                                              }
                                            }
                                          }
                                        });
                                      },
                                      child: Card(
                                        elevation: 2,
                                        color: item is CrewMember
                                            ? Colors.white // Color for CrewMembers
                                            : item is Gear && item.isPersonalTool == true
                                                ? Colors.blue[100] // Color for personal tools
                                                : Colors.orange[100],
                                        // Color for regular Gear
                                        // Different colors for CrewMember and Gear
                                        margin: const EdgeInsets.symmetric(vertical: 1.0),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8.0), // Rounded corners
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    itemDisplay(item),
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    item is Gear
                                                        ? 'Quantity: ${item.quantity}'
                                                        : item is CrewMember
                                                            ? item.getPositionTitle(item.position)
                                                            : '',
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                      fontStyle: FontStyle.italic,
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              // Single Item Deletion
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red),
                                                onPressed: () {
                                                  setState(() {
                                                    if (loads[index].contains(item)) {


                                                      if (item is Gear) {
                                                        if (item.quantity > 1) {
                                                          showDialog(
                                                            context: context,
                                                            builder: (BuildContext context) {
                                                              int quantityToRemove = 1; // Default to 1 for selection
                                                              return StatefulBuilder(
                                                                  builder: (BuildContext context, StateSetter setDialogState) {
                                                                    return AlertDialog(
                                                                      title: Text('Remove ${item.name}'),
                                                                      content: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          Text('Select the quantity to remove:'),
                                                                          SizedBox(height: 8),
                                                                          DropdownButton<int>(
                                                                            value: quantityToRemove,
                                                                            items: List.generate(
                                                                              item.quantity,
                                                                                  (index) =>
                                                                                  DropdownMenuItem(
                                                                                    value: index + 1,
                                                                                    child: Text('${index + 1}'),
                                                                                  ),
                                                                            ),
                                                                            onChanged: (value) {
                                                                              setDialogState(() {
                                                                                quantityToRemove = value ?? 1; // Update dialog state
                                                                              });
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () {
                                                                            Navigator.of(context).pop(); // Cancel action
                                                                          },
                                                                          child: const Text('Cancel'),
                                                                        ),
                                                                        TextButton(
                                                                          onPressed: () {
                                                                            setState(() {
                                                                              // Deduct the selected quantity from the load item
                                                                              // item is in load. existingGear is in inventory
                                                                              var originalWeight = item.weight ~/ item.quantity;
                                                                              item.quantity -= quantityToRemove;
                                                                              item.weight -= (item.weight ~/ (item.quantity + quantityToRemove)) * quantityToRemove;

                                                                              // Handle returning the removed item to the inventory
                                                                              var existingGear = gearList.firstWhere(
                                                                                    (gear) => gear.name == item.name,
                                                                                orElse: () => Gear(
                                                                                  name: item.name,
                                                                                  quantity: 0,
                                                                                  weight: 0,
                                                                                  isPersonalTool: item.isPersonalTool,
                                                                                ),
                                                                              );

                                                                              // Update the quantity
                                                                              existingGear.quantity += quantityToRemove;
                                                                              existingGear.weight = originalWeight;

                                                                              if (!gearList.contains(existingGear)) {
                                                                                gearList.add(existingGear);
                                                                              }

                                                                              // Remove the item from the load if its quantity reaches zero
                                                                              if (item.quantity <= 0) {
                                                                                loads[index].remove(item);
                                                                              }
                                                                            });

                                                                            Navigator.of(context).pop(); // Close the dialog
                                                                          },
                                                                          child: const Text('Remove'),
                                                                        ),
                                                                      ],
                                                                    );
                                                                  }
                                                              );
                                                            },
                                                          );
                                                        }
                                                        else {
                                                          loads[index].remove(item);
                                                          var existingGear = gearList.firstWhere(
                                                            (gear) => gear.name == item.name,
                                                            orElse: () => Gear(
                                                              name: item.name,
                                                              quantity: 0,
                                                              weight: item.weight ~/ item.quantity, // Correct per-unit weight
                                                              isPersonalTool: item.isPersonalTool,
                                                            ),
                                                          );

                                                          // Update the quantity
                                                          existingGear.quantity += item.quantity;

                                                          if (!gearList.contains(existingGear)) {
                                                            gearList.add(existingGear);
                                                          }
                                                        }
                                                      }
                                                      else if (item is CrewMember) {
                                                        // Handle personal tools
                                                        if (item.personalTools != null) {
                                                          for (var tool in item.personalTools!) {
                                                            // Check if the tool exists in the gearList first
                                                            final gearListIndex = gearList.indexWhere(
                                                                  (gear) => gear.name == tool.name,
                                                            );

                                                            if (gearListIndex != -1) {
                                                              // Decrement the quantity of the tool in the gearList
                                                              Gear gearTool = gearList[gearListIndex];
                                                              gearTool.quantity -= tool.quantity;
                                                              gearTool.weight -= tool.weight * tool.quantity; // Adjust weight

                                                              // If the quantity reaches zero, remove the tool from the gearList
                                                              if (gearTool.quantity <= 0) {
                                                                gearList.removeAt(gearListIndex);
                                                              }
                                                            } else {
                                                              // Check if the tool exists in the current load
                                                              final toolIndex = loads[index].indexWhere(
                                                                    (loadItem) => loadItem is Gear && loadItem.name == tool.name,
                                                              );

                                                              if (toolIndex != -1) {
                                                                // Decrement the quantity of the tool in the load
                                                                Gear loadTool = loads[index][toolIndex];
                                                                loadTool.quantity -= tool.quantity;
                                                                loadTool.weight -= tool.weight * tool.quantity; // Adjust weight

                                                                // If the quantity reaches zero, remove the tool from the load
                                                                if (loadTool.quantity <= 0) {
                                                                  loads[index].removeAt(toolIndex);
                                                                }
                                                              }
                                                            }
                                                          }
                                                        }

                                                        // Add the crew member back to the crew list if necessary
                                                        if (!crewList.contains(item)) {
                                                          crewList.add(item);
                                                        }
                                                        loads[index].remove(item);
                                                      }
                                                      else if (item is CustomItem){
                                                        loads[index].remove(item);
                                                      }
                                                    }
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  //const SizedBox(height: 4),

                                  SizedBox(height: 2),

                                  GestureDetector(
                                    onTap: () => _showSelectionDialog(index),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        // Background color
                                        borderRadius: BorderRadius.circular(8),
                                        // Rounded corners
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        '+ Add Item',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
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
                          // Add a new empty load
                          loads.add([]);

                          // Add a corresponding false entry to `_isExpanded` for the new load
                          _isExpanded.add(true);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
