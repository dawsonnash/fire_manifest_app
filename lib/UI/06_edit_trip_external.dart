import 'dart:ui';
import 'package:fire_app/Data/load_accoutrements.dart';
import 'package:fire_app/UI/06_saved_trips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../CodeShare/colors.dart';
import '../Data/gear.dart';
import '../Data/crewmember.dart';
import '../Data/sling.dart';
import '../Data/trip.dart';
import '../Data/load.dart';
import '../Data/customItem.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Double integers when calculating quantity dont always work out. a 45 lb QB can become 44
// Update: Maybe fixed?
class EditTripExternal extends StatefulWidget {
  final Trip trip;

  const EditTripExternal({
    super.key,
    required this.trip,
  });

  @override
  State<EditTripExternal> createState() => _EditTripExternalState();
}

class _EditTripExternalState extends State<EditTripExternal> {
  late final Box<Gear> gearBox;
  late final Box<Trip> tripBox;

  List<bool> _isExpanded = [];
  List<List<bool>> _isSlingExpanded = [];

  List<Gear> gearList = [];
  List<Load> loads = [];

  @override
  void initState() {
    super.initState();
    gearBox = Hive.box<Gear>('gearBox');
    tripBox = Hive.box<Trip>('tripBox');
    loads = widget.trip.loads.toList();

    // Initialize expansion states for loads and slings
    _isExpanded = List.generate(widget.trip.loads.length, (_) => false);
    _isSlingExpanded = List.generate(widget.trip.loads.length, (loadIndex) => List.generate(widget.trip.loads[loadIndex].slings?.length ?? 0, (_) => false));

    loadItems();
  }

  // Can make weights user variables later on
  double getAccoutrementWeight(String name) {
    switch (name) {
      case "Cargo Net (20'x20')": return 45.0;
      case "Cargo Net (12'x12')": return 20.0;
      case "Lead Line": return 10.0;
      case "Swivel": return 5.0;
      default: return 0.0;
    }
  }

  // This is what displays on each load
  String itemDisplayEditTrip(dynamic item) {
    if (item is Gear) {
      return "${item.name}, ${item.totalGearWeight} lbs";
    } else if (item is LoadAccoutrement) {
      return "${item.name}, ${item.weight} lbs";
    } else if (item is CustomItem) {
      return "${item.name}, ${item.weight} lbs";
    } else {
      return "Unknown item type";
    }
  }

  void _showSelectionDialog(int selectedLoadIndex, int selectedSlingIndex) async {
    Map<Gear, int> selectedGearQuantities = {};
    List<dynamic> selectedItems = [];

    List<Gear> sortedGearList = sortGearListAlphabetically(gearList);
    bool isLoadAccoutrementExpanded = false;
    bool isGearExpanded = false;
    bool isCustomItemExpanded = false;

    String customItemName = '';
    int customItemWeight = 0;
    int customItemQuantity = 1;

    // Define focus nodes for each TextField
    final customItemNameFocus = FocusNode();
    final customItemWeightFocus = FocusNode();
    final customItemQuantityFocus = FocusNode();

    // Define all possible Load Accoutrements
    final List<String> allLoadAccoutrements = [
      "Cargo Net (20'x20')",
      "Cargo Net (12'x12')",
      "Lead Line",
      "Swivel"
    ];

    // Get existing accoutrements in **only this specific sling**
    final List<String> existingSlingAccoutrements = loads[selectedLoadIndex]
        .slings![selectedSlingIndex]
        .loadAccoutrements
        .map((acc) => acc.name)
        .toList();

    // Define net types (so we can check for any net in this sling)
    const List<String> netTypes = ['Cargo Net (20\'x20\')', 'Cargo Net (12\'x12\')'];

    // Check if **any net** already exists in **this sling only**
    bool netExistsInSling = existingSlingAccoutrements.any((acc) => netTypes.contains(acc));

    // **Filter available accoutrements for this sling**
    final List<String> availableAccoutrements = allLoadAccoutrements.where((acc) {

      if (existingSlingAccoutrements.contains(acc)) return false;

      if (netTypes.contains(acc) && netExistsInSling) return false;

      return true;
    }).toList();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Add Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textColorPrimary),
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

                        // Load Accoutrement Dropdown
                        ExpansionPanelList(
                          elevation: 8,
                          expandedHeaderPadding: const EdgeInsets.all(0),
                          expansionCallback: (int index, bool isExpanded) {
                            dialogSetState(() {
                              isLoadAccoutrementExpanded = !isLoadAccoutrementExpanded;
                            });
                          },
                          children: [
                            ExpansionPanel(
                              isExpanded: isLoadAccoutrementExpanded,
                              backgroundColor: AppColors.fireColor,
                              headerBuilder: (context, isExpanded) {
                                return ListTile(
                                  title: const Text(
                                    'Load Accoutrements',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                );
                              },
                              body: Column(
                                children: availableAccoutrements .where((accName) {
                                  // Determine which net (if any) is already selected
                                  String? selectedNet = selectedItems
                                      .whereType<LoadAccoutrement>()
                                      .map((acc) => acc.name)
                                      .firstWhere((name) => netTypes.contains(name), orElse: () => '');

                                  // If a net is selected, hide the *opposite* one
                                  if (selectedNet.isNotEmpty && netTypes.contains(accName) && accName != selectedNet) {
                                    return false; // Hide the other net
                                  }
                                  return true; // Keep other items visible
                                }).map((accName) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.gearYellow,
                                      borderRadius: BorderRadius.circular(0.0),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      title: Text(
                                        accName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                            color: Colors.black

                                        ),
                                      ),
                                      value:  selectedItems.any((item) => item is LoadAccoutrement && item.name == accName),
                                      onChanged: (bool? isChecked) {
                                        dialogSetState(() {
                                          if (isChecked == true) {
                                            // Convert and add LoadAccoutrement object
                                            selectedItems.add(LoadAccoutrement(
                                              name: accName,
                                              quantity: 1, // Always 1 per load
                                              weight: getAccoutrementWeight(accName).toInt(),
                                            ));
                                          } else {
                                            // Remove based on name match
                                            selectedItems.removeWhere((item) => item is LoadAccoutrement && item.name == accName);
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
                              backgroundColor: AppColors.fireColor,
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
                                      color: gear.isPersonalTool
                                          ? AppColors.toolBlue // Color for personal tools
                                          : AppColors.gearYellow,
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
                                                    color: Colors.black,
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
                                                          backgroundColor: AppColors.textFieldColor2,
                                                          title: Text(
                                                            'Select Quantity for ${gear.name}',
                                                            style: TextStyle(color: AppColors.textColorPrimary),
                                                          ),
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
                                                                    child: Text('${index + 1}', style: TextStyle(color: AppColors.textColorPrimary)),
                                                                  );
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () {
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton)),
                                                            ),
                                                            TextButton(
                                                              onPressed: () {
                                                                // Finalize the selection
                                                                dialogSetState(() {
                                                                  int selectedQuantity = selectedGearQuantities[gear] ?? 1;
                                                                  remainingQuantity = gear.quantity - selectedQuantity;
                                                                });
                                                                Navigator.of(context).pop();
                                                              },
                                                              child: Text('Confirm', style: TextStyle(color: AppColors.saveButtonAllowableWeight)),
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
                                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textColorSecondary),
                                                      ),
                                                    if (gear.quantity > 1) Icon(Icons.arrow_drop_down, color: AppColors.textColorSecondary),
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
                              backgroundColor: AppColors.fireColor,
                              headerBuilder: (context, isExpanded) => GestureDetector(
                                onLongPress: () {
                                  showModalBottomSheet(
                                    backgroundColor: AppColors.textFieldColor2,
                                    context: context,
                                    isScrollControlled: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                    ),
                                    builder: (BuildContext context) {
                                      return Container(
                                        padding: EdgeInsets.all(16.0),
                                        height: MediaQuery.of(context).size.height * 0.7,
                                        // 70% of the screen height
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Modal Title
                                            Text(
                                              'IRPG Item Weights',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 20,
                                                color: AppColors.textColorPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Scrollable List of IRPG Items
                                            Expanded(
                                              child: ListView.builder(
                                                itemCount: irpgItems.length,
                                                itemBuilder: (context, index) {
                                                  final item = irpgItems[index];
                                                  return Container(
                                                    margin: EdgeInsets.symmetric(vertical: 4.0),
                                                    child: ListTile(
                                                      contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 0.0),
                                                      title: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            item['name'],
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: AppColors.textColorPrimary,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${item['weight']} lbs',
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              color: AppColors.textColorPrimary,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),

                                            // Cancel Button
                                            Align(
                                              alignment: Alignment.bottomRight,
                                              child: TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Close the modal
                                                },
                                                child: Text(
                                                  'Cancel',
                                                  style: TextStyle(
                                                    color: AppColors.cancelButton,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                                child: ListTile(
                                  title: const Text(
                                    'Custom Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              body: Container(
                                color: AppColors.textFieldColor2,
                                child: Column(
                                  children: [
                                    // Custom Item Name Field
                                    TextField(
                                      decoration: InputDecoration(
                                        labelText: 'Item Name',
                                        labelStyle: TextStyle(color: AppColors.textColorPrimary), // Label color
                                      ),
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
                                      style: TextStyle(color: AppColors.textColorPrimary),
                                    ),
                                    const SizedBox(height: 8),

                                    // Custom Item Weight Field
                                    TextField(
                                        decoration: InputDecoration(
                                          labelText: 'Weight (lbs)',
                                          labelStyle: TextStyle(color: AppColors.textColorPrimary), // Label color
                                        ),
                                        keyboardType: TextInputType.number,
                                        maxLength: 3,
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
                                        style: TextStyle(color: AppColors.textColorPrimary)),
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
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.cancelButton),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      // Add selected custom item if name and weight are provided
                      if (customItemName.isNotEmpty && customItemWeight > 0) {
                        // Add the custom item to the load
                        loads[selectedLoadIndex].slings![selectedSlingIndex].customItems.add(
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

                          final int existingGearIndex = loads[selectedLoadIndex].slings?[selectedSlingIndex].loadGear.indexWhere(
                                    (loadItem) => loadItem is Gear && loadItem.name == item.name && loadItem.isPersonalTool == item.isPersonalTool,
                                  ) ??
                              -1; // Default to -1 if null

                          if (existingGearIndex != -1) {
                            // If it exists, update its quantity
                            Gear existingGear = loads[selectedLoadIndex].slings![selectedSlingIndex].loadGear[existingGearIndex];
                            existingGear.quantity += selectedQuantity;
                            // Weight is dynamically calculated elsewhere based on quantity
                          } else {
                            // If it doesn't exist, add the new gear item to the load
                            loads[selectedLoadIndex].slings![selectedSlingIndex].loadGear.add(
                                  Gear(
                                      name: item.name,
                                      quantity: selectedQuantity,
                                      weight: item.weight,
                                      // Per-item weight, not total weight
                                      isPersonalTool: item.isPersonalTool,
                                      isHazmat: item.isHazmat),
                                );
                          }

                          // Update the remaining quantity in the original inventory
                          item.quantity -= selectedQuantity;
                          if (item.quantity <= 0) {
                            gearList.remove(item);
                          }
                        }
                        else if (item is LoadAccoutrement){
                          loads[selectedLoadIndex].slings![selectedSlingIndex].loadAccoutrements.add(
                            LoadAccoutrement(
                                name: item.name,
                                quantity: 1,
                              weight: item.weight,
                            ),
                          );
                        }
                      }
                    });
                    sortSlingItems(loads[selectedLoadIndex].slings as Sling);
                  },
                  child: Text('Add', style: TextStyle(color: AppColors.saveButtonAllowableWeight)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Function to load the list of Gear items from Hive boxes
  void loadItems() {
    setState(() {
      // Map to track used gear quantities across all loads
      Map<String, int> usedGearQuantities = {};

      // Iterate through each Load object and track gear usage
      for (var load in loads) {
        for (var gear in load.loadGear) {
          usedGearQuantities[gear.name] = (usedGearQuantities[gear.name] ?? 0) + gear.quantity;
        }

        // Also track gear inside Slings (if they exist)
        if (load.slings != null) {
          for (var sling in load.slings!) {
            for (var gear in sling.loadGear) {
              usedGearQuantities[gear.name] = (usedGearQuantities[gear.name] ?? 0) + gear.quantity;
            }
          }
        }
      }

      // Calculate remaining gear quantities based on what is still available
      gearList = widget.trip.gear
          .map((gear) {
            int usedQuantity = usedGearQuantities[gear.name] ?? 0;
            int remainingQuantity = gear.quantity - usedQuantity;

            // Only include gear with remaining quantities
            return Gear(
              name: gear.name,
              quantity: remainingQuantity > 0 ? remainingQuantity : 0,
              weight: gear.weight,
              isPersonalTool: gear.isPersonalTool,
              isHazmat: gear.isHazmat,
            );
          })
          .where((gear) => gear.quantity > 0) // Remove gear with 0 quantity
          .toList();
    });
  }

// Convert a Load object to a dynamic list
  List<dynamic> loadToDynamicList(Load load) {
    return [
      {"slings": load.slings != null ? load.slings!.map((sling) => slingToDynamicList(sling)).toList() : []}, // ✅ Store slings in a dictionary for direct UI reference
      ...load.loadPersonnel,
      ...load.loadGear.map((gear) => Gear(
            name: gear.name,
            quantity: gear.quantity,
            weight: gear.weight,
            isPersonalTool: gear.isPersonalTool,
            isHazmat: gear.isHazmat,
          )),
      ...load.customItems.map((customItem) => CustomItem(
            name: customItem.name,
            weight: customItem.weight,
          )),
      if (load.loadAccoutrements != null) ...load.loadAccoutrements!,
    ];
  }

  Map<String, Object> slingToDynamicList(Sling sling) {
    return {
      "slingNumber": sling.slingNumber,
      "weight": sling.weight,
      "loadAccoutrements": sling.loadAccoutrements.map((acc) => acc).toList(),
      "loadGear": sling.loadGear
          .map((gear) => Gear(
                name: gear.name,
                quantity: gear.quantity,
                weight: gear.weight,
                isPersonalTool: gear.isPersonalTool,
                isHazmat: gear.isHazmat,
              ))
          .toList(),
      "customItems": sling.customItems
          .map((customItem) => CustomItem(
                name: customItem.name,
                weight: customItem.weight,
              ))
          .toList(),
    };
  }

  Sling dynamicListToSling(Map<String, dynamic> slingData) {
    return Sling(
      slingNumber: slingData["slingNumber"],
      weight: slingData["weight"],
      loadAccoutrements: (slingData["loadAccoutrements"] as List<dynamic>).whereType<LoadAccoutrement>().toList(),
      loadGear: (slingData["loadGear"] as List<dynamic>).whereType<Gear>().toList(),
      customItems: (slingData["customItems"] as List<dynamic>).whereType<CustomItem>().toList(),
    );
  }

  Load dynamicListToLoad(List<dynamic> dynamicList, int loadNumber) {
    List<Sling> extractedSlings = [];

    // Check if the first item is a map containing slings
    if (dynamicList.isNotEmpty && dynamicList.first is Map<String, dynamic>) {
      var slingData = dynamicList.removeAt(0) as Map<String, dynamic>;
      if (slingData.containsKey("slings")) {
        extractedSlings = (slingData["slings"] as List<dynamic>).map((slingList) => dynamicListToSling(slingList)).toList();
      }
    }

    return Load(
      loadNumber: loadNumber,
      weight: dynamicList.fold(0, (sum, item) {
        if (item is Gear) return sum + item.weight;
        if (item is CustomItem) return sum + item.weight;
        if (item is Sling) return sum + item.weight;
        return sum;
      }),
      loadPersonnel: dynamicList.whereType<CrewMember>().toList(),
      loadGear: dynamicList.whereType<Gear>().toList(),
      customItems: dynamicList.whereType<CustomItem>().toList(),
      slings: extractedSlings,
      //Now properly extracted from the dynamic list
      loadAccoutrements: dynamicList.whereType<LoadAccoutrement>().toList(),
    );
  }

  @override
  void dispose() {
    super.dispose();
    loadItems(); // Reload original data from Hive on back navigation
  }

  void _saveTrip() {
    // Ensure each load has the correct weight before saving
    widget.trip.loads = loads.asMap().entries.map<Load>((entry) {
      int index = entry.key;
      Load load = entry.value; // Directly access Load object

      // Calculate the correct total weight for the load
      int totalWeight = calculateAvailableWeight(load);

      // Assign the calculated weight
      load.weight = totalWeight;

      return load;
    }).toList();

    // Save the updated trip to Hive
    tripBox.put(widget.trip.tripName, widget.trip);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Center(
          child: Text(
            'Trip Saved!',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    // Navigate to the saved trips view
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SavedTripsView(),
      ),
    );
  }

  // Function to calculate available weight for a load
  int calculateAvailableWeight(Load load) {
    int totalWeight = 0;

    // Add weight from Slings and all their contents
    if (load.slings != null) {
      for (var sling in load.slings!) {
        // totalWeight += sling.weight; // Add sling's base weight

        // Add weight of Gear in the Sling
        totalWeight += sling.loadGear.fold(0, (sum, gear) => sum + gear.totalGearWeight);

        // Add weight of Custom Items in the Sling
        totalWeight += sling.customItems.fold(0, (sum, item) => sum + item.weight);

        // Add weight of Load Accoutrements in the Sling
        totalWeight += sling.loadAccoutrements.fold(0, (sum, acc) => sum + acc.weight);
      }
    }

    return totalWeight;
  }

  num calculateSlingWeight(Sling sling) {
    return sling.loadGear.fold(0, (sum, gear) => sum + gear.totalGearWeight) +
        sling.customItems.fold(0, (sum, item) => sum + item.weight) +
        sling.loadAccoutrements.fold(0, (sum, accoutrement) => sum + accoutrement.weight);
  }

  void sortSlingItems(Sling sling) {
    // Sort items within a Sling
    sling.loadGear.sort((a, b) => 0); // Gear order remains unchanged
    sling.customItems.sort((a, b) => 0); // CustomItem order remains unchanged
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.trip.tripName,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
            ),
            Text(
              'Allowable: ${widget.trip.allowable} lbs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
            child: ElevatedButton(
              onPressed: _saveTrip,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonStyle1,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.textColorSecondary,
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
            color: AppColors.isDarkMode ? Colors.black : Colors.transparent,
            // Background color for dark mode
            child: AppColors.isDarkMode
                ? (AppColors.enableBackgroundImage
                    ? Stack(
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                            // Blur effect
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
                    imageFilter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    // Always display in light mode
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
            child: Scrollbar(
              child: Column(
                children: [
                  Flexible(
                    child: ReorderableListView.builder(
                      proxyDecorator: (Widget child, int loadIndex, Animation<double> animation) {
                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 1.0 + (0.05 * animation.value),
                              child: Material(
                                color: Colors.transparent,
                                child: child,
                              ),
                            );
                          },
                          child: child,
                        );
                      },
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: loads.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }

                          // Move the load object
                          final item = loads.removeAt(oldIndex);
                          loads.insert(newIndex, item);

                          // Move expanded state for the main loads
                          final expandedState = _isExpanded.removeAt(oldIndex);
                          _isExpanded.insert(newIndex, expandedState);

                          // Move corresponding _isSlingExpanded entry
                          final slingExpandedState = _isSlingExpanded.removeAt(oldIndex);
                          _isSlingExpanded.insert(newIndex, slingExpandedState);
                        });
                      },

                      itemBuilder: (context, loadIndex) {
                        bool isExpanded = _isExpanded[loadIndex];

                        return Dismissible(
                          key: ValueKey(loads[loadIndex]), // Unique key per load
                          direction: DismissDirection.endToStart, // Swipe left to delete
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.textFieldColor2,
                                  title: Text(
                                    "Confirm Deletion",
                                    style: TextStyle(color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete Load #${loadIndex + 1}?",
                                    style: TextStyle(color: AppColors.textColorPrimary),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false); // Cancel deletion
                                      },
                                      child: Text("Cancel", style: TextStyle(color: AppColors.cancelButton)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true); // Confirm deletion
                                      },
                                      child: Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
                            setState(() {
                              var deletedLoad = loads.removeAt(loadIndex);

                              // Restore all slings & items from the deleted load back to inventory
                              for (var sling in deletedLoad.slings ?? []) {
                                for (var item in sling.loadGear) {
                                  var existingGear = gearList.firstWhere(
                                        (gear) => gear.name == item.name && gear.isPersonalTool == item.isPersonalTool,
                                    orElse: () => Gear(
                                      name: item.name,
                                      quantity: 0,
                                      weight: item.weight,
                                      isPersonalTool: item.isPersonalTool,
                                      isHazmat: item.isHazmat,
                                    ),
                                  );

                                  existingGear.quantity += (item.quantity as int);
                                  if (!gearList.contains(existingGear)) {
                                    gearList.add(existingGear);
                                  }
                                }
                              }

                              // Remove expansion state
                              if (_isExpanded.length > loadIndex) _isExpanded.removeAt(loadIndex);
                              if (_isSlingExpanded.length > loadIndex) _isSlingExpanded.removeAt(loadIndex);
                            });
                          },
                          child: Container(
                            key: ValueKey(loadIndex),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),

                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header Section
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded[loadIndex] = !_isExpanded[loadIndex];
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: calculateAvailableWeight(loads[loadIndex]) > widget.trip.allowable
                                          ? Colors.black // Warning color
                                          : AppColors.fireColor, // Normal color
                                      borderRadius:
                                    const BorderRadius.all(
                                        Radius.circular(10),
                                      ),
                                      border: Border.all(
                                        color: Colors.black, // Black outline
                                        width: 0.5, // Adjust thickness as needed
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          children: [
                                            Text(
                                              'LOAD #${loadIndex + 1}',
                                              style: TextStyle(
                                                color: calculateAvailableWeight(loads[loadIndex]) > widget.trip.allowable
                                                    ? Colors.white // Warning color
                                                    : Colors.black,
                                                fontSize: 22,
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
                                                        '${calculateAvailableWeight(loads[loadIndex])} lbs',
                                                        style: TextStyle(
                                                          fontSize: 20,
                                                          fontWeight: FontWeight.bold,
                                                          color: calculateAvailableWeight(loads[loadIndex]) > widget.trip.allowable
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
                                        // Expansion Icon
                                        Icon(
                                          isExpanded ? Icons.expand_less : Icons.expand_more,
                                          color: calculateAvailableWeight(loads[loadIndex]) > widget.trip.allowable
                                              ? Colors.white // Warning color
                                              : Colors.black,
                                          size: 36,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Body Section with Add Item Button
                                if (isExpanded)
                                  Column(
                                    children: [
                                      // **Display slings within the load**
                                      for (var slingIndex = 0; slingIndex < (loads[loadIndex].slings?.length ?? 0); slingIndex++)
                                        Dismissible(
                                          key: ValueKey(loads[loadIndex].slings![slingIndex]), // Unique key
                                          direction: DismissDirection.endToStart, // Swipe left to delete
                                          background: Container(
                                            color: Colors.red,
                                            alignment: Alignment.centerRight,
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Icon(Icons.delete, color: Colors.black),
                                          ),
                                          confirmDismiss: (direction) async {
                                            // Show confirmation dialog
                                            return await showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  backgroundColor: AppColors.textFieldColor2, // Background color
                                                  title: Text(
                                                    "Confirm Deletion",
                                                    style: TextStyle(color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
                                                  ),
                                                  content:  Text(
                                                    "Are you sure you want to delete this sling?",
                                                    style: TextStyle(color: AppColors.textColorPrimary, fontWeight: FontWeight.normal),

                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(false); // Cancel deletion
                                                      },
                                                      child: Text(
                                                        "Cancel",
                                                        style: TextStyle(color: AppColors.cancelButton),
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop(true); // Confirm deletion
                                                      },
                                                      child: Text(
                                                        "Delete",
                                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          onDismissed: (direction) {
                                            setState(() {
                                              // Store the sling before removing it
                                              var deletedSling = loads[loadIndex].slings!.removeAt(slingIndex);

                                              // Restore all items from the deleted sling back to inventory
                                              for (var item in deletedSling.loadGear) {
                                                var existingGear = gearList.firstWhere(
                                                      (gear) => gear.name == item.name && gear.isPersonalTool == item.isPersonalTool,
                                                  orElse: () => Gear(
                                                      name: item.name,
                                                      quantity: 0,
                                                      weight: item.weight,
                                                      isPersonalTool: item.isPersonalTool,
                                                      isHazmat: item.isHazmat),
                                                );

                                                existingGear.quantity += item.quantity;

                                                if (!gearList.contains(existingGear)) {
                                                  gearList.add(existingGear);
                                                }
                                              }

                                              // Remove expansion state
                                              if (_isSlingExpanded.length > loadIndex && _isSlingExpanded[loadIndex].length > slingIndex) {
                                                _isSlingExpanded[loadIndex].removeAt(slingIndex);
                                              }
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Container(
                                              width: double.infinity,
                                              padding: _isSlingExpanded[loadIndex][slingIndex] ? const EdgeInsets.only(top: 16.0) : const EdgeInsets.only(top: 16.0, bottom: 16),
                                              decoration: BoxDecoration(
                                                color: AppColors.textFieldColor2, // Transparent background
                                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                                border: Border.all(
                                                  color: Colors.black, //
                                                  width: 1.5, // Border thickness
                                                ),
                                              ),
                                              child: Column(
                                                children: [
                                                  // Sling Header (Clickable for Expansion)
                                                  GestureDetector(
                                                    behavior: HitTestBehavior.opaque, // Ensures the entire area is tappable
                                                    onTap: () {
                                                      setState(() {
                                                        _isSlingExpanded[loadIndex][slingIndex] = !_isSlingExpanded[loadIndex][slingIndex];
                                                      });
                                                    },
                                                    child: Padding(
                                                      padding: _isSlingExpanded[loadIndex][slingIndex]
                                                          ? const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0)
                                                          : const EdgeInsets.only(left: 8.0, right: 8.0),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                        children: [
                                                          Text(
                                                            'Sling #${slingIndex + 1}',
                                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                                          ),
                                                          Text(
                                                            '${calculateSlingWeight(loads[loadIndex].slings![slingIndex])} lbs',
                                                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                                          ),
                                                          Icon(
                                                            _isSlingExpanded[loadIndex][slingIndex] ? Icons.expand_less : Icons.expand_more,
                                                            color: Colors.white,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),

                                                  // Expanded Items Section
                                                  if (_isSlingExpanded[loadIndex][slingIndex])
                                                    Padding(
                                                      padding: const EdgeInsets.only(top: 8.0),
                                                      child: Container(
                                                        child: Column(
                                                          children: [
                                                            // **Sling Items List**
                                                            ...[
                                                              ...loads[loadIndex].slings![slingIndex].loadAccoutrements,
                                                              ...loads[loadIndex].slings![slingIndex].loadGear,
                                                              ...loads[loadIndex].slings![slingIndex].customItems,
                                                            ].map((item) => Dismissible(
                                                                  key: ValueKey(item),
                                                                  direction: DismissDirection.endToStart,
                                                                  background: Container(
                                                                    color: Colors.red,
                                                                    alignment: Alignment.centerRight,
                                                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                                                    child: Icon(Icons.delete, color: AppColors.textColorSecondary),
                                                                  ),
                                                                  onDismissed: (direction) {
                                                                    setState(() {
                                                                      if (item is Gear) {
                                                                        // No changes needed for Gear removal
                                                                        var existingGear = gearList.firstWhere(
                                                                              (gear) => gear.name == item.name && gear.isPersonalTool == item.isPersonalTool,
                                                                          orElse: () => Gear(
                                                                              name: item.name,
                                                                              quantity: 0,
                                                                              weight: item.weight,
                                                                              // Per-item weight
                                                                              isPersonalTool: item.isPersonalTool,
                                                                              isHazmat: item.isHazmat),
                                                                        );

                                                                        // Update the quantity in the existing inventory
                                                                        existingGear.quantity += item.quantity;

                                                                        if (!gearList.contains(existingGear)) {
                                                                          gearList.add(existingGear);
                                                                        }
                                                                        loads[loadIndex].slings![slingIndex].loadGear.remove(item);

                                                                      }
                                                                      else if (item is CustomItem) {
                                                                        loads[loadIndex].slings![slingIndex].customItems.remove(item);
                                                                      } else if (item is LoadAccoutrement) {
                                                                        loads[loadIndex].slings![slingIndex].loadAccoutrements.remove(item);
                                                                      }
                                                                    });
                                                                  },
                                                                  child: Card(
                                                                    elevation: 2,
                                                                    color: item is LoadAccoutrement ? AppColors.gearYellow : AppColors.gearYellow,
                                                                    margin: const EdgeInsets.symmetric(vertical: 0.5),
                                                                    shape: RoundedRectangleBorder(
                                                                      borderRadius: BorderRadius.circular(0.0),
                                                                    ),
                                                                    child: Padding(
                                                                      padding: const EdgeInsets.all(6.0),
                                                                      child: Row(
                                                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                                        children: [
                                                                          Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                                            children: [
                                                                              Text(
                                                                                itemDisplayEditTrip(item),
                                                                                style: TextStyle(
                                                                                  color: item is LoadAccoutrement ? Colors.black : Colors.black,
                                                                                  fontSize: 16,
                                                                                  fontWeight: FontWeight.bold,
                                                                                ),
                                                                              ),
                                                                              Text(
                                                                                (item is Gear || item is LoadAccoutrement) ? 'Quantity: ${(item is Gear) ? item.quantity : 1}' : '',
                                                                                style: TextStyle(
                                                                                  fontSize: 14,
                                                                                  color: item is LoadAccoutrement ? Colors.black : Colors.black,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                          IconButton(
                                                                            icon: const Icon(Icons.delete, color: Colors.red),
                                                                            onPressed: () {
                                                                              setState(() {
                                                                                if (item is Gear) {
                                                                                  if (item.quantity > 1) {
                                                                                    showDialog(
                                                                                      context: context,
                                                                                      builder: (BuildContext context) {
                                                                                        int quantityToRemove = 1; // Default to 1 for selection
                                                                                        return StatefulBuilder(
                                                                                          builder: (BuildContext context, StateSetter setDialogState) {
                                                                                            return AlertDialog(
                                                                                              backgroundColor: AppColors.textFieldColor2,
                                                                                              title: Text('Remove ${item.name}', style: TextStyle(color: AppColors.textColorPrimary)),
                                                                                              content: Column(
                                                                                                mainAxisSize: MainAxisSize.min,
                                                                                                children: [
                                                                                                  Text(
                                                                                                    'Select the quantity to remove:',
                                                                                                    style: TextStyle(color: AppColors.textColorPrimary),
                                                                                                  ),
                                                                                                  SizedBox(height: 8),
                                                                                                  DropdownButton<int>(
                                                                                                    value: quantityToRemove,
                                                                                                    dropdownColor: AppColors.textFieldColor2,
                                                                                                    items: List.generate(
                                                                                                      item.quantity,
                                                                                                          (index) => DropdownMenuItem(
                                                                                                        value: index + 1,
                                                                                                        child: Text('${index + 1}', style: TextStyle(color: AppColors.textColorPrimary)),
                                                                                                      ),
                                                                                                    ),
                                                                                                    style: TextStyle(color: AppColors.textColorPrimary),
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
                                                                                                  child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton)),
                                                                                                ),
                                                                                                TextButton(
                                                                                                  onPressed: () {
                                                                                                    setState(() {
                                                                                                      // Deduct the selected quantity
                                                                                                      item.quantity -= quantityToRemove;

                                                                                                      // Handle returning the removed quantity to the inventory
                                                                                                      var existingGear = gearList.firstWhere(
                                                                                                            (gear) => gear.name == item.name && gear.isPersonalTool == item.isPersonalTool,
                                                                                                        // Ensure same isPersonalTool status
                                                                                                        orElse: () => Gear(
                                                                                                            name: item.name, quantity: 0, weight: item.weight, isPersonalTool: item.isPersonalTool, isHazmat: item.isHazmat),
                                                                                                      );

                                                                                                      // Update inventory quantity
                                                                                                      existingGear.quantity += quantityToRemove;

                                                                                                      if (!gearList.contains(existingGear)) {
                                                                                                        gearList.add(existingGear);
                                                                                                      }

                                                                                                      // Remove the item from the load if quantity reaches zero
                                                                                                      if (item.quantity <= 0) {
                                                                                                        loads[loadIndex].slings![slingIndex].loadGear.remove(item);
                                                                                                      }
                                                                                                    });

                                                                                                    Navigator.of(context).pop(); // Close the dialog
                                                                                                  },
                                                                                                  child: Text(
                                                                                                    'Remove',
                                                                                                    style: TextStyle(color: Colors.red),
                                                                                                  ),
                                                                                                ),
                                                                                              ],
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      },
                                                                                    );
                                                                                  } else {
                                                                                    // Remove single gear item
                                                                                    loads[loadIndex].slings![slingIndex].loadGear.remove(item);

                                                                                    var existingGear = gearList.firstWhere(
                                                                                          (gear) => gear.name == item.name && gear.isPersonalTool == item.isPersonalTool, // Ensure same isPersonalTool status
                                                                                      orElse: () => Gear(name: item.name, quantity: 0, weight: item.weight, isPersonalTool: item.isPersonalTool, isHazmat: item.isHazmat),
                                                                                    );

                                                                                    // Update inventory quantity
                                                                                    existingGear.quantity += 1;

                                                                                    if (!gearList.contains(existingGear)) {
                                                                                      gearList.add(existingGear);
                                                                                    }
                                                                                  }
                                                                                }
                                                                               else if (item is CustomItem) {
                                                                                  loads[loadIndex].slings![slingIndex].customItems.remove(item);
                                                                                } else if (item is LoadAccoutrement) {
                                                                                  loads[loadIndex].slings![slingIndex].loadAccoutrements.remove(item);
                                                                                }
                                                                              });
                                                                            },
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                )),

                                                            // **Add Item Button (Specific to Sling)**
                                                            GestureDetector(
                                                              onTap: () => _showSelectionDialog(loadIndex, slingIndex),
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(top: 0),
                                                                child: Container(
                                                                  width: double.infinity,
                                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.green, // Your background color
                                                                    borderRadius: const BorderRadius.vertical(
                                                                      bottom: Radius.circular(8), // Only bottom corners rounded
                                                                    ),
                                                                  ),
                                                                  alignment: Alignment.center,
                                                                  child: Text(
                                                                    '+ Add Item',
                                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
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
                                            ),
                                          ),
                                        ),

                                    ],
                                  ),

                                if  (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            // Ensure slings list is initialized
                                            loads[loadIndex].slings ??= [];

                                            // Add new sling
                                            loads[loadIndex].slings!.add(
                                              Sling(
                                                slingNumber: loads[loadIndex].slings!.length + 1,
                                                weight: 0,
                                                loadAccoutrements: [],
                                                loadGear: [],
                                                customItems: [],
                                              ),
                                            );

                                            // Ensure _isSlingExpanded list exists for this load and update it
                                            while (_isSlingExpanded.length <= loadIndex) {
                                              _isSlingExpanded.add([]); // Fill missing entries
                                            }

                                            _isSlingExpanded[loadIndex].add(true); // Default to expanded state
                                          });
                                        },
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                                          children: [
                                            Icon(
                                              FontAwesomeIcons.circlePlus,
                                              color: Colors.green,
                                            ),
                                            SizedBox(width: 8), // Space between the icon and the text
                                            Text(
                                              'Add Sling',
                                              textAlign: TextAlign.center,
                                              softWrap: true,
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textColorPrimary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 12.0, right: 12.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            loads.add(
                              Load(
                                loadNumber: loads.length + 1,
                                weight: 0,
                                loadPersonnel: [],
                                loadGear: [],
                                customItems: [],
                                slings: [],
                                loadAccoutrements: [],
                              ),
                            );
                            _isExpanded.add(true);
                            _isSlingExpanded.add([]); // Start with an empty sling expansion list
                          });
                        },
                        child:  Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                          children: [
                            Icon(
                              FontAwesomeIcons.circlePlus,
                              color: AppColors.primaryColor,
                            ),
                            SizedBox(width: 8), // Space between the icon and the text
                            Text(
                              'Add Load',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textColorPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ),
                ],
              ),
              // Add Load Button
            ),
          ),
        ],
      ),
    );
  }
}
