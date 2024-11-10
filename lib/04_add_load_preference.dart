import 'dart:ui';
import 'package:flutter/services.dart';

import 'Data/crew.dart';
import 'Data/gear.dart';
import 'Data/saved_preferences.dart';
import 'Data/crewmember.dart';
import 'package:flutter/material.dart';

class AddLoadPreference extends StatefulWidget {
  // This page requires a Trip Preference object to be passed to it - to edit it
  final TripPreference tripPreference;
  final VoidCallback onUpdate;  // Callback for deletion to update previous page

  const AddLoadPreference({
    super.key,
    required this.tripPreference,
    required this.onUpdate});

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

  bool isPositionalSaveButtonEnabled = false; // Controls whether saving button is showing
  bool isGearSaveButtonEnabled = false; // Controls whether saving button is showing


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

    // Populate Saw Team options
    for (int i = 1; i <= 6; i++) {
      List<CrewMember> sawTeam = crew.getSawTeam(i);
      if (sawTeam.isNotEmpty &&
          !sawTeam.every(usedCrewMembers.contains) &&
          !sawTeam.every((member) => selectedCrewMembers.contains(member))) {
        sawTeamOptions.add({'name': 'Saw Team $i', 'members': sawTeam});
      }
    }

    // Populate individual crew member options
    final availableCrewMembers = crew.crewMembers
        .where((crewMember) => !usedCrewMembers.contains(crewMember))
        .toList();

    for (var member in availableCrewMembers) {
      bool isPartOfSelectedSawTeam = false;

      for (int i = 1; i <= 6; i++) {
        List<CrewMember> sawTeam = crew.getSawTeam(i);
        if (sawTeam.contains(member) &&
            selectedCrewMembers.any((item) => item is Map && item['name'] == 'Saw Team $i')) {
          isPartOfSelectedSawTeam = true;
          break;
        }
      }

      if (!isPartOfSelectedSawTeam) {
        individualOptions.add({'name': member.name, 'members': [member]});
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
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateSelection() {
              // Clear all options and re-populate based on the current selection
              sawTeamOptions.clear();
              individualOptions.clear();

              // Collect all used crew members (both individuals and members of saw teams)
              final usedCrewMembers = widget.tripPreference.positionalPreferences
                  .expand((posPref) => posPref.crewMembersDynamic)
                  .expand((member) => member is List<CrewMember> ? member : [member])
                  .toSet();

              // Populate saw team options only if they are not entirely selected or previously added
              for (int i = 1; i <= 6; i++) {
                List<CrewMember> sawTeam = crew.getSawTeam(i);

                // Add Saw Team only if at least one member is not in usedCrewMembers and the whole team isn't selected
                if (sawTeam.isNotEmpty &&
                    !sawTeam.every(usedCrewMembers.contains) && // Ensure the team isn't entirely used
                    !sawTeam.every((member) => selectedCrewMembers.contains(member))) { // Ensure the team isn't entirely selected
                  sawTeamOptions.add({'name': 'Saw Team $i', 'members': sawTeam});
                }
              }

              // Populate individual crew member options, so they remain visible and checked if selected
              for (var member in crew.crewMembers) {
                if (!usedCrewMembers.contains(member)) { // Only consider members not in usedCrewMembers
                  bool isPartOfSelectedSawTeam = false;

                  for (int i = 1; i <= 6; i++) {
                    List<CrewMember> sawTeam = crew.getSawTeam(i);
                    if (sawTeam.contains(member) &&
                        selectedCrewMembers.any((item) => item is Map && item['name'] == 'Saw Team $i')) {
                      isPartOfSelectedSawTeam = true;
                      break;
                    }
                  }

                  // Add crew member to individual options if they're not part of a fully selected saw teams
                  if (!isPartOfSelectedSawTeam) {
                    individualOptions.add({
                      'name': member.name,
                      'members': [member],
                      'isSelected': selectedCrewMembers.contains(member) // Track if crew member is selected
                    });
                  }
                }
              }
            }

            return AlertDialog(
              title: const Text('Select Crew Members'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Saw Team options
                    ...sawTeamOptions.map((option) {
                      bool isSelected = selectedCrewMembers
                          .any((item) => item is Map && item['name'] == option['name']);
                      return CheckboxListTile(
                        title: Text(option['name']),
                        value: isSelected,
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              // Add Saw Team and remove individual members
                              selectedCrewMembers.add(option);
                              for (var member in option['members']) {
                                selectedCrewMembers.remove(member);
                              }
                            } else {
                              // Remove Saw Team
                              selectedCrewMembers.removeWhere(
                                      (item) => item is Map && item['name'] == option['name']);
                            }
                            updateSelection(); // Update individual options
                          });
                        },
                      );
                    }).toList(),

                    // Divider between saw teams and individuals
                    if (sawTeamOptions.isNotEmpty && individualOptions.isNotEmpty)
                      const Divider(color: Colors.black, thickness: 1),

                    // Individual crew member options
                    ...individualOptions.map((option) {
                      bool isSelected = option['isSelected'] ?? false; // Use the 'isSelected' flag
                      return CheckboxListTile(
                        title: Text(option['name']),
                        value: isSelected,
                        onChanged: (bool? isChecked) {
                          setState(() {
                            if (isChecked == true) {
                              selectedCrewMembers.add(option['members'].first);
                            } else {
                              selectedCrewMembers.remove(option['members'].first);
                            }
                            updateSelection(); // Check if all members of saw teeam are selected
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

    // Gets gear already used in existing GearPreferences
    final usedGear = widget.tripPreference.gearPreferences
        .expand((posPref) => posPref.gear)
        .toSet();  // Convert to Set to avoid duplicates

    // Filters out used gear for selection list
    final availableGear = crew.gear
        .where((gear) => !usedGear.contains(gear))
        .toList();

    // If no gear available, show a message
    if (availableGear.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No gear available',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          duration: Duration(seconds: 2),
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
              title: const Text('Select Gears'),
              content: SingleChildScrollView(
                child: Column(
                  children: availableGear.map((gear) {
                    return CheckboxListTile(
                      title: Text(gear.name),
                      value: tempSelectedGear.contains(gear),
                      onChanged: (bool? isChecked) {
                        setState(() {
                          if (isChecked == true) {
                            tempSelectedGear.add(gear);
                          } else {
                            tempSelectedGear.remove(gear);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
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
        _checkGearInput(); // Update button state
      });
    }
  }

  void _checkPositionalInput() {
    setState(() {
      isPositionalSaveButtonEnabled = selectedCrewMembers.isNotEmpty && selectedPositionalLoadPreference != null;
    });
  }

  void _checkGearInput() {
    setState(() {
      isGearSaveButtonEnabled = selectedGear.isNotEmpty && selectedGearLoadPreference != null;
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
      priority: 1,  // Adjusted later through UI
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
        duration: Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.of(context).pop();  // Return to the previous screen
  }


  void saveGearLoadPreference(TripPreference newTripPreference) {

    final newGearPreference = GearPreference(
        priority: 1,  // To be changed and updated via UI drag n drop
        loadPreference: selectedGearLoadPreference!,
        gear: selectedGear,
    );

    // Add this new preference to the TripPreference object
    newTripPreference.gearPreferences.add(newGearPreference);

    // Callback function, Update previous page UI with setState()
    widget.onUpdate();

    // Show successful save popup
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Preference saved!',
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
    Navigator.of(context).pop();  // Return to previous screen
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        // Maybe change? Dynamic button size based on screen size
        fixedSize: Size(MediaQuery
            .of(context)
            .size
            .width / 2, MediaQuery
            .of(context)
            .size
            .height / 10)
    );

    return Scaffold(
      resizeToAvoidBottomInset: false, // Ensures the layout doesn't adjust for  keyboard - which causes pixel overflow
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
            Tab(
              icon: Icon(Icons.work_outline_outlined),
              text: 'Gear'
            ),
          ],
        ),
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
                        onTap: _showCrewMemberSelectionDialog, // Trigger dialog on tap
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: Text(
                            selectedCrewMembers.isEmpty
                                ? 'Choose crew member(s)'
                                : selectedCrewMembers.map((e) {
                              if (e is Map && e.containsKey('name') && e['name'].startsWith('Saw Team')) {
                                return e['name']; // Display "Saw Team i"
                              } else if (e is CrewMember) {
                                return e.name;  // Display individual crew member name
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
                                child: Text(entry.value), // Add info icon that tells what the load preference option does, e.g., 'Balanced distributes evenly from first to last load
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
                        onPressed: isPositionalSaveButtonEnabled ? () => savePositionalLoadPreference(widget.tripPreference) : null,
                        style: style,  // Main button theme
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
                        onTap: _showGearSelectionDialog,  // Trigger dialog on tap
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(color: Colors.white, width: 2.0),
                          ),
                          child: Text(
                            selectedGear.isEmpty
                                ? 'Choose gear'
                                : selectedGear.map((e) => e.name).join(', '),
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
                                child: Text(entry.value),
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
                        onPressed: isGearSaveButtonEnabled ? () => saveGearLoadPreference(widget.tripPreference) : null,
                        style: style,  // Main button theme
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
