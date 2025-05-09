import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hive/hive.dart';

import '../CodeShare/variables.dart';
import '../Data/crewmember.dart';
import '../Data/customItem.dart';
import '../Data/gear.dart';
import '../Data/load.dart';
import '../Data/trip.dart';
import '../main.dart';

// Double integers when calculating quantity dont always work out. a 45 lb QB can become 44
// Update: Maybe fixed?
class EditTrip extends StatefulWidget {
  final Trip trip;

  const EditTrip({
    super.key,
    required this.trip,
  });

  @override
  State<EditTrip> createState() => _EditTripState();
}

class _EditTripState extends State<EditTrip> {
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

    // Convert Load objects to dynamic lists
    loads = widget.trip.loads.map((load) => loadToDynamicList(load)).toList();

    _isExpanded = List.generate(loads.length, (_) => false);
    loadItems();
  }

  // This is what displays on each load
  String itemDisplay(dynamic item) {
    if (item is Gear) {
      return "${item.name}, ${item.totalGearWeight} lb";
    } else if (item is CrewMember) {
      return "${item.name}, ${item.flightWeight} lb";
    } else if (item is CustomItem) {
      return "${item.name}, ${item.weight} lb";
    } else {
      return "Unknown item type";
    }
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

    bool isSelectAllCheckedGear = gearList.every((gear) => selectedItems.contains(gear)) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            void updateSelectAllState() {
              dialogSetState(() {
                // Update all Select All Checkboxes
                isSelectAllCheckedGear = gearList.every((gear) => selectedItems.contains(gear)) && selectedGearQuantities.entries.every((entry) => entry.value == entry.key.quantity);
              });
            }

            return AlertDialog(
              backgroundColor: AppColors.textFieldColor2,
              title: Text(
                'Add Crew Members and Gear',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18, color: AppColors.textColorPrimary),
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
                              backgroundColor: AppColors.fireColor,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  child: ListTile(
                                    title: Text(
                                      'Crew Members',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: sortedCrewList.map((crew) {
                                  return Container(
                                    //margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Add space around the tile
                                    decoration: BoxDecoration(
                                      color: AppColors.textFieldColor,
                                      borderRadius: BorderRadius.circular(0.0),
                                      // Rounded corners
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withValues(alpha: 0.8),
                                          spreadRadius: 1,
                                          blurRadius: 5,
                                          offset: Offset(0, 3), // Shadow position
                                        ),
                                      ],
                                    ),
                                    child: CheckboxListTile(
                                      activeColor: AppColors.textColorPrimary,
                                      // Checkbox outline color when active
                                      checkColor: AppColors.textColorSecondary,
                                      side: BorderSide(
                                        color: AppColors.textColorPrimary,
                                        // Outline color
                                        width: 2.0, // Outline width
                                      ),
                                      //
                                      title: Text(
                                        '${crew.name}, ${crew.flightWeight} lb',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text16, color: AppColors.textColorPrimary),
                                        textAlign: TextAlign.start,
                                      ),
                                      subtitle: Text(
                                        crew.getPositionTitle(crew.position),
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text14),
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
                              backgroundColor: AppColors.fireColor,
                              // Set background color
                              headerBuilder: (context, isExpanded) {
                                return Container(
                                  //color: Colors.deepOrangeAccent, // Set the background color for the header
                                  child: ListTile(
                                    title:  Text(
                                      'Gear',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text18),
                                    ),
                                  ),
                                );
                              },
                              body: Column(
                                children: [
                                  if (gearList.isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.gearYellow, // Background color
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.black, width: .75, // Black border
                                          ),
                                        ),
                                      ),
                                      child: CheckboxListTile(
                                        title: Text(
                                          'Select All',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: AppData.text16, color: Colors.black),
                                        ),
                                        value: isSelectAllCheckedGear,
                                        onChanged: (bool? isChecked) {
                                          dialogSetState(() {
                                            isSelectAllCheckedGear = isChecked ?? false;

                                            if (isSelectAllCheckedGear) {
                                              selectedItems.addAll(gearList.where((gear) => !selectedItems.contains(gear)));

                                              selectedGearQuantities = {
                                                for (var gear in gearList) gear: gear.quantity,
                                              };
                                            } else {
                                              // Remove only gear items, keeping crew members
                                              selectedItems.removeWhere((item) => item is Gear);

                                              // Reset selected quantities for gear (avoid stale selections)
                                              selectedGearQuantities.clear();
                                            }
                                            updateSelectAllState();
                                          });
                                        },
                                      ),
                                    ),
                                  Column(
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
                                              color: Colors.grey.withValues(alpha: 0.8),
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
                                                child: Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            gear.name,
                                                            style: TextStyle(
                                                              fontSize: AppData.text16,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        if (gear.isHazmat)
                                                          Padding(
                                                            padding: const EdgeInsets.only(left: 4.0),
                                                            child: Icon(
                                                              FontAwesomeIcons.triangleExclamation, // Hazard icon
                                                              color: Colors.red, // Red color for hazard
                                                              size: AppData.text14, // Icon size
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    Text(
                                                      '${gear.weight} lb x$remainingQuantity',
                                                      style: TextStyle(
                                                        fontSize: AppData.text14,
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
                                                                style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.text18, ),
                                                              ),
                                                              content: SizedBox(
                                                                height: 150,
                                                                child: CupertinoPicker(
                                                                  scrollController: FixedExtentScrollController(
                                                                    initialItem: (selectedGearQuantities[gear] ?? 1) - 1,
                                                                  ),
                                                                  itemExtent: AppData.text32,
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
                                                                        child: Text('${index + 1}', style: TextStyle(fontSize: AppData.text18, color: AppColors.textColorPrimary)),
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
                                                                  child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
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
                                                                  child: Text('Confirm', style: TextStyle(fontSize: AppData.bottomDialogTextSize, color: AppColors.saveButtonAllowableWeight)),
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
                                                            '   Qty: ${selectedGearQuantities[gear] ?? 1}',
                                                            style: TextStyle(fontSize: AppData.text14, color: AppColors.textColorSecondary),
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
                                ],
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
                                                fontSize: AppData.text20,
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
                                                              fontSize: AppData.text16,
                                                              color: AppColors.textColorPrimary,
                                                            ),
                                                          ),
                                                          Text(
                                                            '${item['weight']} lb',
                                                            style: TextStyle(
                                                              fontSize: AppData.text16,
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
                                                  style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
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
                                  title: Text(
                                    'Custom Item',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: AppData.text18
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
                                        labelText: ' Item Name',
                                        labelStyle: TextStyle( fontSize: AppData.text16, color: AppColors.textColorPrimary), // Label color
                                      ),
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(15),
                                      ],
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
                                      style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.text16,  ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Custom Item Weight Field
                                    TextField(
                                        decoration: InputDecoration(
                                          labelText: ' Weight (lb)',
                                          labelStyle: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16), // Label color
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                    LengthLimitingTextInputFormatter(3),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
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
                                        style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text16)),
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
                    style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize),
                  ),
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

                          final existingGearIndex = loads[selectedLoadIndex].indexWhere(
                            (loadItem) => loadItem is Gear && loadItem.name == item.name && loadItem.isPersonalTool == item.isPersonalTool, // Ensure same isPersonalTool status
                          );

                          if (existingGearIndex != -1) {
                            // If it exists, update its quantity
                            Gear existingGear = loads[selectedLoadIndex][existingGearIndex] as Gear;
                            existingGear.quantity += selectedQuantity;
                            // Weight is dynamically calculated elsewhere based on quantity
                          } else {
                            // If it doesn't exist, add the new gear item to the load
                            loads[selectedLoadIndex].add(
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
                        } else if (item is CrewMember) {
                          // Add crew member directly
                          loads[selectedLoadIndex].add(item);

                          // Loop through and add all personal tools
                          if (item.personalTools != null) {
                            for (var tool in item.personalTools!) {
                              final existingToolIndex = loads[selectedLoadIndex].indexWhere(
                                (loadItem) => loadItem is Gear && loadItem.name == tool.name && loadItem.isPersonalTool == tool.isPersonalTool, // Ensure same isPersonalTool status
                              );

                              if (existingToolIndex != -1) {
                                // Update the existing tool's quantity
                                Gear existingTool = loads[selectedLoadIndex][existingToolIndex] as Gear;
                                existingTool.quantity += tool.quantity;
                                // Weight is dynamically calculated elsewhere based on quantity
                              } else {
                                // Add the tool as a new gear item
                                loads[selectedLoadIndex].add(
                                  Gear(
                                      name: tool.name,
                                      quantity: tool.quantity,
                                      weight: tool.weight,
                                      // Per-item weight
                                      isPersonalTool: tool.isPersonalTool,
                                      isHazmat: tool.isHazmat),
                                );
                              }
                            }
                          }

                          // Remove crew member from the available list
                          crewList.remove(item);
                        }
                      }
                    });
                    sortLoadItems(loads[selectedLoadIndex]);
                  },
                  child: Text('Add', style: TextStyle(color: AppColors.saveButtonAllowableWeight, fontSize: AppData.bottomDialogTextSize)),
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
      // Map of gear name to remaining quantity
      Map<String, int> usedGearQuantities = {};

      // Calculate total quantities used in all loads
      for (var load in loads) {
        for (var item in load) {
          if (item is Gear) {
            usedGearQuantities[item.name] = (usedGearQuantities[item.name] ?? 0) + item.quantity;
          }
        }
      }

      // Calculate remaining quantities for the gear list
      gearList = widget.trip.gear
          .map((gear) {
            int usedQuantity = usedGearQuantities[gear.name] ?? 0;
            int remainingQuantity = gear.quantity - usedQuantity;

            // Only include gear with remaining quantities
            return Gear(name: gear.name, quantity: remainingQuantity > 0 ? remainingQuantity : 0, weight: gear.weight, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat);
          })
          .where((gear) => gear.quantity > 0)
          .toList();

      // Load crew members
      crewList = widget.trip.crewMembers
          .where((crew) => !loads.any((load) => load.any((item) => item is CrewMember && item.name == crew.name)))
          .map((crew) => CrewMember(
                name: crew.name,
                flightWeight: crew.flightWeight,
                position: crew.position,
                personalTools: crew.personalTools,
              ))
          .toList();
    });
  }

// Convert a Load object to a dynamic list
  List<dynamic> loadToDynamicList(Load load) {
    return [
      ...load.loadPersonnel,
      ...load.loadGear.map((gear) => Gear(name: gear.name, quantity: gear.quantity, weight: gear.weight, isPersonalTool: gear.isPersonalTool, isHazmat: gear.isHazmat)),
      ...load.customItems.map((customItem) => CustomItem(
            name: customItem.name,
            weight: customItem.weight,
          )),
    ];
  }

// Convert a dynamic list back to a Load object
  Load dynamicListToLoad(List<dynamic> dynamicList, int loadNumber) {
    return Load(
      loadNumber: loadNumber,
      weight: dynamicList.fold(0, (sum, item) {
        if (item is Gear) return sum + item.weight;
        if (item is CrewMember) return sum + item.flightWeight;
        if (item is CustomItem) return sum + item.weight;
        return sum;
      }),
      loadPersonnel: dynamicList.whereType<CrewMember>().toList(),
      loadGear: dynamicList.whereType<Gear>().toList(),
      customItems: dynamicList.whereType<CustomItem>().toList(),
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
      List<dynamic> dynamicList = entry.value;

      // Calculate the correct total weight for the load
      int totalWeight = calculateAvailableWeight(dynamicList);

      // Convert the dynamic list to a Load object and set the weight
      Load load = dynamicListToLoad(dynamicList, index + 1);
      load.weight = totalWeight; // Assign the calculated weight
      return load;
    }).toList();

    // Update timestamp before saving
    widget.trip.timestamp = DateTime.now();

    if (tripBox.containsKey(widget.trip.key)) {
      tripBox.delete(widget.trip.key);
    }

    // Save under the correct key
    tripBox.put(widget.trip.tripName, widget.trip);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Center(
          child: Text(
            'Trip Saved!',
            style: TextStyle(
              color: Colors.black,
              fontSize: AppData.text32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(); // Go back to the home screen
    Navigator.of(context).pop(); // Go back to the home screen
    selectedIndexNotifier.value = 1; // Switch to "Saved Trips" tab


    final Map<String, Object> analyticsParams = {
      'trip_name': widget.trip.tripName.trim(),
      'trip_allowable': widget.trip.allowable.toString(),
      'trip_available_seats': widget.trip.availableSeats.toString(),
      'num_loads': widget.trip.loads.length.toString(),
    };

    // Add load weights dynamically
    for (int i = 0; i < widget.trip.loads.length; i++) {
      analyticsParams['load_${i + 1}_weight'] = widget.trip.loads[i].weight.toString();
    }

    FirebaseAnalytics.instance.logEvent(
      name: 'internal_trip_edited',
      parameters: analyticsParams,
    );
  }

  // Function to calculate available weight for a load
  int calculateAvailableWeight(List<dynamic> loadItems) {
    final totalWeight = loadItems.fold(0, (sum, item) {
      if (item is Gear) {
        return sum + item.totalGearWeight; // Use the total weight directly
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

  void sortLoadItems(List<dynamic> load) {
    load.sort((a, b) {
      // Prioritize CrewMember objects first
      if (a is CrewMember && b is! CrewMember) return -1;
      if (b is CrewMember && a is! CrewMember) return 1;

      // Within Gear, prioritize personal tools
      if (a is Gear && b is Gear) {
        if (a.isPersonalTool && !b.isPersonalTool) return -1;
        if (!a.isPersonalTool && b.isPersonalTool) return 1;
      }

      // Keep CustomItem objects or other cases in relative order
      if (a is CustomItem && b is! CustomItem) return -1;
      if (b is CustomItem && a is! CustomItem) return 1;

      return 0; // Maintain relative order for similar types
    });
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
              style: TextStyle(fontSize: AppData.appBarText, fontWeight: FontWeight.bold, color: AppColors.textColorPrimary),
            ),
            Text(
              'Allowable: ${widget.trip.allowable} lb',
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
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
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
                          final item = loads.removeAt(oldIndex);
                          loads.insert(newIndex, item);

                          // Also update expanded state to match the reordered loads
                          final expandedState = _isExpanded.removeAt(oldIndex);
                          _isExpanded.insert(newIndex, expandedState);
                        });
                      },
                      itemBuilder: (context, index) {
                        bool isExpanded = _isExpanded[index];

                        return Dismissible(
                          key: ValueKey(loads[index]),
                          // Unique key per load
                          direction: DismissDirection.endToStart,
                          // Swipe left to delete
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Icon(Icons.delete, color: Colors.black, size: AppData.text24,),
                          ),
                          confirmDismiss: (direction) async {
                            return await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  backgroundColor: AppColors.textFieldColor2,
                                  title: Text(
                                    "Confirm Deletion",
                                    style: TextStyle( fontSize: AppData.miniDialogTitleTextSize,color: AppColors.textColorPrimary, fontWeight: FontWeight.bold),
                                  ),
                                  content: Text(
                                    "Are you sure you want to delete Load #${index + 1}?",
                                    style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.miniDialogBodyTextSize, ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(false); // Cancel deletion
                                      },
                                      child: Text("Cancel", style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop(true);
                                      },
                                      child: Text("Delete", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: AppData.bottomDialogTextSize)),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          onDismissed: (direction) {
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
                                      orElse: () => Gear(name: item.name, quantity: 0, weight: item.totalGearWeight ~/ item.quantity, isHazmat: item.isHazmat),
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
                          },
                          child: Container(
                            key: ValueKey(index),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.textFieldColor2, // Transparent background
                                borderRadius: BorderRadius.circular(10), // Rounded corners
                                border: Border.all(
                                  color: Colors.black, //
                                  width: 1.5, // Border thickness
                                ),
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
                                      padding: const EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: (calculateAvailableWeight(loads[index]) > widget.trip.allowable ||
                                            calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                            ? Colors.black
                                            : AppColors.fireColor,
                                        borderRadius: _isExpanded[index]
                                            ? const BorderRadius.vertical(top: Radius.circular(10))
                                            : const BorderRadius.all(Radius.circular(10)),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, constraints) {
                                          return FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: ConstrainedBox(
                                              constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                              child: IntrinsicWidth(
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'LOAD #${index + 1}',
                                                      style: TextStyle(
                                                        color: (calculateAvailableWeight(loads[index]) > widget.trip.allowable ||
                                                            calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                                            ? Colors.white
                                                            : Colors.black,
                                                        fontSize: AppData.text22,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(width: 20),
                                                    Row(
                                                      children: [
                                                        Text(
                                                          '${calculateAvailableWeight(loads[index])} lb',
                                                          style: TextStyle(
                                                            fontSize: AppData.text20,
                                                            fontWeight: FontWeight.bold,
                                                            color: (calculateAvailableWeight(loads[index]) > widget.trip.allowable ||
                                                                calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Container(
                                                          height: AppData.text22,
                                                          width: 1,
                                                          color: (calculateAvailableWeight(loads[index]) > widget.trip.allowable ||
                                                              calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                                              ? Colors.white
                                                              : Colors.black,
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          '${calculateAvailableSeats(loads[index])}/${widget.trip.availableSeats} seats',
                                                          style: TextStyle(
                                                            fontSize: AppData.text20,
                                                            fontWeight: FontWeight.bold,
                                                            color: (calculateAvailableWeight(loads[index]) > widget.trip.allowable ||
                                                                calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                                                ? Colors.white
                                                                : Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    SizedBox(width: 20),
                                                    Icon(
                                                      isExpanded ? Icons.expand_less : Icons.expand_more,
                                                      color: (calculateAvailableWeight(loads[index]) > widget.trip.allowable ||
                                                          calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                                          ? Colors.white
                                                          : Colors.black,
                                                      size: AppData.text36,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),

                                  // Body Section with Add Item Button
                                  if (isExpanded)
                                    Padding(
                                      padding: const EdgeInsets.all(0.0),
                                      child: Column(
                                        children: [
                                          // If overweight
                                          if (calculateAvailableWeight(loads[index]) > widget.trip.allowable)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 0),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  // Background color
                                                  borderRadius: BorderRadius.circular(0),
                                                  // Rounded corners
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'OVERWEIGHT',
                                                  style: TextStyle(
                                                    fontSize: AppData.text18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          // If over seats
                                          if (calculateAvailableSeats(loads[index]) > widget.trip.availableSeats)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 0.0),
                                              child: Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.symmetric(vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  // Background color
                                                  borderRadius: BorderRadius.circular(0),
                                                  // Rounded corners
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  'NOT ENOUGH SEATS',
                                                  style: TextStyle(
                                                    fontSize: AppData.text18,
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
                                              direction: (item is Gear && item.isPersonalTool)
                                                  ? DismissDirection.none // Disable swipe for personal tools
                                                  : DismissDirection.endToStart,
                                              // Allow swipe for other items

                                              background: Container(
                                                color: Colors.red,
                                                // Red background for delete action
                                                alignment: Alignment.centerRight,
                                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                                child: Icon(Icons.delete, color: AppColors.textColorSecondary, size: AppData.text24,), // Trash icon
                                              ),

                                              onDismissed: (direction) {
                                                setState(() {
                                                  if (loads[index].contains(item)) {
                                                    loads[index].remove(item);

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
                                                    } else if (item is CrewMember) {
                                                      // Handle personal tools for CrewMembers
                                                      if (item.personalTools != null) {
                                                        for (var tool in item.personalTools!) {
                                                          // Check and update in the gearList, ensuring it matches `isPersonalTool`
                                                          final gearListIndex = gearList.indexWhere(
                                                            (gear) => gear.name == tool.name && gear.isPersonalTool == tool.isPersonalTool,
                                                          );

                                                          if (gearListIndex != -1) {
                                                            Gear gearTool = gearList[gearListIndex];
                                                            gearTool.quantity -= tool.quantity;

                                                            // If quantity reaches zero, remove the tool from the gearList
                                                            if (gearTool.quantity <= 0) {
                                                              gearList.removeAt(gearListIndex);
                                                            }
                                                          } else {
                                                            // Check and update in the load
                                                            final toolIndex = loads[index].indexWhere(
                                                              (loadItem) => loadItem is Gear && loadItem.name == tool.name && loadItem.isPersonalTool == tool.isPersonalTool,
                                                            );

                                                            if (toolIndex != -1) {
                                                              Gear loadTool = loads[index][toolIndex];
                                                              loadTool.quantity -= tool.quantity;

                                                              // If quantity reaches zero, remove the tool from the load
                                                              if (loadTool.quantity <= 0) {
                                                                loads[index].removeAt(toolIndex);
                                                              }
                                                            }
                                                          }
                                                        }
                                                      }

                                                      // Add the CrewMember back to the available list
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
                                                    ? AppColors.textFieldColor2 // Color for CrewMembers
                                                    : item is Gear && item.isPersonalTool == true
                                                        ? AppColors.toolBlue // Color for personal tools
                                                        : AppColors.gearYellow,
                                                // Color for regular Gear
                                                // Different colors for CrewMember and Gear
                                                margin: const EdgeInsets.symmetric(vertical: 0.0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(0.0), // Rounded corners
                                                ),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(6.0),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            Text(
                                                              itemDisplay(item),
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                fontSize: AppData.text16,
                                                                fontWeight: FontWeight.bold,
                                                                color: item is CrewMember ? AppColors.textColorPrimary : Colors.black,
                                                              ),
                                                            ),
                                                            if (item is! CustomItem)
                                                              Text(
                                                                item is Gear ? 'Quantity: ${item.quantity} x ${item.weight} lb' : item.getPositionTitle(item.position),
                                                                style: TextStyle(
                                                                  fontSize: AppData.text14,
                                                                  color: item is CrewMember ? AppColors.textColorPrimary : Colors.black,
                                                                ),
                                                              ),
                                                          ],
                                                        ),
                                                      ),

                                                      // Single Item Deletion
                                                      if (!(item is Gear && item.isPersonalTool))
                                                        IconButton(
                                                          icon:  Icon(Icons.delete, color: Colors.red, size: AppData.text24,),
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
                                                                              backgroundColor: AppColors.textFieldColor2,
                                                                              title: Text('Remove ${item.name}', style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text18)),
                                                                              content: Column(
                                                                                mainAxisSize: MainAxisSize.min,
                                                                                children: [
                                                                                  Text(
                                                                                    'Select the quantity to remove:',
                                                                                    style: TextStyle(color: AppColors.textColorPrimary, fontSize: AppData.text14, ),
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
                                                                                    style: TextStyle(color: AppColors.textColorPrimary,  fontSize: AppData.text16, ),
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
                                                                                  child: Text('Cancel', style: TextStyle(color: AppColors.cancelButton, fontSize: AppData.bottomDialogTextSize)),
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
                                                                                            name: item.name,
                                                                                            quantity: 0,
                                                                                            weight: item.weight,
                                                                                            isPersonalTool: item.isPersonalTool,
                                                                                            isHazmat: item.isHazmat),
                                                                                      );

                                                                                      // Update inventory quantity
                                                                                      existingGear.quantity += quantityToRemove;

                                                                                      if (!gearList.contains(existingGear)) {
                                                                                        gearList.add(existingGear);
                                                                                      }

                                                                                      // Remove the item from the load if quantity reaches zero
                                                                                      if (item.quantity <= 0) {
                                                                                        loads[index].remove(item);
                                                                                      }
                                                                                    });

                                                                                    Navigator.of(context).pop(); // Close the dialog
                                                                                  },
                                                                                  child: Text(
                                                                                    'Remove',
                                                                                    style: TextStyle(color: Colors.red, fontSize: AppData.bottomDialogTextSize),
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
                                                                    loads[index].remove(item);
                                                                    var existingGear = gearList.firstWhere(
                                                                      (gear) => gear.name == item.name && gear.isPersonalTool == item.isPersonalTool, // Ensure same isPersonalTool status
                                                                      orElse: () =>
                                                                          Gear(name: item.name, quantity: 0, weight: item.weight, isPersonalTool: item.isPersonalTool, isHazmat: item.isHazmat),
                                                                    );

                                                                    // Update inventory quantity
                                                                    existingGear.quantity += 1;

                                                                    if (!gearList.contains(existingGear)) {
                                                                      gearList.add(existingGear);
                                                                    }
                                                                  }
                                                                } else if (item is CrewMember) {
                                                                  // Handle CrewMember logic
                                                                  if (item.personalTools != null) {
                                                                    for (var tool in item.personalTools!) {
                                                                      // Ensure the removal only applies to personal tools
                                                                      final gearListIndex = gearList.indexWhere(
                                                                        (gear) => gear.name == tool.name && gear.isPersonalTool == tool.isPersonalTool,
                                                                      );

                                                                      if (gearListIndex != -1) {
                                                                        // Update gear list quantities
                                                                        Gear gearTool = gearList[gearListIndex];
                                                                        gearTool.quantity -= tool.quantity;
                                                                        if (gearTool.quantity <= 0) {
                                                                          gearList.removeAt(gearListIndex);
                                                                        }
                                                                      } else {
                                                                        // Update load quantities
                                                                        // Ensure removal from load only applies to personal tools
                                                                        final toolIndex = loads[index].indexWhere(
                                                                          (loadItem) => loadItem is Gear && loadItem.name == tool.name && loadItem.isPersonalTool == tool.isPersonalTool,
                                                                        );

                                                                        if (toolIndex != -1) {
                                                                          Gear loadTool = loads[index][toolIndex];
                                                                          loadTool.quantity -= tool.quantity;
                                                                          if (loadTool.quantity <= 0) {
                                                                            loads[index].removeAt(toolIndex);
                                                                          }
                                                                        }
                                                                      }
                                                                    }
                                                                  }
                                                                  if (!crewList.contains(item)) {
                                                                    crewList.add(item);
                                                                  }
                                                                  loads[index].remove(item);
                                                                } else if (item is CustomItem) {
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

                                          // Add Item
                                          GestureDetector(
                                            onTap: () => _showSelectionDialog(index),
                                            child: Container(
                                              width: double.infinity,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                // Background color
                                                borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
                                                // Rounded corners
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '+ Add Item',
                                                style: TextStyle(fontSize: AppData.text18, fontWeight: FontWeight.bold, color: Colors.black),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Add Load Button
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0, left: 12.0, right: 12.0),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            // Add load here bruh
                            loads.add([]);
                            _isExpanded.add(true);
                          });
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center, // Center the content horizontally
                          children: [
                            Icon(
                              FontAwesomeIcons.circlePlus,
                              color: AppColors.primaryColor,
                                size: AppData.text24

                            ),
                            SizedBox(width: AppData.sizedBox8), // Space between the icon and the text
                            Text(
                              'Add Load',
                              textAlign: TextAlign.center,
                              softWrap: true,
                              style: TextStyle(
                                fontSize: AppData.text22,
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
