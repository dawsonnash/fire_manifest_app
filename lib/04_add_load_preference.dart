import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'Data/crew.dart';
import 'Data/gear.dart';
import 'Data/saved_preferences.dart';
import 'Data/crewmember.dart';
import 'package:flutter/material.dart';

class AddLoadPreference extends StatefulWidget {
  // This page requires a Trip Preference object to be passed to it - to edit it
  final TripPreference tripPreference;
  final VoidCallback onUpdate; // Callback for deletion to update previous page

  const AddLoadPreference(
      {super.key, required this.tripPreference, required this.onUpdate});

  @override
  State<AddLoadPreference> createState() => _AddLoadPreferenceState();
}

class _AddLoadPreferenceState extends State<AddLoadPreference>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  // Variables to store user input
  // Priority decided as drag & drop in UI
  int? selectedPositionalLoadPreference;
  List<dynamic> selectedCrewMembers = [];

  int? selectedGearLoadPreference;
  List<Gear> selectedGear = [];
  Map<Gear, int> selectedGearQuantities = {};

  bool isPositionalSaveButtonEnabled =
      false; // Controls whether saving button is showing
  bool isGearSaveButtonEnabled =
      false; // Controls whether saving button is showing

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to open the multi-select dialog for crew members
  // overly logically complex - do not try to understand
  void _showCrewMemberSelectionDialog() async {
    List<Map<String, dynamic>> sawTeamOptions = [];
    List<Map<String, dynamic>> individualOptions = [];

    // Collect all used crew members (both individuals and members of Saw Teams)
    final usedCrewMembers = widget.tripPreference.positionalPreferences
        .expand((posPref) => posPref.crewMembersDynamic)
        .expand((member) => member is List<CrewMember> ? member : [member])
        .toSet();

    // Populate saw team options
    for (int i = 1; i <= 6; i++) {
      List<CrewMember> sawTeam = crew.getSawTeam(i);
      if (sawTeam.isNotEmpty &&
          !sawTeam.every(usedCrewMembers.contains) &&
          !sawTeam.every((member) => selectedCrewMembers.contains(member))) {
        sawTeamOptions.add({'name': 'Saw Team $i', 'members': sawTeam});
      }
    }

    // Populate individual crew member options, so they remain visible and checked if selected
    for (var member in crew.crewMembers) {
      if (!usedCrewMembers.contains(member)) {
        // only consider members not in usedCrewMembers
        bool isPartOfSelectedSawTeam = false;

        // Check if the member is part of a fully selected Saw Team
        for (int i = 1; i <= 6; i++) {
          List<CrewMember> sawTeam = crew.getSawTeam(i);
          if (sawTeam.contains(member) &&
              selectedCrewMembers.any(
                  (item) => item is Map && item['name'] == 'Saw Team $i')) {
            isPartOfSelectedSawTeam = true;
            break;
          }
        }

        // Add the crew member to individual options if they're not part of a fully selected Saw Team
        if (!isPartOfSelectedSawTeam) {
          individualOptions.add({
            'name': member.name,
            'members': [member],
            'isSelected': selectedCrewMembers.contains(member)
            // Check if the member is already selected
          });
        }
      }
    }

    if (sawTeamOptions.isEmpty && individualOptions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No crew members available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show the selection dialog
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateSelection() {
              // clear and repopulate options based on the current selection
              sawTeamOptions.clear();
              individualOptions.clear();

              // Collect all used crew members again
              final usedCrewMembers = widget
                  .tripPreference.positionalPreferences
                  .expand((posPref) => posPref.crewMembersDynamic)
                  .expand((member) =>
                      member is List<CrewMember> ? member : [member])
                  .toSet();

              // Repopulate Saw Team options
              for (int i = 1; i <= 6; i++) {
                List<CrewMember> sawTeam = crew.getSawTeam(i);
                if (sawTeam.isNotEmpty &&
                    !sawTeam.every(usedCrewMembers.contains) &&
                    !sawTeam.every(
                        (member) => selectedCrewMembers.contains(member))) {
                  sawTeamOptions
                      .add({'name': 'Saw Team $i', 'members': sawTeam});
                }
              }

              // Repopulate individual crew member options
              for (var member in crew.crewMembers) {
                if (!usedCrewMembers.contains(member)) {
                  bool isPartOfSelectedSawTeam = false;

                  // Check if the member is part of a fully selected Saw Team
                  for (int i = 1; i <= 6; i++) {
                    List<CrewMember> sawTeam = crew.getSawTeam(i);
                    if (sawTeam.contains(member) &&
                        selectedCrewMembers.any((item) =>
                            item is Map && item['name'] == 'Saw Team $i')) {
                      isPartOfSelectedSawTeam = true;
                      break;
                    }
                  }

                  if (!isPartOfSelectedSawTeam) {
                    individualOptions.add({
                      'name': member.name,
                      'members': [member],
                      'isSelected': selectedCrewMembers.contains(member)
                    });
                  }
                }
              }
            }

            return AlertDialog(
              title: const Text(
                'Select Crew Members',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    ...sawTeamOptions.map((option) {
                      bool isSelected = selectedCrewMembers.any((item) =>
                          item is Map && item['name'] == option['name']);
                      return CheckboxListTile(
                        title: Text(option['name']),
                        value: isSelected,
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              selectedCrewMembers.add(option);
                              for (var member in option['members']) {
                                selectedCrewMembers.remove(member);
                              }
                            } else {
                              selectedCrewMembers.removeWhere((item) =>
                                  item is Map &&
                                  item['name'] == option['name']);
                            }
                            updateSelection();
                          });
                        },
                      );
                    }).toList(),
                    if (sawTeamOptions.isNotEmpty &&
                        individualOptions.isNotEmpty)
                      const Divider(color: Colors.black, thickness: 1),
                    ...individualOptions.map((option) {
                      bool isSelected = option['isSelected'] ?? false;
                      CrewMember member = option['members'].first;

                      return CheckboxListTile(
                        title: Text(
                          member.name,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          member.getPositionTitle(member.position),
                          style: TextStyle(
                            color: Colors.black,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        value: isSelected,
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              selectedCrewMembers.add(member);
                            } else {
                              selectedCrewMembers.remove(member);
                            }
                            updateSelection();
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    setState(() {
      _checkPositionalInput();
    });
  }

  // Functions to open the multi-select dialog for gear
  void _showGearSelectionDialog() async {
    // Map to track the total used quantities for each gear item
    Map<String, int> totalQuantities = {
      for (var gear in crew.gear) gear.name: 0,
      // Use gear.name. Coudl make a unique key
    };

    // Calculate total used quantities from all existing gear preferences
    for (var gearPref in widget.tripPreference.gearPreferences) {
      for (var gear in gearPref.gear) {
        totalQuantities[gear.name] =
            (totalQuantities[gear.name] ?? 0) + gear.quantity;
      }
    }

    // List of gear items with updated available quantities
    final availableGear = crew.gear.where((gear) {
      int remainingQuantity = gear.quantity - (totalQuantities[gear.name] ?? 0);
      return remainingQuantity > 0;
    }).toList();

    // Initialize selected gear quantities if not already set
    if (selectedGearQuantities.isEmpty) {
      selectedGearQuantities = {
        for (var gear in selectedGear) gear: gear.quantity
      };
    }
    if (availableGear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No gear available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final List<Gear>? result = await showDialog(
      context: context,
      builder: (context) {
        List<Gear> tempSelectedGear = List.from(selectedGear);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Select Gear',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  children: availableGear.map((gear) {
                    // Calculate the correct remaining quantity for this gear item
                    int remainingQuantity =
                        gear.quantity - (totalQuantities[gear.name] ?? 0);

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  gear.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  overflow: TextOverflow
                                      .ellipsis, // Use ellipsis if text is too long
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
                        if (tempSelectedGear.contains(gear))
                          if (remainingQuantity > 1)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(
                                          'Select Quantity for ${gear.name}'),
                                      content: Container(
                                        height: 150,
                                        child: CupertinoPicker(
                                          scrollController:
                                              FixedExtentScrollController(
                                                  initialItem:
                                                      (selectedGearQuantities[
                                                                  gear] ??
                                                              1) -
                                                          1),
                                          itemExtent: 32.0,
                                          // Height of each item
                                          onSelectedItemChanged: (int value) {
                                            setState(() {
                                              selectedGearQuantities[gear] =
                                                  value + 1;
                                            });
                                          },
                                          children: List<Widget>.generate(
                                              remainingQuantity, (int index) {
                                            return Center(
                                              child: Text(
                                                '${index + 1}',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                            );
                                          }),
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Close'),
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                            ),
                        Checkbox(
                          value: tempSelectedGear.contains(gear),
                          onChanged: (bool? isChecked) {
                            setState(() {
                              if (isChecked == true) {
                                tempSelectedGear.add(gear);
                                selectedGearQuantities[gear] = 1;
                              } else {
                                tempSelectedGear.remove(gear);
                                selectedGearQuantities.remove(gear);
                              }
                            });
                          },
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    tempSelectedGear.forEach((gear) {
                      selectedGearQuantities[gear] =
                          selectedGearQuantities[gear] ?? 1;
                    });
                    Navigator.of(context).pop(tempSelectedGear);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedGear = result;
        _checkGearInput();
      });
    }
  }

  void _checkPositionalInput() {
    setState(() {
      isPositionalSaveButtonEnabled = selectedCrewMembers.isNotEmpty &&
          selectedPositionalLoadPreference != null;
    });
  }

  void _checkGearInput() {
    setState(() {
      isGearSaveButtonEnabled =
          selectedGear.isNotEmpty && selectedGearLoadPreference != null;
    });
  }

  void savePositionalLoadPreference(TripPreference newTripPreference) {
    // Create a new list to store crew members dynamically
    List<dynamic> crewMembersToSave = [];

    // Loop through selectedCrewMembers and add either individual members or entire Saw Teams
    for (var member in selectedCrewMembers) {
      if (member is Map && member.containsKey('members')) {
        // Add the Saw Team as a List<CrewMember>
        crewMembersToSave.add(member['members']);
      } else if (member is CrewMember) {
        // Add the individual Crew Member directly
        crewMembersToSave.add(member);
      }
    }

    // Create a new PositionalPreference with the updated crew members list
    final newPositionalPreference = PositionalPreference(
      priority: 1, // Adjusted later through UI
      loadPreference: selectedPositionalLoadPreference!,
      crewMembersDynamic: crewMembersToSave,
    );

    // Add the new preference to the TripPreference object
    newTripPreference.positionalPreferences.add(newPositionalPreference);

    // Debugging `crewMembersDynamic`
    // widget.tripPreference.positionalPreferences.forEach((posPref) {
    //   posPref.crewMembersDynamic.forEach((item) {
    //     if (item is CrewMember) {
    //       print('Individual: ${item.name}');
    //     } else if (item is List<CrewMember>) {
    //       print('Saw Team: ${item.map((member) => member.name).join(', ')}');
    //     }
    //   });
    // });

    // Trigger the update callback
    widget.onUpdate();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preference saved!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(); // Return to the previous screen
  }

  void saveGearLoadPreference(TripPreference newTripPreference) {
    // New list of Gear objects with updated quantities
    List<Gear> copiedSelectedGear = selectedGear.map((gear) {
      return gear.copyWith(quantity: selectedGearQuantities[gear] ?? 1);
    }).toList();

    // New GearPreference object with copied Gear objects
    final newGearPreference = GearPreference(
      priority: 1, // To be updated through UI
      loadPreference: selectedGearLoadPreference!,
      gear: copiedSelectedGear, // Use copied list with updated quantities
    );

    // Print statement to display the gear items and their selected quantities
    // print("Saving...");
    // for (var gear in newGearPreference.gear) {
    //   print("Gear: ${gear.name}, Quantity: ${gear.quantity}");
    // }

    // Add to TripPreference object
    newTripPreference.gearPreferences.add(newGearPreference);

    // Trigger the update callback
    widget.onUpdate();

    // Show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Preference saved!',
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop(); // Return to previous screen
  }

  @override
  Widget build(BuildContext context) {
    // Main theme button style
    final ButtonStyle style = ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        backgroundColor: Colors.deepOrangeAccent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        //surfaceTintColor: Colors.grey,
        elevation: 15,
        shadowColor: Colors.black,
        side: const BorderSide(color: Colors.black, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery.of(context).size.width / 2,
            MediaQuery.of(context).size.height / 10));

    return Scaffold(
      resizeToAvoidBottomInset: false,
      // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: const Text(
          'Add Load Preference',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          labelColor: Colors.black,
          dividerColor: Colors.black,
          indicatorColor: Colors.black,
          controller: _tabController,
          tabs: const <Widget>[
            Tab(
              icon: Icon(Icons.person),
              text: 'Positional',
            ),
            Tab(icon: Icon(Icons.work_outline_outlined), text: 'Gear'),
          ],
        ),
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
          TabBarView(
            controller: _tabController,
            children: <Widget>[
              // Positional Preference
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),

                      // Choose Crew Member(s)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: _showCrewMemberSelectionDialog,
                          // Trigger dialog on tap
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: Text(
                              selectedCrewMembers.isEmpty
                                  ? 'Choose crew member(s)'
                                  : selectedCrewMembers.map((e) {
                                      if (e is Map &&
                                          e.containsKey('name') &&
                                          e['name'].startsWith('Saw Team')) {
                                        return e[
                                            'name']; // Display "Saw Team i"
                                      } else if (e is CrewMember) {
                                        return e
                                            .name; // Display individual crew member name
                                      }
                                      return '';
                                    }).join(', '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Choose Load Preference
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedPositionalLoadPreference,
                              hint: const Text(
                                'Choose load preference',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              dropdownColor: Colors.black,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                              iconEnabledColor: Colors.white,
                              items: loadPreferenceMap.entries.map((entry) {
                                return DropdownMenuItem<int>(
                                  value: entry.key,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.value),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          // Info dialog with loadpref explanation
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                    '${entry.value} Load Preference',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    )),
                                                content: Text(
                                                  getPreferenceInfo(entry
                                                      .key), //Load Preference explanation
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedPositionalLoadPreference = newValue;
                                    _checkPositionalInput();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 6),

                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: isPositionalSaveButtonEnabled
                              ? () => savePositionalLoadPreference(
                                  widget.tripPreference)
                              : null,
                          style: style, // Main button theme
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Gear Preference
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white.withOpacity(0.1),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Spacer(flex: 1),

                      // Choose Gear
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: GestureDetector(
                          onTap: _showGearSelectionDialog,
                          // Trigger dialog on tap
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12.0),
                              border:
                                  Border.all(color: Colors.white, width: 2.0),
                            ),
                            child: Text(
                              selectedGear.isEmpty
                                  ? 'Choose gear'
                                  : selectedGear.map((e) {
                                      final quantity =
                                          selectedGearQuantities[e] ??
                                              1; // Use selected quantity
                                      return '${e.name} (x$quantity)';
                                    }).join(', '),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Enter Load Preference
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedGearLoadPreference,
                              hint: const Text(
                                'Choose load preference',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              dropdownColor: Colors.black,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                              iconEnabledColor: Colors.white,
                              items: loadPreferenceMap.entries.map((entry) {
                                return DropdownMenuItem<int>(
                                  value: entry.key,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.value),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.info_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          // Info dialog with loadpref explanation
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text(
                                                    '${entry.value} Load Preference',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    )),
                                                content: Text(
                                                  getPreferenceInfo(entry
                                                      .key), //Load Preference explanation
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedGearLoadPreference = newValue;
                                    _checkGearInput();
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      const Spacer(flex: 6),

                      // Save Button
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: ElevatedButton(
                          onPressed: isGearSaveButtonEnabled
                              ? () =>
                                  saveGearLoadPreference(widget.tripPreference)
                              : null,
                          style: style, // Main button theme
                          child: const Text('Save'),
                        ),
                      ),
                    ],
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

String getPreferenceInfo(int? preference) {
  switch (preference) {
    case 0:
      return "Places crew members/gear into the first load based on the order selected. If a crew member's or gear's weight exceeds the allowable load weight, they will be placed into the next available load.";
    case 1:
      return "Places crew members/gear into the last load based on the order selected. If a crew member's or gear's weight exceeds the allowable load weight, they will be placed in the next available load, working backward from the last load to the first.";
    case 2:
      return 'Distributes selected crew members/gear evenly across loads, working from the first load to the last.';
    default:
      return 'Select a preference to see more information.';
  }
}
